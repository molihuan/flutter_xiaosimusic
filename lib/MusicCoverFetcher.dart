import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class MusicCoverFetcher {
  static Future<String?> fetchCoverImageUrl(String songTitle) async {
    String apiUrl = 'https://api.52vmy.cn/api/music/qq?msg=$songTitle&n=1';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        String responseBody = response.body;
        // 使用正则表达式提取 picture 关键词的图片 URL
        RegExp regex = RegExp(r'"picture":"([^"]+)"');
        Match? match = regex.firstMatch(responseBody);
        if (match != null) {
          return match.group(1)!;
        }
      } else {
        print('Failed to fetch cover image URL: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to fetch cover image URL: $e');
    }
    return null;
  }

  static Widget buildCoverImageWidget(String? coverImageUrl) {
    return coverImageUrl != null
        ? Image.network(
      coverImageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.error);
      },
    )
        : const Icon(Icons.music_note);
  }
}