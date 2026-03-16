import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- Thêm thư viện này
import 'notification_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Cài đặt", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      // Dùng StreamBuilder để đọc dữ liệu từ Firestore giống hệt ProfileScreen
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          // Nếu đang tải dữ liệu thì hiện vòng xoay
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          // Lấy dữ liệu từ kho ra
          var data = snapshot.data!.data() as Map<String, dynamic>?;
          String email = data?['email'] ?? currentUser.email ?? "";
          String displayName = data?['displayName'] ?? email.split('@')[0];
          String? avatarUrl = data?['avatarUrl']; // Lấy link ảnh nếu có
          String username = "@${email.split('@')[0]}";
          String avatarChar = displayName.isNotEmpty ? displayName[0].toUpperCase() : "A";

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              const SizedBox(height: 20),
              
              // --- AVATAR & THÔNG TIN ---
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null 
                          ? Text(avatarChar, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white))
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(username, style: const TextStyle(color: Colors.white54, fontSize: 16)),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),

              // --- KHU VỰC LOCKET GOLD ---
              _buildMenuTile(
                icon: Icons.star_rounded, 
                title: "Đăng ký Locket Gold", 
                color: Colors.amber, 
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng Locket Gold đang phát triển!")));
                }
              ),

              const SizedBox(height: 20),
              const Text("TÀI KHOẢN", style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // --- MENU TÀI KHOẢN ---
              _buildMenuTile(
                icon: Icons.edit_rounded, 
                title: "Sửa tên, email", 
                color: Colors.white,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chức năng sửa thông tin sắp ra mắt!")));
                }
              ),
              _buildMenuTile(
                icon: Icons.notifications_rounded, 
                title: "Thông báo", 
                color: Colors.white,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                }
              ),

              const SizedBox(height: 20),
              const Text("HỖ TRỢ & PHẢN HỒI", style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // --- MENU HỖ TRỢ ---
              _buildMenuTile(
                icon: Icons.help_outline_rounded, 
                title: "Hỗ trợ", 
                color: Colors.white,
                onTap: () {}
              ),
              _buildMenuTile(
                icon: Icons.report_problem_rounded, 
                title: "Báo cáo sự cố", 
                color: Colors.orangeAccent,
                onTap: () {}
              ),
              _buildMenuTile(
                icon: Icons.lightbulb_outline_rounded, 
                title: "Gửi đề xuất", 
                color: Colors.blueAccent,
                onTap: () {}
              ),

              const SizedBox(height: 20),

              // --- NÚT ĐĂNG XUẤT ---
              _buildMenuTile(
                icon: Icons.logout_rounded, 
                title: "Đăng xuất", 
                color: Colors.redAccent, 
                isLast: true,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                }
              ),
              
              const SizedBox(height: 40), 
            ],
          );
        },
      ),
    );
  }

  // Khung thiết kế của các nút menu
  Widget _buildMenuTile({required IconData icon, required String title, required Color color, bool isLast = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontSize: 16)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }
}