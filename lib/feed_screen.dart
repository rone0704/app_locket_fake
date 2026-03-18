import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gallery_screen.dart'; 
import 'home_screen.dart'; 
import 'profile_screen.dart';
import 'chat_list_screen.dart';
import 'ui_components.dart';
import 'app_utils.dart';

class FeedScreen extends StatefulWidget {
  final String? initialPostId;

  const FeedScreen({super.key, this.initialPostId});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  int _currentIndex = 0;
  
  @override
  void dispose() {
    if (currentUser != null) {
      FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({
        'lastSeen': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));
    }
    super.dispose();
  }

  // --- HÀM XÓA BÀI VIẾT ---
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
        if (mounted) {
          Navigator.pop(context); 
        }
        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
        if (mounted) {
          setState(() { if (_currentIndex > 0) _currentIndex--; });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa ảnh thành công!")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
        }
      }
    }
  }

  // --- MENU SHARE ---
  void _showShareMenu(DocumentSnapshot postSnapshot) {
    var data = postSnapshot.data() as Map<String, dynamic>;
    bool isMine = data['email'] == currentUser!.email;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 30),
                const Text("Chia sẻ đến...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.grey[800], shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _shareOptionIcon(Icons.ios_share, "Chia sẻ", Colors.grey[800]!),
                _shareOptionIcon(Icons.chat_bubble, "Tin nhắn", Colors.green),
                _shareOptionIcon(Icons.camera_alt, "Instagram", Colors.pinkAccent),
                _shareOptionIcon(Icons.snapchat, "Snapchat", Colors.yellow[700]!),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng Lưu ảnh đang phát triển!")));
                    },
                    icon: const Icon(Icons.download_rounded, color: Colors.white),
                    label: const Text("Lưu", style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  ),
                ),
                const SizedBox(width: 15),
                if (isMine)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deletePost(postSnapshot.id),
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      label: const Text("Xóa", style: TextStyle(color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    ),
                  )
                else
                   Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                         Navigator.pop(context);
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã báo cáo vi phạm.")));
                      },
                      icon: const Icon(Icons.flag_outlined, color: Colors.white),
                      label: const Text("Báo cáo", style: TextStyle(color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _shareOptionIcon(IconData icon, String label, Color color) {
    return Column(children: [Container(width: 55, height: 55, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 30)), const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))]);
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
            
            if (snapshotPosts.hasError) {
              return Scaffold(
                backgroundColor: Colors.black,
                body: ErrorStateWidget(
                  message: 'Không thể tải bài viết',
                  onRetry: () => setState(() {}),
                ),
              );
            }

            var allPosts = snapshotPosts.data?.docs ?? [];
            var filteredPosts = allPosts.where((post) {
              var data = post.data() as Map<String, dynamic>;
              String recipient = data['recipient'] ?? 'all';
              bool isForMe = recipient == 'all' || recipient == currentUser!.email;
              bool isMine = data['email'] == currentUser!.email;
              bool isFriend = data.containsKey('email') && myFriends.contains(data['email']);
              return (isFriend || isMine) && (isForMe || isMine);
            }).toList();

            if (filteredPosts.isEmpty) {
              return Scaffold(
                backgroundColor: Colors.black,
                body: EmptyState(
                  title: 'Chưa có khoảnh khắc nào',
                  subtitle: 'Hãy tạo bài viết đầu tiên của bạn!',
                  icon: Icons.image_not_supported,
                ),
              );
            }

            int initialIndex = 0;
            if (widget.initialPostId != null) {
              int foundIndex = filteredPosts.indexWhere((doc) => doc.id == widget.initialPostId);
              if (foundIndex != -1) initialIndex = foundIndex;
            }

            return Scaffold(
              backgroundColor: Colors.black,
              resizeToAvoidBottomInset: false, 
              body: Stack(
                children: [
                  // PAGE VIEW
                  PageView.builder(
                    key: ValueKey(filteredPosts.length),
                    controller: PageController(
                      initialPage: _currentIndex >= filteredPosts.length 
                          ? (filteredPosts.isNotEmpty ? filteredPosts.length - 1 : 0) 
                          : (_currentIndex == 0 && widget.initialPostId != null ? initialIndex : _currentIndex)
                    ),
                    scrollDirection: Axis.vertical,
                    physics: const ClampingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() { _currentIndex = index; });
                    },
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      var post = filteredPosts[index];
                      return FeedPostItem(post: post, currentUser: currentUser!);
                    },
                  ),

                  // --- 2. HEADER (ĐÃ CẬP NHẬT LINK) ---
                  Positioned(
                    top: 50, left: 20, right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Nút Profile (Trái) -> Mở ProfileScreen
                        GestureDetector(
                          onTap: () => mounted ? Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())) : null,
                          child: _headerIcon(Icons.person),
                        ),
                        
                        // Dropdown (Giữa)
                        Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(20)), child: const Row(children: [Text("Mọi người", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(width: 5), Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16)])),
                        
                        // Nút Chat (Phải) -> Mở ChatListScreen
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListScreen())),
                          child: _headerIcon(Icons.chat_bubble_outline),
                        ),
                      ],
                    ),
                  ),

                  // 3. BOTTOM BAR
                  Positioned(
                    bottom: 30, left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 32), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GalleryScreen()))),
                        GestureDetector(
                          onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false),
                          child: Container(width: 75, height: 75, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.amber, width: 4), color: Colors.white)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.ios_share, color: Colors.white, size: 30),
                          onPressed: () {
                            int targetIndex = _currentIndex;
                            if (_currentIndex == 0 && widget.initialPostId != null) {
                               int found = filteredPosts.indexWhere((doc) => doc.id == widget.initialPostId);
                               if (found != -1) targetIndex = found;
                            }
                            if (targetIndex >= filteredPosts.length) targetIndex = filteredPosts.length - 1;
                            if (targetIndex >= 0 && targetIndex < filteredPosts.length) _showShareMenu(filteredPosts[targetIndex]);
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _headerIcon(IconData icon) {
    return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey[900], shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 22));
  }
}

