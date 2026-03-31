import 'package:flutter/material.dart';
import 'main_layout.dart'; // Đổi import sang MainLayout

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppNavigator {
  static void openPostById(String postId) {
    final navigator = appNavigatorKey.currentState;
    final context = appNavigatorKey.currentContext;
    if (navigator == null || context == null || postId.isEmpty) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => MainLayout(
          initialTab: 1, // Tab Home
          initialHomeVerticalPage: 1, // Cuộn xuống Feed
          initialPostId: postId, // Truyền ID ảnh
        ),
      ),
    );
  }
}