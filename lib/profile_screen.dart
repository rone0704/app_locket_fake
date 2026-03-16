import 'package:flutter/foundation.dart'; // Để dùng Uint8List (cho Web)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
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
      builder: (context) => AlertDialog(
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
                  'displayName': nameController.text.trim()
                });
                Navigator.pop(context);
              }
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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Xóa bạn bè?", style: TextStyle(color: Colors.white)),
        content: Text("Bạn có chắc muốn xóa $friendEmail khỏi danh sách?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({'friends': FieldValue.arrayRemove([friendEmail])});
              
              var friendQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: friendEmail).get();
              if (friendQuery.docs.isNotEmpty) {
                 await FirebaseFirestore.instance.collection('users').doc(friendQuery.docs.first.id).update({'friends': FieldValue.arrayRemove([currentUser!.email])});
              }
              Navigator.pop(context);
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("Hồ sơ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // Nút Đăng xuất (Gọi hàm _signOut có xác nhận)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent), 
            onPressed: _signOut 
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
          
          var data = snapshot.data!.data() as Map<String, dynamic>?;
          String email = data?['email'] ?? currentUser!.email ?? "";
          String displayName = data?['displayName'] ?? email.split('@')[0];
          String? avatarUrl = data?['avatarUrl']; 
          List friends = data != null && data.containsKey('friends') ? data['friends'] : [];
          String avatarChar = displayName.isNotEmpty ? displayName[0].toUpperCase() : "A";

          return Column(
            children: [
              const SizedBox(height: 30),
              
              // AVATAR
              Center(
                child: GestureDetector(
                  onTap: _changeAvatar, 
                  child: Stack(
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[800],
                          border: Border.all(color: Colors.amber, width: 2),
                          image: avatarUrl != null 
                              ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                              : null
                        ),
                        child: avatarUrl == null 
                            ? Center(child: Text(avatarChar, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)))
                            : null,
                      ),
                      
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                        ),
                      ),
                      
                      if (_isUploading)
                        const Positioned.fill(child: CircularProgressIndicator(color: Colors.amber)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // TÊN
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.edit, color: Colors.white54, size: 18), onPressed: () => _editName(displayName))
                ],
              ),
              Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),

              const SizedBox(height: 30),
              Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), color: Colors.grey[900], child: Text("${friends.length} Bạn bè", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
              
              Expanded(
                child: friends.isEmpty
                    ? const Center(child: Text("Chưa có bạn bè nào", style: TextStyle(color: Colors.white24)))
                    : ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          String friendEmail = friends[index];
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.grey[800], child: Text(friendEmail[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
                            title: Text(friendEmail.split('@')[0], style: const TextStyle(color: Colors.white)),
                            subtitle: Text(friendEmail, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            trailing: IconButton(icon: const Icon(Icons.person_remove, color: Colors.redAccent), onPressed: () => _removeFriend(friendEmail)),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}