// ==========================================
// ITEM BÀI ĐĂNG 
// ==========================================
class FeedPostItem extends StatefulWidget {
  final QueryDocumentSnapshot post;
  final User currentUser;
  const FeedPostItem({super.key, required this.post, required this.currentUser});
  @override State<FeedPostItem> createState() => _FeedPostItemState();
}

class _FeedPostItemState extends State<FeedPostItem> {
  final TextEditingController _replyController = TextEditingController();
  bool _isSending = false;
  final List<Widget> _flyingIcons = []; 

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    var data = widget.post.data() as Map<String, dynamic>;
    String authorUid = data['userId'] ?? "";
    String myUid = widget.currentUser.uid;
    if (authorUid.isEmpty) {
       var userQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: data['email']).get();
       if (userQuery.docs.isNotEmpty) authorUid = userQuery.docs.first.id;
    }
    if (authorUid.isEmpty || authorUid == myUid) {
       setState(() => _isSending = false);
       return;
    }
    String chatId = myUid.compareTo(authorUid) < 0 ? "${myUid}_$authorUid" : "${authorUid}_$myUid";
    try {
      final appContext = context;
      await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add({
        'senderId': myUid, 'text': text, 'replyToImage': data['imageUrl'], 'timestamp': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'lastMessage': "Đã phản hồi ảnh: $text", 'lastTime': FieldValue.serverTimestamp(), 'users': [myUid, authorUid]
      }, SetOptions(merge: true));
      _replyController.clear();
      FocusScope.of(appContext).unfocus(); 
      await SafeContext.showSnackBar(appContext, "Đã gửi tin nhắn!");
    } catch (e) { 
      debugPrint("Lỗi: $e");
      await SafeContext.showErrorSnackBar(context, "Lỗi: $e");
    } 
    finally { if (mounted) setState(() => _isSending = false); }
  }

  void _triggerFlyingIcons(String emoji) {
    for (int i = 0; i < 12; i++) {
      double randomOffset = (Random().nextDouble() * 40) - 20; 
      Widget iconWidget = Positioned(bottom: 180, right: 40 + randomOffset, child: _FlyingIconAnimation(emoji: emoji, onFinished: () {}));
      setState(() { _flyingIcons.add(iconWidget); });
      if (_flyingIcons.length > 50) _flyingIcons.removeAt(0);
    }
  }

  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime d = timestamp.toDate();
    Duration diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return "Vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes}ph";
    if (diff.inHours < 24) return "${diff.inHours}h";
    return "${d.day} thg ${d.month}";
  }

  @override
  Widget build(BuildContext context) {
    var data = widget.post.data() as Map<String, dynamic>;
    String imageUrl = data['imageUrl'];
    if (!imageUrl.startsWith('http')) imageUrl = "https://picsum.photos/seed/${widget.post.id}/800/1000";
    String? caption = data['caption'];

    return Container(
      color: Colors.black, 
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 100), 
              Expanded(
                flex: 6, 
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Stack(
                    children: [
                      Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(30), child: Image.network(imageUrl, fit: BoxFit.cover))),
                      if (caption != null && caption.isNotEmpty)
                        Positioned(
                          bottom: 20, left: 0, right: 0,
                          child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)), child: Text(caption, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600), textAlign: TextAlign.center))),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              
              // THÔNG TIN USER
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('users').where('email', isEqualTo: data['email']).limit(1).get(),
                builder: (context, snapshot) {
                  String? avatarUrl;
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    var userDoc = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                    avatarUrl = userDoc['avatarUrl'];
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 12, backgroundColor: Colors.grey[800],
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null ? Text(data['author']?[0] ?? "A", style: const TextStyle(fontSize: 10, color: Colors.white)) : null,
                      ),
                      const SizedBox(width: 8),
                      Text(data['author'] ?? "Ẩn danh", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(_timeAgo(data['timestamp']), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 15),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(35)),
                child: Row(
                  children: [
                    Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 15), child: TextField(controller: _replyController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: const InputDecoration(hintText: "Gửi tin nhắn...", hintStyle: TextStyle(color: Colors.white54), border: InputBorder.none, isDense: true), onSubmitted: (_) => _sendReply()))),
                    if (_isSending) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2)),
                    _BounceableIcon(emoji: "🔥", onTap: () => _triggerFlyingIcons("🔥")),
                    _BounceableIcon(emoji: "💛", onTap: () => _triggerFlyingIcons("💛")),
                    _BounceableIcon(emoji: "😍", onTap: () => _triggerFlyingIcons("😍")),
                    IconButton(icon: const Icon(Icons.sentiment_satisfied_alt, color: Colors.white54, size: 24), onPressed: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 120), 
            ],
          ),
          IgnorePointer(child: Stack(children: _flyingIcons)),
        ],
      ),
    );
  }
}

