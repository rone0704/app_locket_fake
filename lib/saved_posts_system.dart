import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ==========================================
// HỆ THỐNG LƯU BÀI VIẾT/FAVORITES
// ==========================================

class SavedPostsSystem {
  final String userId;

  SavedPostsSystem({required this.userId});

  // Lưu bài viết
  Future<void> savePost(String postId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('savedPosts')
        .doc(postId)
        .set({
      'postId': postId,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  // Bỏ lưu bài viết
  Future<void> unsavePost(String postId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('savedPosts')
        .doc(postId)
        .delete();
  }

  // Kiểm tra bài viết có được lưu không
  Future<bool> isPostSaved(String postId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('savedPosts')
        .doc(postId)
        .get();
    return doc.exists;
  }

  // Lấy danh sách bài viết đã lưu
  static Stream<QuerySnapshot> getSavedPosts(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('savedPosts')
        .orderBy('savedAt', descending: true)
        .snapshots();
  }
}

// ==========================================
// SAVED POSTS SCREEN
// ==========================================

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
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
          "Bài viết đã lưu",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: SavedPostsSystem.getSavedPosts(currentUser!.uid),
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
                  const Icon(Icons.bookmark_outline, color: Colors.white54, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    "Chưa có bài viết nào được lưu",
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    child: const Text(
                      "Quay lại",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            );
          }

          final savedPostIds = snapshot.data!.docs
              .map((doc) => (doc.data() as Map)['postId'] as String)
              .toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: savedPostIds.length,
            itemBuilder: (context, index) {
              return SavedPostTile(
                postId: savedPostIds[index],
                userId: currentUser!.uid,
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// SAVED POST TILE
// ==========================================

class SavedPostTile extends StatefulWidget {
  final String postId;
  final String userId;

  const SavedPostTile({
    super.key,
    required this.postId,
    required this.userId,
  });

  @override
  State<SavedPostTile> createState() => _SavedPostTileState();
}

class _SavedPostTileState extends State<SavedPostTile> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }

        final post = snapshot.data!.data() as Map<String, dynamic>?;
        if (post == null) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.error, color: Colors.white54),
            ),
          );
        }

        return GestureDetector(
          onTap: () => _openPost(context),
          onLongPress: () => _showOptions(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(post['imageUrl'] ?? ''),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {},
              ),
              color: Colors.grey[900],
            ),
            child: Stack(
              children: [
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                ),
                // Info
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((post['author'] ?? '').isNotEmpty)
                        Text(
                          post['author'] ?? 'Ẩn danh',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if ((post['caption'] ?? '').isNotEmpty)
                        Text(
                          post['caption'] ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Save icon
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark, color: Colors.black, size: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPost(BuildContext context) {
    // TODO: Navigate to post detail
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.bookmark_remove, color: Colors.amber),
            title: const Text("Bỏ lưu", style: TextStyle(color: Colors.white)),
            onTap: () async {
              await SavedPostsSystem(userId: widget.userId)
                  .unsavePost(widget.postId);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã bỏ lưu bài viết")),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.amber),
            title: const Text("Chia sẻ", style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
