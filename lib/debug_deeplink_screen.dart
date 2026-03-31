import 'package:flutter/material.dart';

import 'push_notification_service.dart';

class DebugDeepLinkScreen extends StatefulWidget {
  const DebugDeepLinkScreen({super.key});

  @override
  State<DebugDeepLinkScreen> createState() => _DebugDeepLinkScreenState();
}

class _DebugDeepLinkScreenState extends State<DebugDeepLinkScreen> {
  final TextEditingController _postIdController = TextEditingController();
  final TextEditingController _deepLinkController = TextEditingController(
    text: 'locketfake://post/',
  );

  void _openByPostId() {
    final postId = _postIdController.text.trim();
    final ok = PushNotificationService.openFromPayload(<String, dynamic>{
      'postId': postId,
    });
    _showResult(ok, ok ? 'Đã mở Feed với postId' : 'PostId không hợp lệ');
  }

  void _openByDeepLink() {
    final deepLink = _deepLinkController.text.trim();
    final ok = PushNotificationService.openFromDeepLink(deepLink);
    _showResult(ok, ok ? 'Đã mở Feed từ deeplink' : 'Deep link không hợp lệ');
  }

  void _showResult(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    _postIdController.dispose();
    _deepLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Debug Deeplink'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Mở bài viết bằng postId',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _postIdController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nhập postId',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _openByPostId,
            child: const Text('Open by postId'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Mở bằng deeplink',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _deepLinkController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'locketfake://post/{postId}',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _openByDeepLink,
            child: const Text('Open by deeplink'),
          ),
        ],
      ),
    );
  }
}
