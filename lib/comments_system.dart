import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ==========================================
// HỆ THỐNG BÌNH LUẬN & TRẢ LỜI
// ==========================================

class CommentSystem {
  final String postId;
  final String userId;
  final String userName;
  final String userEmail;

  CommentSystem({
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  // Thêm bình luận
  Future<void> addComment(String text) async {
    if (text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
      'replies': 0,
    });
  }

  // Thêm trả lời
  Future<void> addReply(String commentId, String text) async {
    if (text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .add({
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
    });

    // Cập nhật reply count
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({
      'replies': FieldValue.increment(1),
    });
  }

  // Xóa bình luận
  Future<void> deleteComment(String commentId) async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  // Xóa trả lời
  Future<void> deleteReply(String commentId, String replyId) async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(replyId)
        .delete();

    // Giảm reply count
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({
      'replies': FieldValue.increment(-1),
    });
  }

  // Like bình luận
  Future<void> likeComment(String commentId) async {
    final commentRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final doc = await transaction.get(commentRef);
      List likes = List<String>.from(doc['likes'] ?? []);

      if (!likes.contains(userId)) {
        likes.add(userId);
      }

      transaction.update(commentRef, {'likes': likes});
    });
  }

  // Unlike bình luận
  Future<void> unlikeComment(String commentId) async {
    final commentRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final doc = await transaction.get(commentRef);
      List likes = List<String>.from(doc['likes'] ?? []);
      likes.remove(userId);

      transaction.update(commentRef, {'likes': likes});
    });
  }
}

// ==========================================
// WIDGET BÌNH LUẬN
// ==========================================

class CommentWidget extends StatefulWidget {
  final DocumentSnapshot comment;
  final String postId;
  final User currentUser;
  final bool isReply;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.postId,
    required this.currentUser,
    this.isReply = false,
  });

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget>
    with TickerProviderStateMixin {
  bool _showReplyInput = false;
  final TextEditingController _replyController = TextEditingController();
  bool _isSending = false;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticInOut),
    );
  }

  void _bounce() {
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.comment.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp?;
    final timeStr = timestamp != null
        ? "${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
        : "Bây giờ";

    return SingleChildScrollView(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber,
              child: Text(
                (data['userName'] as String?)?.isNotEmpty == true
                    ? (data['userName'] as String).substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              data['userName'] ?? 'Ẩn danh',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              timeStr,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            trailing: data['userId'] == widget.currentUser.uid
                ? PopupMenuButton(
                    color: Colors.grey[900],
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text("Xóa", style: TextStyle(color: Colors.red)),
                        onTap: () => _deleteComment(),
                      ),
                    ],
                  )
                : null,
          ),
        Padding(
          padding: const EdgeInsets.only(left: 70, right: 16, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['text'] ?? '',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleLike(data['likes'] ?? []),
                    child: Text(
                      "❤️ Thích",
                      style: TextStyle(
                        color: ((data['likes'] ?? []) as List).contains(widget.currentUser.uid)
                            ? Colors.red
                            : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (!widget.isReply)
                    GestureDetector(
                      onTap: () {
                        _bounce();
                        setState(() => _showReplyInput = !_showReplyInput);
                      },
                      child: AnimatedBuilder(
                        animation: _bounceAnimation,
                        builder: (context, child) => Transform.scale(
                          scale: _bounceAnimation.value,
                          child: const Text(
                            "💬 Trả lời",
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 16),
                  if ((data['likes'] ?? []).isNotEmpty)
                    Text(
                      "${(data['likes'] ?? []).length} thích",
                      style: const TextStyle(color: Colors.amber, fontSize: 11),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Hiển thị replies
        if (!widget.isReply && (data['replies'] ?? 0) > 0)
          Padding(
            padding: const EdgeInsets.only(left: 70, bottom: 8),
            child: GestureDetector(
              onTap: () => _showReplies(),
              child: Text(
                "Xem ${data['replies']} trả lời",
                style: const TextStyle(color: Colors.amber, fontSize: 12),
              ),
            ),
          ),
        // Input trả lời
        if (_showReplyInput && !widget.isReply)
          Padding(
            padding: EdgeInsets.only(
              left: 70,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 80,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Trả lời...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.amber, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending ? null : () => _sendReply(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.black, size: 18),
                  ),
                ),
              ],
            ),
          ),
        const Divider(color: Colors.grey, height: 1),
      ],      ),    );
  }

  void _toggleLike(List likes) async {
    final likeList = List<String>.from(likes);
    final system = CommentSystem(
      postId: widget.postId,
      userId: widget.currentUser.uid,
      userName: widget.currentUser.displayName ?? 'Ẩn danh',
      userEmail: widget.currentUser.email ?? '',
    );

    if (likeList.contains(widget.currentUser.uid)) {
      await system.unlikeComment(widget.comment.id);
    } else {
      await system.likeComment(widget.comment.id);
    }
  }

  void _deleteComment() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Xóa bình luận?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              final system = CommentSystem(
                postId: widget.postId,
                userId: widget.currentUser.uid,
                userName: widget.currentUser.displayName ?? 'Ẩn danh',
                userEmail: widget.currentUser.email ?? '',
              );
              await system.deleteComment(widget.comment.id);
              if (mounted) Navigator.pop(dialogContext);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _sendReply() async {
    setState(() => _isSending = true);

    final system = CommentSystem(
      postId: widget.postId,
      userId: widget.currentUser.uid,
      userName: widget.currentUser.displayName ?? 'Ẩn danh',
      userEmail: widget.currentUser.email ?? '',
    );

    await system.addReply(widget.comment.id, _replyController.text);
    _replyController.clear();

    if (mounted) {
      setState(() => _isSending = false);
      setState(() => _showReplyInput = false);
    }
  }

  void _showReplies() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Trả lời", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.postId)
                .collection('comments')
                .doc(widget.comment.id)
                .collection('replies')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (streamContext, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (listContext, index) {
                    return CommentWidget(
                      comment: snapshot.data!.docs[index],
                      postId: widget.postId,
                      currentUser: widget.currentUser,
                      isReply: true,
                    );
                  },
                );
              }
              return const CircularProgressIndicator(color: Colors.amber);
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    _bounceController.dispose();
    super.dispose();
  }
}
