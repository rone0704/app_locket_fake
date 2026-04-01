import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'ui_widgets.dart';
import 'image_url_utils.dart';
import 'ui_button_tokens.dart';
import 'main_layout.dart';
import 'app_navigator.dart';
import 'welcome_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isUploading = false;

  // --- HÀM ĐĂNG XUẤT (ĐÃ CẬP NHẬT: CÓ XÁC NHẬN) ---
  void _signOut() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Đăng xuất?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Bạn có chắc chắn muốn thoát tài khoản không?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          // Nút Hủy
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy", style: TextStyle(color: Colors.white54)),
          ),
          // Nút Đăng xuất
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                appNavigatorKey.currentState?.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => WelcomeScreen(
                      onFinished: () {
                        appNavigatorKey.currentState?.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                  (route) => false,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dang xuat that bai: $e'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              "Đăng xuất",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HÀM ĐỔI TÊN ---
  void _editName(String currentName) {
    TextEditingController nameController = TextEditingController(
      text: currentName,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Đổi tên hiển thị",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          enableInteractiveSelection: false,
          cursorColor: Colors.amber,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Nhập tên mới...",
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.amber, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser!.uid)
                  .update({'displayName': nameController.text.trim()});
            },
            child: const Text(
              "Lưu",
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HÀM THAY ĐỔI AVATAR (CHUẨN WEB & MOBILE) ---
  Future<void> _changeAvatar() async {
    final ImagePicker picker = ImagePicker();

    // 1. Chọn ảnh
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Giảm dung lượng
      maxWidth: 500, // Resize
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      // 2. Đọc dữ liệu ảnh dưới dạng Bytes (Fix lỗi Platform Web)
      Uint8List fileBytes = await image.readAsBytes();

      // 3. Upload lên Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(
        'user_avatars/${currentUser!.uid}.jpg',
      );

      // Dùng putData cho an toàn trên mọi nền tảng
      await ref.putData(fileBytes, SettableMetadata(contentType: 'image/jpeg'));

      // 4. Lấy link
      final imageUrl = await ref.getDownloadURL();

      // 5. Cập nhật Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'avatarUrl': imageUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã cập nhật ảnh đại diện!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // --- HÀM XÓA BẠN ---
  void _removeFriend(String friendEmail) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Xóa bạn bè?", style: TextStyle(color: Colors.white)),
        content: Text(
          "Bạn có chắc muốn xóa $friendEmail khỏi danh sách?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser!.uid)
                  .update({
                    'friends': FieldValue.arrayRemove([friendEmail]),
                  });

              var friendQuery = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: friendEmail)
                  .get();
              if (friendQuery.docs.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(friendQuery.docs.first.id)
                    .update({
                      'friends': FieldValue.arrayRemove([currentUser!.email]),
                    });
              }
              if (mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text(
              "Xóa",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // ĐÃ SỬA: Đổi sang AppBar tiêu chuẩn để làm nổi bật nút Back màu Trắng
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: TokenIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            size: 38,
            iconColor: Colors.white, // NÚT TRẮNG NỔI BẦN BẬT
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Hồ sơ của tôi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TokenIconButton(
              icon: Icons.logout,
              size: 38,
              iconColor: Colors.redAccent,
              onTap: _signOut,
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Khong the tai ho so. Vui long thu lai',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>?;
          String email = data?['email'] ?? currentUser!.email ?? '';
          String displayName = data?['displayName'] ?? email.split('@')[0];
          String? avatarUrl = data?['avatarUrl'];
          List friends = data != null && data.containsKey('friends')
              ? data['friends']
              : [];

          return SingleChildScrollView(
            child: Column(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('userId', isEqualTo: currentUser!.uid)
                      .snapshots(),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Text(
                          'Khong the tai bai viet cua ban',
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final myPosts = postSnapshot.data?.docs ?? const [];

                    return Column(
                      children: [
                        GestureDetector(
                          onTap: _changeAvatar,
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey[900]!, Colors.grey[800]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.amber,
                                        border: Border.all(
                                          color: Colors.amber,
                                          width: 3,
                                        ),
                                        image: avatarUrl != null
                                            ? DecorationImage(
                                                image: NetworkImage(avatarUrl),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: avatarUrl == null
                                          ? Center(
                                              child: Text(
                                                displayName[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 18,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    if (_isUploading)
                                      const Positioned.fill(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TokenIconButton(
                                      icon: Icons.edit,
                                      size: 34,
                                      iconColor: Colors.amber,
                                      onTap: () => _editName(displayName),
                                    ),
                                  ],
                                ),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatColumn(
                                      'Bạn bè',
                                      friends.length.toString(),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.grey[700],
                                    ),
                                    _buildStatColumn(
                                      'Bài viết',
                                      myPosts.length.toString(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _editName(displayName),
                                        icon: const Icon(Icons.badge_rounded),
                                        label: const Text('Sửa hồ sơ nhanh'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.16,
                                            ),
                                          ),
                                          backgroundColor: Colors.black
                                              .withValues(alpha: 0.25),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _changeAvatar,
                                        icon: const Icon(Icons.photo_camera),
                                        label: const Text('Đổi avatar'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.16,
                                            ),
                                          ),
                                          backgroundColor: Colors.black
                                              .withValues(alpha: 0.25),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SectionHeader(title: 'Khoảnh khắc của tôi'),
                        if (myPosts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: EmptyState(
                              icon: Icons.photo_library_outlined,
                              title: 'Chưa có ảnh nào',
                              subtitle:
                                  'Hãy đăng ảnh đầu tiên để profile trông chuyên nghiệp hơn.',
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                            itemCount: myPosts.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.78,
                                ),
                            itemBuilder: (context, index) {
                              final doc = myPosts[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final imageUrl =
                                  data['imageUrl']?.toString() ?? '';
                              final imageBytes = decodeDataImageUrl(imageUrl);
                              final hasImage = isRenderableImageUrl(imageUrl);

                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MainLayout(
                                        initialTab: 1, // Mở tab Home
                                        initialHomeVerticalPage:
                                            1, // Cuộn xuống Feed
                                        initialPostId: doc.id, // Truyền ID ảnh
                                      ),
                                    ),
                                    (route) => false,
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: hasImage
                                      ? (imageBytes != null
                                            ? Image.memory(
                                                imageBytes,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                              ))
                                      : Container(
                                          color: Colors.grey[900],
                                          child: const Icon(
                                            Icons.broken_image_outlined,
                                            color: Colors.white38,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),

                // Friends Section
                SectionHeader(title: 'Bạn bè của tôi (${friends.length})'),

                if (friends.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: EmptyState(
                      icon: Icons.people_outline,
                      title: 'Chưa có bạn bè nào',
                      subtitle: 'Kết nối với những người khác để bắt đầu',
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      String friendEmail = friends[index];
                      String friendName = friendEmail.split('@')[0];

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.amber,
                            child: Text(
                              friendName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            friendName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            friendEmail,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          trailing: TokenIconButton(
                            icon: Icons.person_remove,
                            size: 34,
                            iconColor: Colors.redAccent,
                            onTap: () => _removeFriend(friendEmail),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}