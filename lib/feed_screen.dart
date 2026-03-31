import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';
import 'ui_components.dart';
import 'app_utils.dart';
import 'image_url_utils.dart';
import 'ui_button_tokens.dart';
class FeedScreen extends StatefulWidget {
  final String? initialPostId;
  final VoidCallback? onGoToChat;
  final VoidCallback? onGoToGallery;

  const FeedScreen({
    super.key,
    this.initialPostId,
    this.onGoToChat,
    this.onGoToGallery,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  int _currentIndex = 0;
  int _lastPageIndex = 0;
  bool _showOverlayUi = true;

  void _handleFeedPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _showOverlayUi = true;
      _lastPageIndex = index;
    });
  }

  @override
  void dispose() {
    if (currentUser != null) {
      FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({'lastSeen': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    }
    super.dispose();
  }

  Future<void> _deletePost(String postId) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Xóa khoảnh khắc này?", style: TextStyle(color: Colors.white)),
            content: const Text("Hành động này không thể hoàn tác đâu nhé.", style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy", style: TextStyle(color: Colors.white54))),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xóa luôn", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
            ],
          ),
        ) ?? false;

    if (confirm) {
      try {
        if (mounted) Navigator.pop(context);
        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
        if (mounted) {
          setState(() { if (_currentIndex > 0) _currentIndex--; });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa ảnh thành công!")));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  void _showShareMenu(DocumentSnapshot postSnapshot) {
    var data = postSnapshot.data() as Map<String, dynamic>;
    bool isMine = data['email'] == currentUser!.email;

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: const Color(0xFF121418), borderRadius: const BorderRadius.vertical(top: Radius.circular(25)), border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 30),
                const Text("Chia sẻ đến...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                TokenIconButton(icon: Icons.close, size: 34, onTap: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _shareOptionIcon(Icons.ios_share, "Chia sẻ", Colors.grey[800]!), _shareOptionIcon(Icons.chat_bubble, "Tin nhắn", Colors.green),
                _shareOptionIcon(Icons.camera_alt, "Instagram", Colors.pinkAccent), _shareOptionIcon(Icons.snapchat, "Snapchat", Colors.yellow[700]!),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: TokenActionButton(icon: Icons.download_rounded, label: 'Lưu', onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng Lưu ảnh đang phát triển!"))); })),
                const SizedBox(width: 15),
                if (isMine) Expanded(child: TokenActionButton(icon: Icons.delete_outline, label: 'Xóa', onTap: () => _deletePost(postSnapshot.id)))
                else Expanded(child: TokenActionButton(icon: Icons.flag_outlined, label: 'Báo cáo', onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã báo cáo vi phạm."))); })),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _shareOptionIcon(IconData icon, String label, Color color) {
    return PressableScale(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đang mở $label...'))),
      child: Column(children: [Container(width: 55, height: 55, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 30)), const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
      builder: (context, snapshotUser) {
        if (!snapshotUser.hasData) return const Scaffold(backgroundColor: Colors.black, body: LoadingIndicator());

        var userData = snapshotUser.data!.data() as Map<String, dynamic>?;
        List myFriends = userData != null && userData.containsKey('friends') ? List.from(userData['friends']) : [];
        myFriends.add(currentUser!.email);

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshotPosts) {
            if (snapshotPosts.connectionState == ConnectionState.waiting) return const Scaffold(backgroundColor: Colors.black, body: LoadingIndicator());
            if (snapshotPosts.hasError) return Scaffold(backgroundColor: Colors.black, body: ErrorStateWidget(message: 'Không thể tải bài viết', onRetry: () => setState(() {})));

            var allPosts = snapshotPosts.data?.docs ?? [];
            var filteredPosts = allPosts.where((post) {
              var data = post.data() as Map<String, dynamic>;
              String recipient = data['recipient'] ?? 'all'; String recipientUid = data['recipientUid'] ?? '';
              bool isForMe = recipient == 'all' || recipient == currentUser!.email || recipientUid == currentUser!.uid;
              bool isMine = data['email'] == currentUser!.email || data['userId'] == currentUser!.uid;
              bool isFriend = data.containsKey('email') && myFriends.contains(data['email']);
              return (isFriend || isMine) && (isForMe || isMine);
            }).toList();

            if (filteredPosts.isEmpty) return Scaffold(backgroundColor: Colors.black, body: EmptyState(title: 'Chưa có khoảnh khắc nào', subtitle: 'Hãy tạo bài viết đầu tiên của bạn!', icon: Icons.image_not_supported));

            int initialIndex = 0;
            if (widget.initialPostId != null) {
              int foundIndex = filteredPosts.indexWhere((doc) => doc.id == widget.initialPostId);
              if (foundIndex != -1) initialIndex = foundIndex;
            }

            return Scaffold(
              backgroundColor: Colors.black, resizeToAvoidBottomInset: false,
              body: Stack(
                children: [
                  PageView.builder(
                    key: ValueKey(filteredPosts.length),
                    controller: PageController(initialPage: _currentIndex >= filteredPosts.length ? (filteredPosts.isNotEmpty ? filteredPosts.length - 1 : 0) : (_currentIndex == 0 && widget.initialPostId != null ? initialIndex : _currentIndex)),
                    scrollDirection: Axis.vertical, physics: const ClampingScrollPhysics(),
                    onPageChanged: (index) => _handleFeedPageChanged(index),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) => FeedPostItem(post: filteredPosts[index], currentUser: currentUser!),
                  ),

                  Positioned(
                    top: 50, left: 20, right: 20,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 220), curve: Curves.easeOut,
                      offset: _showOverlayUi ? Offset.zero : const Offset(0, -0.35),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 220), opacity: _showOverlayUi ? 1 : 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            PressableScale(onTap: () => mounted ? Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())) : null, child: _headerIcon(Icons.person)),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.38), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withValues(alpha: 0.14))), child: const Row(children: [Text("Mọi người", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), SizedBox(width: 5), Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16)])),
                            PressableScale(
                              onTap: () { if (widget.onGoToChat != null) widget.onGoToChat!(); },
                              child: _headerIcon(Icons.chat_bubble_outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // CỤM NÚT GALLERY (BÊN TRÁI)
                  Positioned(
                    bottom: 30, left: 15,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 240), curve: Curves.easeOut,
                      offset: _showOverlayUi ? Offset.zero : const Offset(0, 0.9),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 240), opacity: _showOverlayUi ? 1 : 0,
                        // ĐỔI THÀNH PressableScale Ở ĐÂY CHO CÓ HIỆU ỨNG NHÚN TỨC THÌ
                        child: PressableScale(
                          onTap: () { if (widget.onGoToGallery != null) widget.onGoToGallery!(); },
                          child: Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle), child: const Icon(Icons.grid_view_rounded, color: Colors.white70, size: 26))
                        )
                      )
                    )
                  ),
                  
                  // CỤM NÚT SHARE (BÊN PHẢI)
                  Positioned(
                    bottom: 30, right: 15,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 240), curve: Curves.easeOut,
                      offset: _showOverlayUi ? Offset.zero : const Offset(0, 0.9),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 240), opacity: _showOverlayUi ? 1 : 0,
                        // ĐỔI THÀNH PressableScale Ở ĐÂY NỮA
                        child: PressableScale(
                          onTap: () {
                            int targetIndex = _currentIndex;
                            if (_currentIndex == 0 && widget.initialPostId != null) { final found = filteredPosts.indexWhere((doc) => doc.id == widget.initialPostId); if (found != -1) targetIndex = found; }
                            if (targetIndex >= filteredPosts.length) targetIndex = filteredPosts.length - 1;
                            if (targetIndex >= 0 && targetIndex < filteredPosts.length) _showShareMenu(filteredPosts[targetIndex]);
                          },
                          child: Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle), child: const Icon(Icons.ios_share, color: Colors.white70, size: 26))
                        )
                      )
                    )
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _headerIcon(IconData icon) {
    return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.38), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.15))), child: Icon(icon, color: Colors.white, size: 22));
  }
}

