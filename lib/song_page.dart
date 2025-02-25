import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'LyricParser.dart';
import 'menu/FavoriteButton.dart';
import 'menu/menu.dart';
import 'menu/menu_vm.dart';
import 'neu_box.dart';
import 'menu/NotificationHelper.dart';
import 'menu/audio_provider.dart';
import 'AboutPage.dart';
import 'package:http/http.dart' as http;

class SongPage extends StatefulWidget {
  const SongPage({super.key});

  @override
  State<SongPage> createState() => _SongPageState();
}

class _SongPageState extends State<SongPage> with TickerProviderStateMixin {
  int currentSongIndex = 0; // 当前播放歌曲的索引
  bool isSingleLoop = false; // 单曲循环状态
  bool isPlayEnd = false;
  bool isShuffle = false;
  final PageController _pageController = PageController(); // 用于控制 PageView 的页面切换
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  List<Map<String, dynamic>> lyrics = [];
  int currentLyricIndex = 0;
  String singerName = "Luo Tian Yi"; // 初始化歌手名字
  String coverImageUrl = 'lib/images/cover_art.jpg'; // 默认封面图片

  @override
  void initState() {
    super.initState();
    // 设置 NotificationHelper 的 BuildContext
    NotificationHelper.setContext(context);
    // 初始化通知
    NotificationHelper.initialize();

    // 初始化旋转动画控制器
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.1415926).animate(_rotationController);

    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    // 监听播放进度
    audioProvider.audioPlayer.positionStream.listen((position) {
      if (position >= (audioProvider.audioPlayer.duration ?? Duration.zero) && isPlayEnd) {
        if (isSingleLoop) {
          playCurrentSong();
        } else {
          nextSong();
        }
        isPlayEnd = false;
      }
      if (position == Duration.zero) {
        isPlayEnd = true;
      }
      updateCurrentLyricIndex(position.inMilliseconds);
    });

    // 监听播放状态变化
    audioProvider.addListener(() {
      if (audioProvider.isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });

    // 初始化时获取歌手名字和封面图片
    _fetchSingerName();
    _fetchSongCoverImage();
  }

  @override
  void dispose() {
    _pageController.dispose(); // 释放 PageController 资源
    _rotationController.dispose(); // 释放动画控制器资源
    super.dispose();
  }

  // 切换到上一首歌
  void previousSong() {
    final menuViewModel = Provider.of<MenuViewModel>(context, listen: false);
    final audioFiles = menuViewModel.getAudioFiles();
    if (audioFiles.isNotEmpty) {
      setState(() {
        currentSongIndex = (currentSongIndex - 1) % audioFiles.length;
        if (currentSongIndex < 0) {
          currentSongIndex = audioFiles.length - 1;
        }
      });
      playCurrentSong();
    }
  }

  // 切换到下一首歌
  void nextSong() {
    final menuViewModel = Provider.of<MenuViewModel>(context, listen: false);
    final audioFiles = menuViewModel.getAudioFiles();
    if (audioFiles.isNotEmpty) {
      setState(() {
        currentSongIndex = (currentSongIndex + 1) % audioFiles.length;
      });
      playCurrentSong();
    }
  }

  // 播放当前歌曲
  void playCurrentSong() async {
    final menuViewModel = Provider.of<MenuViewModel>(context, listen: false);
    final audioFiles = menuViewModel.getAudioFiles();
    if (audioFiles.isNotEmpty) {
      final currentSongPath = audioFiles[currentSongIndex];
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      audioProvider.togglePlay(currentSongPath);
      updateNotification(currentSongPath);

      String songTitle = currentSongPath.split('/').last.split('.').first;
      String lyricUrl = 'https://api.52vmy.cn/api/music/lrc?msg=$songTitle&n=1';
      final parsedLyrics = await LyricParser.parseLyricsFromUrl(lyricUrl);
      setState(() {
        lyrics = parsedLyrics;
        currentLyricIndex = 0;
      });

      // 更新歌手名字和封面图片
      await _fetchSingerName();
      await _fetchSongCoverImage();

    }
  }

  // 提取更新通知的方法
  void updateNotification(String songPath) {
    NotificationHelper.showNotification(
      id: 1,
      title: "Playing Song",
      body: songPath.split('/').last,
      payload: null,
    );
  }

  // 更新当前显示的歌词索引
  void updateCurrentLyricIndex(int currentTime) {
    for (int i = 0; i < lyrics.length; i++) {
      if (i == lyrics.length - 1 || (lyrics[i]['time'] <= currentTime && lyrics[i + 1]['time'] > currentTime)) {
        if (currentLyricIndex != i) {
          setState(() {
            currentLyricIndex = i;
          });
        }
        break;
      }
    }
  }

