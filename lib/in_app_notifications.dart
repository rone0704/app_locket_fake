import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_payload.dart';

// ==========================================
// PUSH NOTIFICATIONS SYSTEM
// ==========================================

class NotificationsSystem {
  final String userId;

  NotificationsSystem({required this.userId});

  // Gửi notification đên bạn bè
  Future<void> sendNotification({
    required String recipientId,
    required String
    type, // 'like', 'comment', 'friendRequest', 'message', 'newPost'
    required String title,
    required String body,
    String? relatedPostId,
    String? relatedUserId,
  }) async {
    final pushData = relatedPostId != null && relatedUserId != null
        ? NotificationPayload.forNewPost(
            postId: relatedPostId,
            senderUid: relatedUserId,
          )
        : <String, dynamic>{};

    await FirebaseFirestore.instance
        .collection('users')
        .doc(recipientId)
        .collection('notifications')
        .add({
          'type': type,
          'title': title,
          'body': body,
          'fromUserId': userId,
          'relatedPostId': relatedPostId,
          'relatedUserId': relatedUserId,
          'deepLink': relatedPostId != null
              ? NotificationPayload.deepLinkForPost(relatedPostId)
              : null,
          'pushData': pushData,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
  }

  // Lấy notifications
  static Stream<QuerySnapshot> getUserNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  // Đánh dấu notification là đã đọc
  Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Xóa notification
  Future<void> deleteNotification(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // Đánh dấu tất cả là đã đọc
  Future<void> markAllAsRead() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // Lấy số notification chưa đọc
  static Future<int> getUnreadCount(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}

// ==========================================
// NOTIFICATION BADGE (CHỈ BÁO SỐ LƯỢNG)
// ==========================================

class NotificationBadge extends StatelessWidget {
  final String userId;

  const NotificationBadge({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: NotificationsSystem.getUnreadCount(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            snapshot.data!.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// NOTIFICATION ITEM
// ==========================================

class NotificationItem extends StatelessWidget {
  final DocumentSnapshot notification;
  final String userId;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.userId,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = notification.data() as Map<String, dynamic>;
    final isRead = data['isRead'] ?? false;
    final timestamp = data['timestamp'] as Timestamp?;
    final type = data['type'] ?? 'notification';

    String timeString = '';
    if (timestamp != null) {
      final dateTime = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        timeString = 'Vừa xong';
      } else if (difference.inHours < 1) {
        timeString = '${difference.inMinutes}m trước';
      } else if (difference.inDays < 1) {
        timeString = '${difference.inHours}h trước';
      } else {
        timeString = '${difference.inDays}d trước';
      }
    }

    IconData notifIcon;
    Color notifColor;

    switch (type) {
      case 'like':
        notifIcon = Icons.favorite;
        notifColor = Colors.red;
        break;
      case 'comment':
        notifIcon = Icons.message;
        notifColor = Colors.blue;
        break;
      case 'friendRequest':
        notifIcon = Icons.person_add;
        notifColor = Colors.green;
        break;
      case 'message':
        notifIcon = Icons.chat;
        notifColor = Colors.amber;
        break;
      case 'newPost':
        notifIcon = Icons.photo_camera;
        notifColor = Colors.purpleAccent;
        break;
      default:
        notifIcon = Icons.notifications;
        notifColor = Colors.white54;
    }

    return GestureDetector(
      onTap: () async {
        if (!isRead) {
          await NotificationsSystem(userId: userId).markAsRead(notification.id);
        }
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead ? Colors.grey[900] : Colors.grey[850],
          border: isRead
              ? null
              : Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: notifColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(notifIcon, color: notifColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['body'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeString,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, color: Colors.white54, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// IN-APP NOTIFICATION TOASTER
// ==========================================

void showInAppNotification(
  BuildContext context, {
  required String title,
  required String body,
  required IconData icon,
  Color iconColor = Colors.white,
}) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  overlay.insert(entry);

  Future.delayed(const Duration(seconds: 4), () {
    entry.remove();
  });
}
