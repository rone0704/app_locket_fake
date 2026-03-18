import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'ui_widgets.dart';
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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Đăng xuất?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Bạn có chắc chắn muốn thoát tài khoản không?", style: TextStyle(color: Colors.white70)),
        actions: [
          // Nút Hủy
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.white54)),
          ),
          // Nút Đăng xuất
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Đóng hộp thoại trước
              await FirebaseAuth.instance.signOut(); // Thực hiện đăng xuất
              
              if (mounted) {
                // Quay về màn hình Login (Màn hình đầu tiên)
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text("Đăng xuất", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- HÀM ĐỔI TÊN ---
  void _editName(String currentName) {
    TextEditingController nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Đổi tên hiển thị", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Nhập tên mới...",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Hủy", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
                'displayName': nameController.text.trim()
              });
            },
            child: const Text("Lưu", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
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
      maxWidth: 500,    // Resize
    ); 
    
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      // 2. Đọc dữ liệu ảnh dưới dạng Bytes (Fix lỗi Platform Web)
      Uint8List fileBytes = await image.readAsBytes();

      // 3. Upload lên Firebase Storage
      final ref = FirebaseStorage.instance.ref().child('user_avatars/${currentUser!.uid}.jpg');
      
      // Dùng putData cho an toàn trên mọi nền tảng
      await ref.putData(fileBytes, SettableMetadata(contentType: 'image/jpeg'));
      
      // 4. Lấy link
      final imageUrl = await ref.getDownloadURL();

      // 5. Cập nhật Firestore
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'avatarUrl': imageUrl
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật ảnh đại diện!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
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
        content: Text("Bạn có chắc muốn xóa $friendEmail khỏi danh sách?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Hủy", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({'friends': FieldValue.arrayRemove([friendEmail])});
              
              var friendQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: friendEmail).get();
              if (friendQuery.docs.isNotEmpty) {
                 await FirebaseFirestore.instance.collection('users').doc(friendQuery.docs.first.id).update({'friends': FieldValue.arrayRemove([currentUser!.email])});
              }
              if (mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        title: 'Hồ sơ của tôi',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _signOut,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>?;
          String email = data?['email'] ?? currentUser!.email ?? '';
          String displayName = data?['displayName'] ?? email.split('@')[0];
          String? avatarUrl = data?['avatarUrl'];
          List friends = data != null && data.containsKey('friends') ? data['friends'] : [];

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header Card with Avatar
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
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar with Camera Icon
                        Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.amber,
                                border: Border.all(color: Colors.amber, width: 3),
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
                        // Display Name
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
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.amber),
                              onPressed: () => _editName(displayName),
                            ),
                          ],
                        ),
                        // Email
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatColumn('Bạn bè', friends.length.toString()),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey[700],
                            ),
                            _buildStatColumn('Bài viết', '0'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Friends Section
                SectionHeader(
                  title: 'Bạn bè của tôi (${friends.length})',
                ),

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
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.person_remove,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _removeFriend(friendEmail),
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
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}