class _FlyingIconAnimation extends StatefulWidget {
  final String emoji;
  final VoidCallback onFinished;
  const _FlyingIconAnimation({required this.emoji, required this.onFinished});
  @override State<_FlyingIconAnimation> createState() => _FlyingIconAnimationState();
}
class _FlyingIconAnimationState extends State<_FlyingIconAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnim, _xAnim, _opacityAnim, _scaleAnim;
  final Random _random = Random();
  @override void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _yAnim = Tween<double>(begin: 0, end: -300 - _random.nextDouble() * 200).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _xAnim = Tween<double>(begin: 0, end: (_random.nextDouble() * 100) - 50).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.2).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2, curve: Curves.easeOutBack)));
    _controller.forward().then((_) => widget.onFinished());
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, child) => Transform.translate(offset: Offset(_xAnim.value, _yAnim.value), child: Opacity(opacity: _opacityAnim.value, child: Transform.scale(scale: _scaleAnim.value, child: Text(widget.emoji, style: const TextStyle(fontSize: 28))))));
  }
}
class _BounceableIcon extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;
  const _BounceableIcon({required this.emoji, required this.onTap});
  @override State<_BounceableIcon> createState() => _BounceableIconState();
}
class _BounceableIconState extends State<_BounceableIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200), reverseDuration: const Duration(milliseconds: 150)); _scaleAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return GestureDetector(onTap: () { _controller.reset(); _controller.forward().then((_) => _controller.reverse()); widget.onTap(); }, behavior: HitTestBehavior.translucent, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: ScaleTransition(scale: _scaleAnimation, child: Text(widget.emoji, style: const TextStyle(fontSize: 26)))));
  }
}