  // 格式化时长
  String formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  // 获取歌手名字
  Future<void> _fetchSingerName() async {
    final menuViewModel = Provider.of<MenuViewModel>(context, listen: false);
    final audioFiles = menuViewModel.getAudioFiles();
    if (audioFiles.isEmpty) return;
    String songTitle = audioFiles[currentSongIndex].split('/').last.split('.').first;
    String apiUrl = 'http://mobilecdn.kugou.com/api/v3/search/song?format=json&keyword=$songTitle&page=1';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        String responseBody = response.body;
        // 使用正则表达式提取第一个歌手名字
        RegExp regex = RegExp(r'"singername":"([^"]+)"');
        Match? match = regex.firstMatch(responseBody);
        if (match != null) {
          setState(() {
            singerName = match.group(1)!;
          });
        }
      } else {
        print('Failed to fetch singer name: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to fetch singer name: $e');
    }
  }

  // 获取歌曲封面图片
  // 获取歌曲封面图片
  Future<void> _fetchSongCoverImage() async {
    final menuViewModel = Provider.of<MenuViewModel>(context, listen: false);
    final audioFiles = menuViewModel.getAudioFiles();
    if (audioFiles.isEmpty) return;

    String songTitle = audioFiles[currentSongIndex].split('/').last.split('.').first;
    String apiUrl = 'https://mcapi.muwl.xyz/api/music_163.php?msg=$songTitle&n=1';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // 清理 Content-Type 字段
        if (response.headers['content-type'] != null) {
          response.headers['content-type'] = response.headers['content-type']!.split(';')[0];
        }

        final data = json.decode(response.body);
        if (data['status'] == 'success' && data.containsKey('img')) {
          String pictureUrl = data['img'].toString().trim();
          if (pictureUrl.isNotEmpty && pictureUrl.startsWith('http')) {
            setState(() {
              coverImageUrl = pictureUrl; // 更新封面图片 URL
            });
          } else {
            print('Invalid picture URL: $pictureUrl');
            setState(() {
              coverImageUrl = 'lib/images/cover_art.jpg'; // 使用默认图片
            });
          }
        } else {
          print('No cover image found for the song.');
          setState(() {
            coverImageUrl = 'lib/images/cover_art.jpg'; // 使用默认图片
          });
        }
      } else {
        print('Failed to fetch cover image: ${response.statusCode}');
        setState(() {
          coverImageUrl = 'lib/images/cover_art.jpg'; // 使用默认图片
        });
      }
    } catch (e) {
      print('Failed to fetch cover image: $e');
      setState(() {
        coverImageUrl = 'lib/images/cover_art.jpg'; // 使用默认图片
      });
    }
  }
  Future<void> _fetchLyrics([String? songTitle]) async {
    final menuViewModel = Provider.of<MenuViewModel>(context, listen: false);
    final audioFiles = menuViewModel.getAudioFiles();
    if (audioFiles.isEmpty) return;

    songTitle ??= audioFiles[currentSongIndex].split('/').last.split('.').first;
    String lyricUrl = 'https://api.52vmy.cn/api/music/lrc?msg=$songTitle&n=1';

    try {
      final response = await http.get(Uri.parse(lyricUrl));
      if (response.statusCode == 200) {
        final parsedLyrics = await LyricParser.parseLyricsFromUrl(lyricUrl);
        setState(() {
          lyrics = parsedLyrics;
          currentLyricIndex = 0;
        });
      } else {
        print('Failed to fetch lyrics: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to fetch lyrics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuViewModel = Provider.of<MenuViewModel>(context, listen: false);
    final audioFiles = menuViewModel.getAudioFiles();
    final currentSongPath = audioFiles.isNotEmpty ? audioFiles[currentSongIndex] : 'assets/music/光与影的对白.flac';
    // 监听 AudioProvider 的状态变化
    final audioProvider = Provider.of<AudioProvider>(context, listen: true);
    final duration = audioProvider.audioPlayer.duration;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      height: 65,
                      width: 65,
                      child: NeuBox(
                        child: Center(
                          child: IconButton(icon: const Icon(
                            Icons.arrow_back,
                            size: 32,
                          ),
                            onPressed: () {
                              // 点击返回按钮时跳转到 AboutPage
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AboutPage()),
                              );
                            },),
                        ),
                      ),
                    ),
                    const Text("P L A Y L I S T"),
                    SizedBox(
                      height: 65,
                      width: 65,
                      child: NeuBox(
                        child: IconButton(
                          icon: const Icon(
                            Icons.menu,
                            size: 32,
                          ),
                          onPressed: () {
                            showMusicListBottomSheet(
                              context,
                              onSongSelected: (selectedSongPath) {
                                setState(() {
                                  currentSongIndex = audioFiles.indexOf(selectedSongPath);
                                });
                                playCurrentSong();
                              },
                              viewModel: menuViewModel,
                            );
                          },
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                NeuBox(
                  child: SizedBox(
                    height: 300, // 根据实际情况调整高度
                    child: PageView(
                      controller: _pageController,
                      children: [
                        AnimatedBuilder(
                          animation: _rotationAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationAnimation.value,
                              child: Center(
                                child: ClipOval(
                                  child: SizedBox(
                                    width: 250, // 设置图片宽度
                                    height: 250, // 设置图片高度，与宽度相等以保证圆形
                                    child: Image.network(
                                      coverImageUrl, // 使用封面图片
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        // 如果图片加载失败，使用默认图片
                                        return Image.asset(
                                          'lib/images/cover_art.jpg',
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        ListView.builder(
                          itemCount: lyrics.length,
                          itemBuilder: (context, index) {
                            return Text(
                              lyrics[index]['lyric'],
                              style: TextStyle(
                                color: index == currentLyricIndex ? Colors.blue : Colors.black,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            singerName, // 显示歌手名字
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey.shade700),
                          ),
                          Text(
                            currentSongPath.split('/').last,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      FavoriteButton(
                        filePath: currentSongPath,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StreamBuilder<Duration>(
                      stream: audioProvider.audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        return Text(formatDuration(position));
                      },
                    ),
                    // 随机功能按钮
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: isShuffle ? Colors.blue : null,
                      ),
                      onPressed: () {
                        setState(() {
                          isShuffle = !isShuffle;
                          isSingleLoop = false;
                          if (isShuffle) {
                            audioProvider.playRandomSong();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('随机播放模式已开启')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('随机播放模式已关闭')),
                            );
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        isSingleLoop ? Icons.repeat_one : Icons.repeat,
                        color: isSingleLoop ? Colors.blue : null,
                      ),
                      onPressed: () {
                        setState(() {
                          isSingleLoop = !isSingleLoop;
                          isShuffle = false;
                          if (isSingleLoop) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('单曲循环模式已开启')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('单曲循环模式已关闭')),
                            );
                          }
                        });
                      },
                    ),
                    Text(formatDuration(duration)),
                  ],
                ),
                const SizedBox(height: 20),
                StreamBuilder<Duration>(
                  stream: audioProvider.audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final totalDuration = audioProvider.audioPlayer.duration ?? Duration.zero;
                    final percent = totalDuration.inMilliseconds > 0
                        ? position.inMilliseconds / totalDuration.inMilliseconds
                        : 0;

                    return NeuBox(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 10, // 设置进度条高度，使其更粗
                          activeTrackColor: Colors.blue.shade200, // 进度条已播放部分颜色
                          inactiveTrackColor: Colors.grey[300], // 进度条未播放部分颜色，浅灰色
                          thumbColor: Colors.blue.shade200, // 滑块颜色
                          overlayColor: Colors.blue.shade200.withOpacity(0.2), // 滑块点击时的覆盖颜色
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8), // 滑块形状和大小
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16), // 滑块点击时覆盖层的大小
                        ),
                        child: Slider(
                          value: percent.clamp(0.0, 1.0).toDouble(),
                          onChanged: (newValue) {
                            final newPosition = newValue * totalDuration.inMilliseconds;
                            audioProvider.audioPlayer.seek(Duration(milliseconds: newPosition.toInt()));
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40), // 增加进度条与按钮之间的间距
                SizedBox(
                  height: 60,
                  child: Row(
                    children: [
                      Expanded(
                        child: NeuBox(
                          child: IconButton(
                            icon: const Icon(Icons.skip_previous, size: 32),
                            onPressed: previousSong,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: NeuBox(
                            child: IconButton(
                              //播放按钮
                              icon: Icon(
                                audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 32,
                              ),
                              onPressed: () {
                                playCurrentSong();
                                _fetchSongCoverImage();
                              },
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: NeuBox(
                          child: IconButton(
                            icon: const Icon(Icons.skip_next, size: 32),
                            onPressed: nextSong,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
