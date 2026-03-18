# 🔧 Integration Guide - Hướng Dẫn Tích Hợp

## 📋 Danh Sách Files Cần Cập Nhật

### 1. **feed_screen.dart** - Thêm Reactions & Comments

Thêm imports:
```dart
import 'reaction_system.dart';
import 'comments_system.dart';
import 'saved_posts_system.dart';
```

Thêm vào FeedPostItem widget (sau caption):
```dart
// Reactions Display
ReactionDisplay(postId: post.id, reactions: post['reactions'] ?? {}),

// Buttons Row
Row(
  mainAxisAlignment: MainAxisAlignment.spaceAround,
  children: [
    // Like/Reaction button
    GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.grey[900],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => ReactionPicker(
            postId: post.id,
            onClose: () => setState(() {}),
          ),
        );
      },
      child: Column(
        children: [
          const Icon(Icons.favorite_outline, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          const Text('Thích', style: TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    ),
    
    // Comment button
    GestureDetector(
      onTap: () {
        _showCommentDialog(context, post.id);
      },
      child: Column(
        children: [
          const Icon(Icons.message_outlined, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          const Text('Bình luận', style: TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    ),
    
    // Save button
    FutureBuilder<bool>(
      future: SavedPostsSystem(userId: currentUser!.uid)
        .isPostSaved(post.id),
      builder: (context, snapshot) {
        final isSaved = snapshot.data ?? false;
        return GestureDetector(
          onTap: () async {
            if (isSaved) {
              await SavedPostsSystem(userId: currentUser!.uid)
                .unsavePost(post.id);
            } else {
              await SavedPostsSystem(userId: currentUser!.uid)
                .savePost(post.id);
            }
            setState(() {});
          },
          child: Column(
            children: [
              Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_outline,
                color: isSaved ? Colors.amber : Colors.white,
                size: 22,
              ),
              const SizedBox(height: 4),
              const Text('Lưu', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        );
      },
    ),
    
    // Share button
    GestureDetector(
      onTap: () => _showShareMenu(post),
      child: Column(
        children: [
          const Icon(Icons.share, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          const Text('Chia sẻ', style: TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    ),
  ],
),
```

Thêm method:
```dart
void _showCommentDialog(BuildContext context, String postId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('Bình luận', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .orderBy('timestamp', descending: true)
            .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator(color: Colors.amber);
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 300,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) => CommentWidget(
                      comment: snapshot.data!.docs[index],
                      postId: postId,
                      currentUser: currentUser!,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng', style: TextStyle(color: Colors.amber)),
        ),
      ],
    ),
  );
}
```

---

### 2. **chat_detail_screen.dart** - Thêm Chat Enhancements

Thêm imports:
```dart
import 'chat_enhancements.dart';
import 'in_app_notifications.dart';
```

Thêm trong message list:
```dart
// Typing indicator
TypingIndicator(
  chatId: chatId,
  currentUserId: currentUser!.uid,
),

// Messages với read receipts
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
    .collection('chats')
    .doc(chatId)
    .collection('messages')
    .orderBy('timestamp', descending: true)
    .snapshots(),
  builder: (context, snapshot) {
    return ListView.builder(
      itemCount: snapshot.data?.docs.length ?? 0,
      itemBuilder: (context, index) => MessageWithReadReceipts(
        message: snapshot.data!.docs[index],
        friendEmails: friendEmails,
      ),
    );
  },
)
```

Thay thế input field:
```dart
// Thay cái input cũ
EnhancedChatInput(
  chatId: chatId,
  userId: currentUser!.uid,
  onSendMessage: (message) async {
    await FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .add({
        'userId': currentUser!.uid,
        'userName': currentUser!.displayName,
        'content': message,
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [],
      });
  },
)
```

---

### 3. **home_screen.dart** - Thêm Stories

Thêm imports:
```dart
import 'stories_system.dart';
```

Thêm vào top của feed:
```dart
// Horizontal scroll của stories
Container(
  height: 120,
  margin: const EdgeInsets.all(12),
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: userFriends.length + 1,
    itemBuilder: (context, index) {
      if (index == 0) {
        return StoryCreator(
          onStoryCreated: () => setState(() {}),
        );
      }
      return const SizedBox(width: 8);
    },
  ),
),
```

