import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_navigator.dart';
import 'in_app_notifications.dart';
import 'ui_widgets.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Vui lòng đăng nhập để xem thông báo',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final notifications = NotificationsSystem(userId: user.uid);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          "Thông báo",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => notifications.markAllAsRead(),
            child: const Text('Đọc hết', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: NotificationsSystem.getUserNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Chưa có thông báo',
                subtitle: 'Khi bạn bè tương tác, thông báo sẽ hiện ở đây.',
                actionLabel: 'Lam moi',
                onAction: () {},
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final notification = docs[index];
              final data = notification.data() as Map<String, dynamic>?;
              final postId = data?['relatedPostId']?.toString();

              return NotificationItem(
                notification: notification,
                userId: user.uid,
                onDelete: () =>
                    notifications.deleteNotification(notification.id),
                onTap: () {
                  if (postId == null || postId.isEmpty) return;
                  Navigator.pop(context);
                  AppNavigator.openPostById(postId);
                },
              );
            },
          );
        },
      ),
    );
  }
}
