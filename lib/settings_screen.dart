import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_screen.dart'; // <--- Gọi file màn hình thông báo vào đây

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Cài đặt", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
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
                  child: const Icon(Icons.person, size: 50, color: Colors.white54),
                ),
                const SizedBox(height: 16),
                const Text("Tên Của Bạn", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const Text("@username", style: TextStyle(color: Colors.white54, fontSize: 16)),
              ],
            ),
          ),
          
          const SizedBox(height: 40),

          // --- DANH SÁCH MENU TÀI KHOẢN ---
          const Text("TÀI KHOẢN", style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          // 1. Nút Tìm Bạn Bè (Tạm thời để thông báo)
          _buildMenuTile(
            icon: Icons.person_add_rounded, 
            title: "Tìm bạn bè", 
            color: Colors.white,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng Tìm bạn bè sắp ra mắt!")));
            }
          ),
          
          // 2. Nút Thông Báo (Bấm vào sẽ trượt sang trang Thông Báo)
          _buildMenuTile(
            icon: Icons.notifications_rounded, 
            title: "Thông báo", 
            color: Colors.white,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            }
          ),
          
          // 3. Nút Đăng Xuất
          _buildMenuTile(
            icon: Icons.logout_rounded, 
            title: "Đăng xuất", 
            color: Colors.redAccent, 
            isLast: true,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            }
          ),
          
        ],
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