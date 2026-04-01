import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_layout.dart';
import 'image_url_utils.dart';
import 'ui_widgets.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const SizedBox(),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(20)),
              child: const Row(
                children: [
                  Text("Mọi người", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(width: 5),
                  Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshotUser) {
          if (!snapshotUser.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));

          var userData = snapshotUser.data?.data() as Map<String, dynamic>?;
          List myFriends = userData != null && userData.containsKey('friends') ? List.from(userData['friends']) : [];
          myFriends.add(currentUser.email);

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshotPosts) {
              if (snapshotPosts.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));

              var allPosts = snapshotPosts.data?.docs ?? [];
              var filteredPosts = allPosts.where((post) {
                var data = post.data() as Map<String, dynamic>;
                String recipient = data['recipient'] ?? 'all';
                String recipientUid = data['recipientUid'] ?? '';
                bool isFriendOrMe = data.containsKey('email') && myFriends.contains(data['email']);
                bool canView = recipient == 'all' || recipient == currentUser.email || recipientUid == currentUser.uid || data['email'] == currentUser.email;
                return isFriendOrMe && canView;
              }).toList();

              if (filteredPosts.isEmpty) {
                return Center(
                  child: EmptyState(
                    icon: Icons.grid_view_rounded,
                    title: 'Chua co khoanh khac nao',
                    subtitle: 'Hay chup va gui anh dau tien de lap day gallery.',
                    actionLabel: 'Mo camera',
                    onAction: () {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainLayout(initialTab: 1)), (route) => false);
                    },
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 120), // Khoảng trống cho Navi MainLayout đè lên
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.7,
                ),
                itemCount: filteredPosts.length,
                itemBuilder: (context, index) {
                  var post = filteredPosts[index];
                  var data = post.data() as Map<String, dynamic>;
                  final String imageUrl = data['imageUrl']?.toString() ?? '';
                  final bool hasValidImage = isRenderableImageUrl(imageUrl);
                  final imageBytes = decodeDataImageUrl(imageUrl);

                  return GestureDetector(
                    onTap: () => Navigator.pushAndRemoveUntil(
                        context, 
                        // BẤM VÀO ẢNH SẼ CHUYỂN NGAY VỀ MAINLAYOUT(TAB HOME) KÈM THEO ID ẢNH
                        MaterialPageRoute(builder: (context) => MainLayout(initialTab: 1, initialHomeVerticalPage: 1, initialPostId: post.id)), 
                        (route) => false
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: hasValidImage
                          ? (imageBytes != null
                                ? Image.memory(imageBytes, fit: BoxFit.cover)
                                : Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900], alignment: Alignment.center, child: const Icon(Icons.broken_image_outlined, color: Colors.white38))))
                          : Container(color: Colors.grey[900], alignment: Alignment.center, child: const Icon(Icons.image_not_supported_outlined, color: Colors.white38)),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}