class FeedPostItem extends StatefulWidget {
  final QueryDocumentSnapshot post; final User currentUser;
  const FeedPostItem({super.key, required this.post, required this.currentUser});
  @override State<FeedPostItem> createState() => _FeedPostItemState();
}

class _FeedPostItemState extends State<FeedPostItem> {
  final TextEditingController _replyController = TextEditingController();
  bool _isSending = false; final List<Widget> _flyingIcons = [];

  Future<void> _sendReply() async {
    final text = _replyController.text.trim(); if (text.isEmpty) return;
    setState(() => _isSending = true);
    var data = widget.post.data() as Map<String, dynamic>;
    String authorUid = data['userId'] ?? ""; String myUid = widget.currentUser.uid;
    if (authorUid.isEmpty) { var userQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: data['email']).get(); if (userQuery.docs.isNotEmpty) authorUid = userQuery.docs.first.id; }
    if (authorUid.isEmpty || authorUid == myUid) { setState(() => _isSending = false); return; }
    String chatId = myUid.compareTo(authorUid) < 0 ? "${myUid}_$authorUid" : "${authorUid}_$myUid";
    try {
      final appContext = context;
      await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add({'senderId': myUid, 'text': text, 'replyToImage': data['imageUrl'], 'timestamp': FieldValue.serverTimestamp()});
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({'lastMessage': "Đã phản hồi ảnh: $text", 'lastTime': FieldValue.serverTimestamp(), 'users': [myUid, authorUid]}, SetOptions(merge: true));
      _replyController.clear(); FocusScope.of(appContext).unfocus(); await SafeContext.showSnackBar(appContext, "Đã gửi tin nhắn!");
    } catch (e) { await SafeContext.showErrorSnackBar(context, "Lỗi: $e"); } finally { if (mounted) setState(() => _isSending = false); }
  }

  void _triggerFlyingIcons(String emoji) {
    for (int i = 0; i < 12; i++) {
      double randomOffset = (Random().nextDouble() * 40) - 20;
      Widget iconWidget = Positioned(bottom: 180, right: 40 + randomOffset, child: _FlyingIconAnimation(emoji: emoji, onFinished: () {}));
      setState(() => _flyingIcons.add(iconWidget)); if (_flyingIcons.length > 50) _flyingIcons.removeAt(0);
    }
  }

  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return ""; DateTime d = timestamp.toDate(); Duration diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return "Vừa xong"; if (diff.inMinutes < 60) return "${diff.inMinutes}ph"; if (diff.inHours < 24) return "${diff.inHours}h"; return "${d.day} thg ${d.month}";
  }

  @override Widget build(BuildContext context) {
    var data = widget.post.data() as Map<String, dynamic>;
    final String imageUrl = data['imageUrl']?.toString() ?? ''; final bool hasValidImage = isRenderableImageUrl(imageUrl); final imageBytes = decodeDataImageUrl(imageUrl); String? caption = data['caption'];
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 80),
              Expanded(flex: 6, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Stack(children: [Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(30), child: hasValidImage ? (imageBytes != null ? Image.memory(imageBytes, fit: BoxFit.cover) : Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900], alignment: Alignment.center, child: const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 40)))) : Container(color: Colors.grey[900], alignment: Alignment.center, child: const Icon(Icons.image_not_supported_outlined, color: Colors.white38, size: 40)))), if (caption != null && caption.isNotEmpty) Positioned(bottom: 20, left: 0, right: 0, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)), child: Text(caption, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600), textAlign: TextAlign.center))))]))),
              const SizedBox(height: 16),
              FutureBuilder<QuerySnapshot>(future: FirebaseFirestore.instance.collection('users').where('email', isEqualTo: data['email']).limit(1).get(), builder: (context, snapshot) { String? avatarUrl; if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) avatarUrl = (snapshot.data!.docs.first.data() as Map<String, dynamic>)['avatarUrl']; return Row(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(radius: 14, backgroundColor: Colors.grey[800], backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null, child: avatarUrl == null ? Text(data['author']?[0] ?? "A", style: const TextStyle(fontSize: 11, color: Colors.white)) : null), const SizedBox(width: 10), Text(data['author'] ?? "Ẩn danh", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(width: 10), Text(_timeAgo(data['timestamp']), style: const TextStyle(color: Colors.white54, fontSize: 12))]); }),
              const SizedBox(height: 18),
              Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(35), border: Border.all(color: Colors.white.withValues(alpha: 0.08))), child: Row(children: [Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.06))), child: TextField(controller: _replyController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(hintText: "Gửi tin nhắn...", hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14), filled: false, fillColor: Colors.transparent, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, disabledBorder: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), isDense: true), cursorColor: Colors.amber, onSubmitted: (_) => _sendReply()))), if (_isSending) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2)), _BounceableIcon(emoji: "🔥", onTap: () => _triggerFlyingIcons("🔥")), _BounceableIcon(emoji: "💛", onTap: () => _triggerFlyingIcons("💛")), _BounceableIcon(emoji: "😍", onTap: () => _triggerFlyingIcons("😍")), PressableScale(onTap: () {}, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.sentiment_satisfied_alt, color: Color.fromARGB(137, 58, 57, 57), size: 24)))]),),
              const SizedBox(height: 100),
            ],
          ),
          IgnorePointer(child: Stack(children: _flyingIcons)),
        ],
      ),
    );
  }
}

