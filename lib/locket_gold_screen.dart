import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocketGoldScreen extends StatelessWidget {
  const LocketGoldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.withValues(alpha: 0.3), Colors.amber.withValues(alpha: 0.1)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.withValues(alpha: 0.2),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Locket GOLD",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Mở khóa trải nghiệm Premium",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- FEATURES LIST ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tính năng Premium",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.photo_library_rounded,
                    title: "Lưu trữ ảnh không giới hạn",
                    description: "Chọa độ bản trong thư viện ảnh của bạn",
                  ),
                  _buildFeatureItem(
                    icon: Icons.videocam_rounded,
                    title: "Chia sẻ video",
                    description: "Tạo và chia sẻ video đặc biệt",
                  ),
                  _buildFeatureItem(
                    icon: Icons.image_rounded,
                    title: "Không giới hạn lưu trữ",
                    description: "Không cần lo lắng về dung lượng",
                  ),
                  _buildFeatureItem(
                    icon: Icons.palette_rounded,
                    title: "Bộ sưu tập tùy biến",
                    description: "Tùy chỉnh giao diện Locket của bạn",
                  ),
                  _buildFeatureItem(
                    icon: Icons.auto_awesome_rounded,
                    title: "Hiệu ứng đặc biệt",
                    description: "Thêm các hiệu ứng độc quyền",
                  ),
                  _buildFeatureItem(
                    icon: Icons.lock_outline_rounded,
                    title: "Bộ khóa riêng tư",
                    description: "Bảo vệ ảnh của bạn với khóa",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- PRICING ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.amber, width: 1.5),
              ),
              child: Column(
                children: [
                  const Text(
                    "38,000 VND",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const Text(
                    "mỗi tháng",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Có thể hủy bất kỳ lúc nào",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- SUBSCRIBE BUTTON ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    _showSubscribeDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Đăng ký ngay",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- FREE TRIAL ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Dùng thử miễn phí 7 ngày đầu",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscribeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Bắt đầu dùng thử",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Bạn sẽ có 7 ngày dùng thử miễn phí. Sau đó sẽ tính phí 38,000 VND/tháng.\n\nCó thể hủy bất kỳ lúc nào!",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                // Tính ngày hết hạn (hiện tại + 7 ngày)
                DateTime expiryDate = DateTime.now().add(const Duration(days: 7));
                
                // Lưu vào Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .update({
                  'isGoldMember': true,
                  'goldMemberExpiryDate': expiryDate,
                  'goldMemberStartedAt': DateTime.now(),
                });

                Navigator.pop(context);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("✨ Chúc mừng! Bạn đã nâng cấp lên Locket Gold"),
                      backgroundColor: Colors.amber,
                      duration: const Duration(seconds: 3),
                      action: SnackBarAction(
                        label: "Đóng",
                        textColor: Colors.black,
                        onPressed: () {},
                      ),
                    ),
                  );
                  
                  // Đóng màn hình sau 2 giây
                  Future.delayed(const Duration(seconds: 2), () {
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  });
                }
              }
            },
            child: const Text(
              "Dùng thử miễn phí",
              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