---

### 4. **profile_screen.dart** - Thêm Block Option

Thêm imports:
```dart
import 'blocking_system.dart';
```

Thêm button trong profile menu:
```dart
// Block user button
if (userId != currentUser!.uid)
  ListTile(
    leading: const Icon(Icons.block, color: Colors.red),
    title: const Text('Chặn người dùng', style: TextStyle(color: Colors.white)),
    onTap: () {
      showBlockDialog(context, userId, currentUser!.uid);
    },
  ),
```

---

### 5. **main_layout.dart** - Drawer Navigation ✅ (Đã done)

Drawer đã được thêm với:
- 🔍 Explore Screen
- 📚 Saved Posts Screen

---

### 6. **settings_screen.dart** - Blocked Users Link ✅ (Đã done)

Đã thêm trong phần TÀI KHOẢN:
- 🚫 Người dùng bị chặn

---

## 🎯 Priority Integration Checklist

**High Priority (Nên làm ngay):**
- [ ] Reactions + Comments trong feed_screen.dart
- [ ] Chat Enhancements trong chat_detail_screen.dart
- [ ] Stories trong home_screen.dart

**Medium Priority (Có thể làm sau):**
- [ ] Notifications badge trong AppBar
- [ ] Push notifications triggers
- [ ] Block option trong profile_screen.dart

**Low Priority (Optional):**
- [ ] Advanced analytics
- [ ] Animation enhancements
- [ ] Performance optimizations

---

## 📝 Database Schema Updates

Cần cập nhật Firestore fields:

### Posts Document:
```json
{
  "reactions": {
    "love": ["uid1", "uid2"],
    "laugh": ["uid3"]
  }
}
```

### Users Collection:
```json
{
  "friends": ["email1@gmail.com", "email2@gmail.com"],
}
```

### Realtime Updates:
- ✅ Firestore triggers sẽ tự động cập nhật
- ✅ StreamBuilder sẽ listen thay đổi

---

## 🧪 Testing Checklist

### Test Reactions:
- [ ] Click reaction picker
- [ ] View reaction list
- [ ] Add/Remove reaction
- [ ] See reaction count update

### Test Comments:
- [ ] Add comment
- [ ] Reply to comment
- [ ] Like comment
- [ ] Delete comment

### Test Chat:
- [ ] See typing indicator
- [ ] Check read receipts
- [ ] Message sent successfully

### Test Stories:
- [ ] Create story
- [ ] View story
- [ ] See viewer list
- [ ] Auto-delete after 24h

### Test Saved Posts:
- [ ] Save post
- [ ] View saved posts
- [ ] Unsave post

### Test Blocking:
- [ ] Block user
- [ ] See blocked list
- [ ] Unblock user

---

## 🐛 Common Issues & Fixes

### Q: "Undefined name 'context'"
A: Đảm bảo bạn pass `context` từ parent widget

### Q: "Firebase snapshot is empty"
A: Check định nghĩa collection path, uid, v.v.

### Q: "Typing indicator không update"
A: Đảm bảo `ChatEnhancements.setTypingStatus(false)` được gọi khi finish typing

### Q: "Reactions không lưu""
A: Kiểm tra rules Firestore:
```
match /posts/{document=**} {
  allow read;
  allow write: if request.auth != null;
}
```

---

## ✨ Tips & Tricks

### 1. Debounce Typing Indicator
```dart
late Timer _typingTimer;

void _onTyping() {
  _typingTimer?.cancel();
  setTyping(true);
  
  _typingTimer = Timer(Duration(seconds: 3), () {
    setTyping(false);
  });
}
```

### 2. Batch Mark Notifications
```dart
// Mark all notifications as read
await NotificationsSystem(userId: userId).markAllAsRead();
```

### 3. Optimized Story Cleanup
```dart
// Run nightly cleanup
SchedulerBinding.instance.addPostFrameCallback((_) {
  StoriesSystem.deleteExpiredStories();
});
```

---

## 📞 Support

Nếu gặp vấn đề:
1. Check FEATURES.md cho API details
2. Xem example code trong files
3. Kiểm tra Firestore rules
4. Verify imports và dependencies

---

**Happy Coding! 🚀**
