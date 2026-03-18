import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ==========================================
// HỆ THỐNG CHẶN NGƯỜI DÙNG
// ==========================================

class BlockingSystem {
  final String userId;

  BlockingSystem({required this.userId});

  // Chặn người dùng
  Future<void> blockUser(String blockedUserId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('blockedUsers')
        .doc(blockedUserId)
        .set({
      'blockedUserId': blockedUserId,
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  // Bỏ chặn người dùng
  Future<void> unblockUser(String blockedUserId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('blockedUsers')
        .doc(blockedUserId)
        .delete();
  }

  // Kiểm tra đã chặn chưa
  Future<bool> isUserBlocked(String blockedUserId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('blockedUsers')
        .doc(blockedUserId)
        .get();
    return doc.exists;
  }

  // Lấy danh sách user bị chặn
  static Stream<QuerySnapshot> getBlockedUsers(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('blockedUsers')
        .snapshots();
  }

  // Kiểm tra có phải ai đó chặn mình không
  static Future<List<String>> getBlockersOfUser(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();

    List<String> blockers = [];

    for (var userDoc in snapshot.docs) {
      final blockedUsers = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('blockedUsers')
          .doc(userId)
          .get();

      if (blockedUsers.exists) {
        blockers.add(userDoc.id);
      }
    }

    return blockers;
  }
}

// ==========================================
// BLOCKED USERS SCREEN
// ==========================================

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Vui lòng đăng nhập",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.amber),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Người dùng bị chặn",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: BlockingSystem.getBlockedUsers(currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, color: Colors.white54, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    "Chưa chặn ai",
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final blockedUserId =
                  (snapshot.data!.docs[index].data() as Map)['blockedUserId'];
              return BlockedUserTile(
                blockedUserId: blockedUserId,
                currentUserId: currentUser!.uid,
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// BLOCKED USER TILE
// ==========================================

class BlockedUserTile extends StatefulWidget {
  final String blockedUserId;
  final String currentUserId;

  const BlockedUserTile({
    super.key,
    required this.blockedUserId,
    required this.currentUserId,
  });

  @override
  State<BlockedUserTile> createState() => _BlockedUserTileState();
}

class _BlockedUserTileState extends State<BlockedUserTile> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.blockedUserId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) {
          return const SizedBox.shrink();
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.amber,
            backgroundImage: userData['avatarUrl'] != null
                ? NetworkImage(userData['avatarUrl'])
                : null,
            child: userData['avatarUrl'] == null
                ? Text(
                    (userData['displayName'] ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          title: Text(
            userData['displayName'] ?? userData['email'] ?? 'Ẩn danh',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            userData['email'] ?? '',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          trailing: ElevatedButton.icon(
            onPressed: () => _unblockUser(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            icon: const Icon(Icons.check, color: Colors.black, size: 16),
            label: const Text(
              "Bỏ chặn",
              style: TextStyle(color: Colors.black, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  void _unblockUser() {
    final stateContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Bỏ chặn người dùng?",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              await BlockingSystem(userId: widget.currentUserId)
                  .unblockUser(widget.blockedUserId);
              if (mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(stateContext).showSnackBar(
                  const SnackBar(content: Text("Đã bỏ chặn người dùng")),
                );
              }
            },
            child: const Text("Bỏ chặn", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// QUICK BLOCK DIALOG
// ==========================================

void showBlockDialog(BuildContext context, String userIdToBlock, String currentUserId) {
  final stateContext = context;
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text("Chặn người dùng này?", style: TextStyle(color: Colors.white)),
      content: const Text(
        "Người dùng sẽ không thể xem hồ sơ, bình luận hoặc gửi tin nhắn cho bạn.",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text("Hủy"),
        ),
        TextButton(
          onPressed: () async {
            await BlockingSystem(userId: currentUserId).blockUser(userIdToBlock);
            if (stateContext.mounted) {
              // ignore: use_build_context_synchronously
              Navigator.pop(dialogContext);
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(stateContext).showSnackBar(
                const SnackBar(content: Text("Đã chặn người dùng này")),
              );
            }
          },
          child: const Text("Chặn", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
