import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> data;

  const PostDetailScreen({super.key, required this.postId, required this.data});

  // Hàm thả cảm xúc
  Future<void> _sendReaction(String emoji) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Lưu reaction dưới dạng: "email|emoji" (Ví dụ: giang@gmail.com|❤️)
    String reactionValue = "${user.email}|$emoji";

    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'reactions': FieldValue.arrayUnion([reactionValue])
    });
  }

  @override
  Widget build(BuildContext context) {
    // Xử lý link ảnh giả lập (nếu có)
    String imageUrl = data['imageUrl'];
    if (!imageUrl.startsWith('http') || imageUrl.contains('picsum')) {
      imageUrl = "https://picsum.photos/seed/$postId/400/600";
    }

    // Xử lý tên author an toàn hơn (tránh lỗi nếu tên rỗng)
    String authorName = data['author'] ?? "Ẩn danh";
    String firstLetter = (authorName.isNotEmpty) ? authorName[0].toUpperCase() : "A";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true, // Để ảnh tràn lên cả thanh status bar
      body: Column(
        children: [
          // 1. ẢNH TOÀN MÀN HÌNH
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                // Lớp phủ đen mờ bên dưới để chữ dễ đọc
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.6, 1.0],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar & Tên người đăng
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.amber,
                          radius: 15,
                          child: Text(firstLetter, 
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          authorName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Gửi lúc: ${_formatTimestamp(data['timestamp'])}",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    // Hiển thị Caption nếu có
                    if (data['caption'] != null && data['caption'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          data['caption'],
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 2. KHU VỰC CẢM XÚC (REACTIONS)
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              children: [
                // Hiển thị danh sách Reaction đã thả
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('posts').doc(postId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    
                    var postData = snapshot.data!.data() as Map<String, dynamic>?;
                    List reactions = postData != null && postData.containsKey('reactions') 
                        ? List.from(postData['reactions']) 
                        : [];

                    if (reactions.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text("Hãy là người đầu tiên thả tim!", style: TextStyle(color: Colors.grey)),
                      );
                    }

                    return SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: reactions.length,
                        itemBuilder: (context, index) {
                          String reaction = reactions[index]; // Dạng: email|emoji
                          String emoji = reaction.split('|').last; // Lấy phần emoji
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(emoji, style: const TextStyle(fontSize: 24)),
                          );
                        },
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 15),

                // Thanh chọn Emoji
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _emojiButton("❤️"),
                    _emojiButton("😂"),
                    _emojiButton("🔥"),
                    _emojiButton("😍"),
                    _emojiButton("😢"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget nút bấm Emoji
  Widget _emojiButton(String emoji) {
    return GestureDetector(
      onTap: () => _sendReaction(emoji),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          shape: BoxShape.circle,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Vừa xong";
    DateTime date = timestamp.toDate();
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}";
  }
}