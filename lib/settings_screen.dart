import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_screen.dart';
import 'locket_gold_screen.dart';
import 'blocking_system.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  
  // --- HÀM CHỈNH SỬA TÊN ---
  void _editName(BuildContext context, String currentName, String uid) {
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'displayName': nameController.text.trim()
                });
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text("Lưu", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- HÀM ĐĂNG XUẤT ---
  void _signOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Đăng xuất?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Bạn có chắc muốn thoát tài khoản không?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
            child: const Text("Đăng xuất", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- HÀM QUẢN LÝ LOCKET GOLD ---
  void _showGoldMemberMenu(BuildContext context, bool isExpired, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Locket Gold",
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isExpired
              ? "Gói Gold của bạn đã hết hạn. Hãy gia hạn để tiếp tục sử dụng các tính năng premium!"
              : "Bạn đang sử dụng Locket Gold. Hãy gia hạn trước khi hết hạn!",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Xóa Gold membership
              await FirebaseFirestore.instance.collection('users').doc(uid).update({
                'isGoldMember': false,
                'goldMemberExpiryDate': null,
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("❌ Đã hủy Locket Gold"),
                  backgroundColor: Colors.redAccent,
                ),
              );
              }
            },
            child: const Text("Hủy Gold", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          if (!isExpired)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LocketGoldScreen()));
              },
              child: const Text("Gia hạn", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>?;
          String email = data?['email'] ?? currentUser.email ?? "";
          String displayName = data?['displayName'] ?? email.split('@')[0];
          String? avatarUrl = data?['avatarUrl'];
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

              // --- LOCKET GOLD SECTION ---
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  
                  var userData = snapshot.data!.data() as Map<String, dynamic>?;
                  bool isGoldMember = userData?['isGoldMember'] ?? false;
                  DateTime? expiryDate = userData?['goldMemberExpiryDate']?.toDate();
                  
                  if (isGoldMember && expiryDate != null) {
                    String expiryDateFormatted = "${expiryDate.day}/${expiryDate.month}/${expiryDate.year}";
                    bool isExpired = DateTime.now().isAfter(expiryDate);
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: isExpired ? Colors.red.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isExpired ? Colors.redAccent : Colors.amber,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isExpired ? Icons.star_outline_rounded : Icons.star_rounded,
                          color: isExpired ? Colors.redAccent : Colors.amber,
                        ),
                        title: Text(
                          isExpired ? "Locket Gold đã hết hạn" : "✨ Locket Gold Active",
                          style: TextStyle(
                            color: isExpired ? Colors.redAccent : Colors.amber,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          isExpired ? "Hết hạn: $expiryDateFormatted" : "Hết hạn: $expiryDateFormatted",
                          style: TextStyle(color: isExpired ? Colors.red[300] : Colors.amberAccent, fontSize: 12),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: isExpired ? Colors.redAccent : Colors.amber,
                        ),
                        onTap: () {
                          _showGoldMemberMenu(context, isExpired, currentUser.uid);
                        }
                      ),
                    );
                  }
                  
                  // Chưa subscribe Gold
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.amber, width: 1.5),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.star_rounded, color: Colors.amber),
                      title: const Text("Đăng ký Locket Gold", style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                      subtitle: const Text("Mở khóa tính năng cao cấp", style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.amber),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LocketGoldScreen()));
                      }
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),
              const Text("TÀI KHOẢN", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 12),

              // --- SỬA TÊN / EMAIL ---
              _buildMenuTile(
                icon: Icons.edit_rounded, 
                title: "Sửa tên, email", 
                color: Colors.white,
                onTap: () => _editName(context, displayName, currentUser.uid)
              ),

              // --- THÔNG BÁO ---
              _buildMenuTile(
                icon: Icons.notifications_rounded, 
                title: "Thông báo", 
                color: Colors.white,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                }
              ),

              // --- NGƯỜI DÙNG BỊ CHẶN ---
              _buildMenuTile(
                icon: Icons.block, 
                title: "Người dùng bị chặn", 
                color: Colors.redAccent,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BlockedUsersScreen()));
                }
              ),

              const SizedBox(height: 25),
              const Text("HỖ TRỢ & PHẢN HỒI", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 12),

              // --- HỖ TRỢ ---
              _buildMenuTile(
                icon: Icons.help_outline_rounded, 
                title: "Hỗ trợ", 
                color: Colors.white,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Chức năng hỗ trợ đang phát triển!"))
                  );
                }
              ),

              // --- BÁO CÁO SỰ CỐ ---
              _buildMenuTile(
                icon: Icons.report_problem_rounded, 
                title: "Báo cáo sự cố", 
                color: Colors.orangeAccent,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cảm ơn bạn đã báo cáo!"))
                  );
                }
              ),

              // --- GỬI ĐỀ XUẤT ---
              _buildMenuTile(
                icon: Icons.lightbulb_outline_rounded, 
                title: "Gửi đề xuất", 
                color: Colors.blueAccent,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cảm ơn bạn đã gửi đề xuất!"))
                  );
                }
              ),

              const SizedBox(height: 25),

              // --- ĐĂNG XUẤT ---
              _buildMenuTile(
                icon: Icons.logout_rounded, 
                title: "Đăng xuất", 
                color: Colors.redAccent,
                onTap: () => _signOut(context)
              ),
              
              const SizedBox(height: 40), 
            ],
          );
        },
      ),
    );
  }

  // --- HÀM TẠO MENU TILE ---
  Widget _buildMenuTile({
    required IconData icon, 
    required String title, 
    required Color color, 
    VoidCallback? onTap
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
    );
  }
}