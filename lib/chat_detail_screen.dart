import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDetailScreen extends StatefulWidget {
  final String friendUid;
  final String friendName;
  final String friendEmail;

  const ChatDetailScreen({
    super.key,
    required this.friendUid,
    required this.friendName,
    required this.friendEmail,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  late String chatId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final String myUid = currentUser!.uid;
    final String otherUid = widget.friendUid;
    chatId = myUid.compareTo(otherUid) < 0 ? "${myUid}_$otherUid" : "${otherUid}_$myUid";
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add({
      'senderId': currentUser!.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'lastMessage': text,
      'lastTime': FieldValue.serverTimestamp(),
      'users': [currentUser!.uid, widget.friendUid]
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.friendName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.friendEmail, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
                var messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msg = messages[index].data() as Map<String, dynamic>;
                    bool isMe = msg['senderId'] == currentUser!.uid;
                    String? replyImage = msg['replyToImage'];

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.amber : Colors.grey[800],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(15),
                            topRight: const Radius.circular(15),
                            bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (replyImage != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                width: 150, 
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(image: NetworkImage(replyImage), fit: BoxFit.cover),
                                  border: Border.all(color: Colors.white24, width: 1)
                                ),
                              ),
                            Text(msg['text'] ?? "", style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 16)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Nhắn tin...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true, fillColor: Colors.black,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.amber), child: const Icon(Icons.send, color: Colors.black, size: 20)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}