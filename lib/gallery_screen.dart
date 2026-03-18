import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'feed_screen.dart'; 
import 'home_screen.dart';
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
              child: const Row(children: [Text("Mọi người", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), SizedBox(width: 5), Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20)]),
            ),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.white), onPressed: () {})],
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
                bool isFriendOrMe = data.containsKey('email') && myFriends.contains(data['email']);
                bool canView = recipient == 'all' || recipient == currentUser.email || data['email'] == currentUser.email;
                return isFriendOrMe && canView;
              }).toList();

              if (filteredPosts.isEmpty) return const Center(child: Text("Chưa có khoảnh khắc nào", style: TextStyle(color: Colors.white54)));

              return Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.7),
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        var post = filteredPosts[index];
                        var data = post.data() as Map<String, dynamic>;
                        String imageUrl = data['imageUrl'];
                        if (!imageUrl.startsWith('http')) imageUrl = "https://picsum.photos/seed/${post.id}/400/600";

                        // --- HIỂN THỊ ẢNH (ClipRRect) ---
                        return GestureDetector(
                          onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => FeedScreen(initialPostId: post.id)));
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(imageUrl, fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(color: Colors.grey[900]);
                            }),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // --- NÚT CHỤP Ở DƯỚI CÙNG (LOGIC QUAY VỀ CAMERA) ---
                  // Nút chụp ảnh ở giữa dưới cùng
                 // Nút chụp ảnh ở giữa dưới cùng
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, top: 10),
                  child: GestureDetector(
                    onTap: () {
                      // SỬA LẠI: Quay về HomeScreen
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()), // <--- ĐỔI CameraScreen THÀNH HomeScreen
                        (route) => false,
                      );
                    }, 
                    child: Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 4),
                        color: Colors.white
                      ),
                    ),
                  ),
                )
                ],
              );
            },
          );
        },
      ),
    );
  }
}