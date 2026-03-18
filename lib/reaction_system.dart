import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ==========================================
// HỆ THỐNG REACTION/LIKE
// ==========================================

class ReactionSystem {
  final String postId;
  final String userId;

  ReactionSystem({required this.postId, required this.userId});

  // Emoji reactions
  static const Map<String, String> reactions = {
    '❤️': 'love',
    '😂': 'laugh',
    '😮': 'wow',
    '😢': 'sad',
    '😡': 'angry',
    '🔥': 'fire',
  };

  // Thêm reaction
  Future<void> addReaction(String emoji) async {
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(postId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final doc = await transaction.get(postRef);
      final reactions = Map<String, dynamic>.from(doc['reactions'] ?? {});

      final reactionKey = ReactionSystem.reactions[emoji] ?? 'love';

      if (reactions[reactionKey] == null) {
        reactions[reactionKey] = [];
      }

      final userList = List<String>.from(reactions[reactionKey] ?? []);
      if (!userList.contains(userId)) {
        userList.add(userId);
        reactions[reactionKey] = userList;
      }

      transaction.update(postRef, {'reactions': reactions});
    });
  }

  // Xóa reaction
  Future<void> removeReaction(String emoji) async {
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(postId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final doc = await transaction.get(postRef);
      final reactions = Map<String, dynamic>.from(doc['reactions'] ?? {});

      final reactionKey = ReactionSystem.reactions[emoji] ?? 'love';

      if (reactions[reactionKey] != null) {
        final userList = List<String>.from(reactions[reactionKey] ?? []);
        userList.remove(userId);
        if (userList.isEmpty) {
          reactions.remove(reactionKey);
        } else {
          reactions[reactionKey] = userList;
        }
      }

      transaction.update(postRef, {'reactions': reactions});
    });
  }

  // Lấy danh sách người đã reaction
  Future<List<String>> getUsersReacted(String emoji) async {
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .get();
    final reactions = Map<String, dynamic>.from(doc['reactions'] ?? {});
    final reactionKey = ReactionSystem.reactions[emoji] ?? 'love';
    return List<String>.from(reactions[reactionKey] ?? []);
  }

  // Kiểm tra user đã reaction chưa
  Future<String?> getUserReaction() async {
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .get();
    final reactions = Map<String, dynamic>.from(doc['reactions'] ?? {});

    for (var entry in reactions.entries) {
      final userList = List<String>.from(entry.value ?? []);
      if (userList.contains(userId)) {
        return ReactionSystem.reactions.entries
            .firstWhere((e) => e.value == entry.key,
                orElse: () => MapEntry('❤️', 'love'))
            .key;
      }
    }
    return null;
  }
}

// ==========================================
// WIDGET HỌC REACTION
// ==========================================

class ReactionPicker extends StatelessWidget {
  final String postId;
  final VoidCallback onClose;

  const ReactionPicker({
    super.key,
    required this.postId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Cảm xúc của bạn", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ReactionSystem.reactions.keys
                .map((emoji) => _buildReactionButton(
                      context: context,
                      emoji: emoji,
                      postId: postId,
                      userId: currentUser.uid,
                      onTap: onClose,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton({
    required BuildContext context,
    required String emoji,
    required String postId,
    required String userId,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () async {
        await ReactionSystem(postId: postId, userId: userId)
            .addReaction(emoji);
        onTap();
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}

// ==========================================
// HIỂN THỊ REACTIONS
// ==========================================

class ReactionDisplay extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> reactions;

  const ReactionDisplay({
    super.key,
    required this.postId,
    required this.reactions,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: reactions.entries.map((entry) {
          final reactionKey = entry.key;
          final userCount = (entry.value as List?)?.length ?? 0;
          final emoji = ReactionSystem.reactions.entries
              .firstWhere((e) => e.value == reactionKey,
                  orElse: () => MapEntry('❤️', 'love'))
              .key;

          return GestureDetector(
            onTap: () {
              _showReactionViewer(context, postId, emoji);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    '$userCount',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showReactionViewer(BuildContext context, String postId, String emoji) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("Những ai đã $emoji",
            style: const TextStyle(color: Colors.white)),
        content: FutureBuilder<List<String>>(
          future:
              ReactionSystem(postId: postId, userId: '').getUsersReacted(emoji),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: snapshot.data!
                    .map((userId) => FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .get(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.hasData) {
                              final userData =
                                  userSnapshot.data!.data() as Map?;
                              return Text(
                                userData?['displayName'] ?? userData?['email'] ?? 'Ẩn danh',
                                style: const TextStyle(color: Colors.white70),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ))
                    .toList(),
              );
            }
            return const CircularProgressIndicator(color: Colors.amber);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}