class _FlyingIconAnimation extends StatefulWidget {
  final String emoji; final VoidCallback onFinished;
  const _FlyingIconAnimation({required this.emoji, required this.onFinished});
  @override State<_FlyingIconAnimation> createState() => _FlyingIconAnimationState();
}

class _FlyingIconAnimationState extends State<_FlyingIconAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<double> _yAnim, _xAnim, _opacityAnim, _scaleAnim; final Random _random = Random();
  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500)); _yAnim = Tween<double>(begin: 0, end: -300 - _random.nextDouble() * 200).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)); _xAnim = Tween<double>(begin: 0, end: (_random.nextDouble() * 100) - 50).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)); _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0))); _scaleAnim = Tween<double>(begin: 0.5, end: 1.2).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2, curve: Curves.easeOutBack))); _controller.forward().then((_) => widget.onFinished()); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { return AnimatedBuilder(animation: _controller, builder: (context, child) => Transform.translate(offset: Offset(_xAnim.value, _yAnim.value), child: Opacity(opacity: _opacityAnim.value, child: Transform.scale(scale: _scaleAnim.value, child: Text(widget.emoji, style: const TextStyle(fontSize: 28)))))); }
}

class _BounceableIcon extends StatefulWidget {
  final String emoji; final VoidCallback onTap;
  const _BounceableIcon({required this.emoji, required this.onTap});
  @override State<_BounceableIcon> createState() => _BounceableIconState();
}

class _BounceableIconState extends State<_BounceableIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<double> _scaleAnimation;
  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200), reverseDuration: const Duration(milliseconds: 150)); _scaleAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { return GestureDetector(onTap: () { _controller.reset(); _controller.forward().then((_) => _controller.reverse()); widget.onTap(); }, behavior: HitTestBehavior.translucent, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: ScaleTransition(scale: _scaleAnimation, child: Text(widget.emoji, style: const TextStyle(fontSize: 26))))); }
}