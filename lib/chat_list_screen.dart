import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_screen.dart'; // <--- DÒNG QUAN TRỌNG NÀY ĐANG BỊ THIẾU

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Trò chuyện", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // 1. Lấy danh sách bạn bè từ Firestore
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));

          var userData = snapshot.data!.data() as Map<String, dynamic>?;
          List friends = userData != null && userData.containsKey('friends') ? userData['friends'] : [];

          if (friends.isEmpty) {
            return const Center(child: Text("Chưa có bạn bè nào để chat", style: TextStyle(color: Colors.white54)));
          }

          // 2. Hiển thị danh sách
          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              String friendEmail = friends[index];
              // Lấy tên từ email (ví dụ giang@gmail.com -> giang)
              String displayName = friendEmail.split('@')[0];

              return FutureBuilder<QuerySnapshot>(
                // Tìm thông tin UID của bạn bè để lấy avatar và uid (cần để tạo phòng chat)
                future: FirebaseFirestore.instance.collection('users').where('email', isEqualTo: friendEmail).limit(1).get(),
                builder: (context, friendSnap) {
                  String? friendUid;
                  String? avatarUrl;
                  
                  if (friendSnap.hasData && friendSnap.data!.docs.isNotEmpty) {
                    var doc = friendSnap.data!.docs.first;
                    friendUid = doc.id;
                    avatarUrl = (doc.data() as Map<String, dynamic>)['avatarUrl'];
                  }

                  return ListTile(
                    onTap: () {
                      if (friendUid != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              friendUid: friendUid!,
                              friendName: displayName,
                              friendEmail: friendEmail,
                            ),
                          ),
                        );
                      }
                    },
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[800],
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null 
                          ? Text(displayName[0].toUpperCase(), style: const TextStyle(color: Colors.white)) 
                          : null,
                    ),
                    title: Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Bấm để nhắn tin", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: const Icon(Icons.chat_bubble, color: Colors.amber),
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