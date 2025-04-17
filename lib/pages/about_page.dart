import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于 ReelNest')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'ReelNest',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '一个多源聚合影视播放器，支持多平台，开源免费。\n\n'
              '本项目仅用于学习与交流，所有视频内容均来自第三方公开接口。',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            Text(
              '作者：sonnyzhai\n'
              'GitHub: github.com/sonnyzhai/ReelNest',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
