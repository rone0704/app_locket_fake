import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ==========================================
// CHAT ENHANCEMENTS (Typing + Read Receipts)
// ==========================================

class ChatEnhancements {
  final String chatId;
  final String userId;

  ChatEnhancements({required this.chatId, required this.userId});

  // Thông báo đang gõ
  Future<void> setTypingStatus(bool isTyping) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('typingIndicators')
        .doc(userId)
        .set({
      'userId': userId,
      'isTyping': isTyping,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Lấy trạng thái gõ
  static Stream<QuerySnapshot> getTypingStatus(String chatId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('typingIndicators')
        .where('isTyping', isEqualTo: true)
        .snapshots();
  }

  // Đánh dấu tin nhắn là đã xem
  Future<void> markMessageAsRead(String messageId) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'readBy': FieldValue.arrayUnion([userId]),
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // Đánh dấu tất cả tin nhắn trong chat là đã xem
  Future<void> markAllMessagesAsRead() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    for (var doc in snapshot.docs) {
      final readBy = doc.data()['readBy'] as List? ?? [];
      if (!readBy.contains(userId)) {
        await doc.reference.update({
          'readBy': FieldValue.arrayUnion([userId]),
          'readAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }
}

// ==========================================
// TYPING INDICATOR
// ==========================================

class TypingIndicator extends StatelessWidget {
  final String chatId;
  final String currentUserId;

  const TypingIndicator({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: ChatEnhancements.getTypingStatus(chatId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final typingUsers = snapshot.data!.docs
            .where((doc) => (doc['userId'] ?? '') != currentUserId)
            .toList();

        if (typingUsers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: _TypingAnimation(),
              ),
              const SizedBox(width: 8),
              Text(
                typingUsers.length == 1
                    ? "${typingUsers.length} người đang gõ..."
                    : "${typingUsers.length} người đang gõ...",
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// TYPING ANIMATION
// ==========================================

class _TypingAnimation extends StatefulWidget {
  const _TypingAnimation();

  @override
  State<_TypingAnimation> createState() => _TypingAnimationState();
}

class _TypingAnimationState extends State<_TypingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        return ScaleTransition(
          scale: Tween(begin: 0.8, end: 1.2).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval((index) / 3, (index + 1) / 3),
            ),
          ),
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ==========================================
// MESSAGE WITH READ RECEIPTS
// ==========================================

class MessageWithReadReceipts extends StatelessWidget {
  final DocumentSnapshot message;
  final List<String> friendEmails;

  const MessageWithReadReceipts({
    super.key,
    required this.message,
    required this.friendEmails,
  });

  @override
  Widget build(BuildContext context) {
    final data = message.data() as Map<String, dynamic>;
    final readBy = List<String>.from(data['readBy'] ?? []);
    final timestamp = data['timestamp'] as Timestamp?;
    final textContent = data['content'] ?? '';

    // Đếm số người đã đọc
    final readCount = readBy.length;
    final totalFriends = friendEmails.length;

    // Format time
    String timeStr = '';
    if (timestamp != null) {
      final dateTime = timestamp.toDate();
      timeStr =
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    textContent,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                      if (readCount > 0) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.done_all, color: Colors.blue, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          "$readCount/$totalFriends",
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Show avatars of readers
          if (readCount > 0)
            GestureDetector(
              onTap: () => _showReaders(context, readBy),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "$readCount",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showReaders(BuildContext context, List<String> readBy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Đã xem",
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: readBy.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  readBy[index],
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
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

// ==========================================
// ENHANCED CHAT INPUT
// ==========================================

class EnhancedChatInput extends StatefulWidget {
  final String chatId;
  final String userId;
  final ValueChanged<String> onSendMessage;

  const EnhancedChatInput({
    super.key,
    required this.chatId,
    required this.userId,
    required this.onSendMessage,
  });

  @override
  State<EnhancedChatInput> createState() => _EnhancedChatInputState();
}

class _EnhancedChatInputState extends State<EnhancedChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTyping);
  }

  void _onTyping() {
    if (_controller.text.isNotEmpty && !_isTyping) {
      setState(() => _isTyping = true);
      ChatEnhancements(chatId: widget.chatId, userId: widget.userId)
          .setTypingStatus(true);
    } else if (_controller.text.isEmpty && _isTyping) {
      setState(() => _isTyping = false);
      ChatEnhancements(chatId: widget.chatId, userId: widget.userId)
          .setTypingStatus(false);
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    widget.onSendMessage(_controller.text);
    _controller.clear();

    ChatEnhancements(chatId: widget.chatId, userId: widget.userId)
        .setTypingStatus(false);
    setState(() => _isTyping = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey[900],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              decoration: InputDecoration(
                hintText: "Nhập tin nhắn...",
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.amber),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
