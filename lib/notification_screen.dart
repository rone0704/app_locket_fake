import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Thông báo", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
      ),
      // Dùng ListView để có thể cuộn lên xuống nếu thông báo quá dài
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text("Hôm nay", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Thông báo 1: Có người thả tim ảnh
          _buildNotificationItem(
            name: "Bảo",
            action: "đã thả ❤️ vào ảnh của bạn.",
            time: "5 phút trước",
            avatarColor: Colors.blueAccent,
            hasImage: true, // Hiển thị cái ảnh nhỏ bên phải
          ),
          
          // Thông báo 2: Có người đăng ảnh mới
          _buildNotificationItem(
            name: "Hải Yến",
            action: "đã thêm một ảnh mới.",
            time: "1 giờ trước",
            avatarColor: Colors.pinkAccent,
            hasImage: false,
          ),
          
          const SizedBox(height: 20),
          const Text("Tuần này", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Thông báo 3: Lời mời kết bạn
          _buildFriendRequestItem(
            name: "Nam Tước",
            time: "3 ngày trước",
            avatarColor: Colors.green,
          ),
        ],
      ),
    );
  }

  // --- HÀM TẠO KHUNG THÔNG BÁO BÌNH THƯỜNG ---
  Widget _buildNotificationItem({required String name, required String action, required String time, required Color avatarColor, required bool hasImage}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          // Avatar (Lấy chữ cái đầu của tên)
          CircleAvatar(
            radius: 24, 
            backgroundColor: avatarColor, 
            child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
          ),
          const SizedBox(width: 12),
          
          // Nội dung thông báo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    children: [
                      TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: " "),
                      TextSpan(text: action),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          
          // Nếu thông báo về ảnh thì hiện cái ảnh thu nhỏ ở góc phải
          if (hasImage)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(
                  image: NetworkImage("https://images.unsplash.com/photo-1517849845537-4d257902454a?q=80&w=200&auto=format&fit=crop"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- HÀM TẠO KHUNG THÔNG BÁO KẾT BẠN (CÓ NÚT CHẤP NHẬN) ---
  Widget _buildFriendRequestItem({required String name, required String time, required Color avatarColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24, 
            backgroundColor: avatarColor, 
            child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    children: [
                      TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: " đã gửi cho bạn một lời mời kết bạn."),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          
          // Nút Chấp nhận kết bạn
          GestureDetector(
            onTap: () {
              // Bấm vào đây sau này xử lý add friend
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
              child: const Text("Chấp nhận", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}