import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'neu_box.dart'; // 导入你的 NeuBox 组件

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // 设置背景颜色
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 32), // 返回按钮图标
          onPressed: () {
            Navigator.pop(context); // 点击返回按钮时返回上一个页面
          },
        ),
        title: Text("关于作者"),
        centerTitle: true,
        backgroundColor: Colors.grey[300], // 使用拟态风格的背景颜色
        elevation: 0, // 去掉阴影
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // 作者头像部分
            const NeuBox(
              height: 150,
              width: 150,
              bottomPadding: 20,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('lib/images/zzuo.jpg'), // 替换为你的作者头像
              ),
            ),
            SizedBox(height: 20),

            // 作者名字
            NeuBox(
              child: Text(
                "小司",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),

            // 作者简介
            NeuBox(
              bottomPadding: 20,
              child: Text(
                "  xiaosi music是一款由Flutter框架开发的\n本地播放器，由小司历时四天时间开发制作，"
                    "\nUI设计灵感源自博主视频。目前实现了：\n"
                    "  添加歌曲、收藏功能、滑动删除功能、\n单曲循环功能、随机播放功能、顺序播放功能、"
                    "专辑图片获取、歌词同步功能、进度条拖动功能、通知栏显示功能。\n"
                    "该版本为1.0.0开发版，本版本不代表最终版本，敬请期待。",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ),
            SizedBox(height: 20),

            // 联系方式
            NeuBox(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.link),
                    title: Text("GitHub开源地址"),
                    subtitle: Text("https://github.com/yourusername"), // 替换为实际链接
                    onTap: () {
                      // 打开链接
                      _launchURL("https://github.com/yourusername");
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.video_library),
                    title: Text("B站主页"),
                    subtitle: Text("https://space.bilibili.com/296054535"), // 替换为实际链接
                    onTap: () {
                      // 打开链接
                      _launchURL("https://space.bilibili.com/296054535");
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.email),
                    title: Text("联系邮箱"),
                    subtitle: Text("1427067534@qq.com"),
                    onTap: () {
                      // 发送邮件
                      _launchEmail("1427067534@qq.com");
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // 打赏和捐赠功能
            NeuBox(
              child: Column(
                children: [
                  //Divider(),
                  ListTile(
                    leading: Icon(Icons.monetization_on, color: Colors.green),
                    title: Text("捐赠支持"),
                    subtitle: Text("请作者喝杯阔乐吧~"),
                    onTap: () {
                      // 打开捐赠链接（例如支付宝或微信支付链接）
                      _showWeChatQRCode(context);
                      _showToast("感谢投喂喵，爱你喵");
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 弹出微信二维码的对话框
  void _showWeChatQRCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("捐赠支持"),
          content: Image.asset(
            'lib/images/xiaosi.png', // 替换为你的微信二维码图片路径
            width: 200,
            height: 200,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭对话框
              },
              child: Text("关闭"),
            ),
          ],
        );
      },
    );
  }

  // 打开链接的辅助方法
  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw '无法打开链接: $url';
    }
  }
  static void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // 发送邮件的辅助方法
  void _launchEmail(String email) async {
    final emailUrl = "mailto:$email";
    if (await canLaunchUrl(Uri.parse(emailUrl))) {
      await launchUrl(Uri.parse(emailUrl));
    } else {
      throw '无法发送邮件: $email';
    }
  }
}