import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_layout.dart';
import 'chat_detail_screen.dart'; 
import 'ui_button_tokens.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: TokenIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            size: 38,
            // NÚT BACK CỦA CHAT GIỜ SẼ VỀ LẠI CAMERA (MAINLAYOUT)
            onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainLayout()), (route) => false),
          ),
        ),
        title: const Text("Trò chuyện", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));

          var userData = snapshot.data!.data() as Map<String, dynamic>?;
          List friends = userData != null && userData.containsKey('friends') ? userData['friends'] : [];

          if (friends.isEmpty) {
            return const Center(child: Text("Chưa có bạn bè nào để chat", style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 120), // ĐẨY LIST LÊN CAO CHO NAVI NẰM DƯỚI
            itemCount: friends.length,
            itemBuilder: (context, index) {
              String friendEmail = friends[index];
              String displayName = friendEmail.split('@')[0];

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('users').where('email', isEqualTo: friendEmail).limit(1).get(),
                builder: (context, friendSnap) {
                  String? friendUid;
                  String? avatarUrl;
                  
                  if (friendSnap.hasData && friendSnap.data!.docs.isNotEmpty) {
                    var doc = friendSnap.data!.docs.first;
                    friendUid = doc.id;
                    avatarUrl = (doc.data() as Map<String, dynamic>)['avatarUrl'];
                  }

                  return PressableScale(
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
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.34),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[800],
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null ? Text(displayName[0].toUpperCase(), style: const TextStyle(color: Colors.white)) : null,
                        ),
                        title: Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: const Text("Bấm để nhắn tin", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: const TokenIconButton(icon: Icons.chat_bubble_outline_rounded, size: 34),
                      ),
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