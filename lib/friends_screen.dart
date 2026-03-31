import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'search_screen.dart'; // Để chuyển sang màn hình tìm kiếm
import 'ui_widgets.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  // --- HÀM CHẤP NHẬN KẾT BẠN ---
  Future<void> _acceptRequest(String senderEmail) async {
    try {
      String? senderUid;
      var senderQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: senderEmail)
          .limit(1)
          .get();
      if (senderQuery.docs.isNotEmpty) {
        senderUid = senderQuery.docs.first.id;
      }

      // 1. Cập nhật phía MÌNH
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
            'friends': FieldValue.arrayUnion([senderEmail]),
            if (senderUid != null)
              'friendUids': FieldValue.arrayUnion([senderUid]),
            'friendRequests': FieldValue.arrayRemove([senderEmail]),
          });

      // 2. Cập nhật phía HỌ
      if (senderUid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(senderUid)
            .update({
              'friends': FieldValue.arrayUnion([currentUser!.email]),
              'friendUids': FieldValue.arrayUnion([currentUser!.uid]),
            });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đã kết bạn với $senderEmail")));
    } catch (e) {
      debugPrint('$e');
    }
  }

  // --- HÀM TỪ CHỐI / XÓA LỜI MỜI ---
  Future<void> _deleteRequest(String senderEmail) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .update({
          'friendRequests': FieldValue.arrayRemove([senderEmail]),
        });
  }

  // --- HÀM XÓA BẠN BÈ (NÚT X) ---
  void _removeFriend(String friendEmail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Hủy kết bạn?",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Bạn có chắc muốn xóa $friendEmail?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              String? friendUid;
              var friendQuery = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: friendEmail)
                  .limit(1)
                  .get();
              if (friendQuery.docs.isNotEmpty) {
                friendUid = friendQuery.docs.first.id;
              }

              // Xóa mình
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser!.uid)
                  .update({
                    'friends': FieldValue.arrayRemove([friendEmail]),
                    if (friendUid != null)
                      'friendUids': FieldValue.arrayRemove([friendUid]),
                  });

              // Xóa họ
              if (friendUid != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(friendUid)
                    .update({
                      'friends': FieldValue.arrayRemove([currentUser!.email]),
                      'friendUids': FieldValue.arrayRemove([currentUser!.uid]),
                    });
              }
              if (mounted) {
                Navigator.pop(context);
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
      backgroundColor: const Color(
        0xFF1C1C1E,
      ), // Màu nền xám đen chuẩn iOS dark mode
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(
              child: Text("Lỗi dữ liệu", style: TextStyle(color: Colors.white)),
            );
          }

          List requests = data['friendRequests'] ?? [];
          List friends = data['friends'] ?? [];

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. HEADER: SỐ LƯỢNG BẠN BÈ
                Text(
                  "${friends.length} / 20 người bạn",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Thêm các bạn thân của bạn",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),

                const SizedBox(height: 20),

                // 2. THANH TÌM KIẾM (BẤM VÀO SẼ CHUYỂN TRANG)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, color: Colors.white70),
                        SizedBox(width: 10),
                        Text(
                          "Thêm một người bạn mới",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 3. MỤC "FIND FRIENDS FROM OTHER APPS"
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Find friends from other apps",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _socialButton(Icons.facebook, Colors.blue, "Messenger"),
                    _socialButton(Icons.camera_alt, Colors.pink, "Insta"),
                    _socialButton(Icons.message, Colors.green, "Tin nhắn"),
                    _socialButton(Icons.link, Colors.grey, "Khác"),
                  ],
                ),

                const SizedBox(height: 30),

                // 4. DANH SÁCH BẠN BÈ
                if (friends.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Bạn bè của bạn",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      return _buildFriendItem(friends[index]);
                    },
                  ),
                ] else ...[
                  EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'Chua co ban be',
                    subtitle: 'Tim kiem va ket noi voi nguoi than de bat dau.',
                    actionLabel: 'Them ban',
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                  ),
                ],

                // 5. YÊU CẦU KẾT BẠN
                if (requests.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(
                            Icons.people_alt,
                            color: Colors.white70,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Yêu cầu kết bạn",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      return _buildRequestItem(requests[index]);
                    },
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                  const EmptyState(
                    icon: Icons.mark_email_unread_outlined,
                    title: 'Khong co loi moi ket ban',
                    subtitle: 'Loi moi moi se hien thi tai day de ban xu ly nhanh.',
                  ),
                ],

                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET CON: NÚT SOCIAL TRÒN ---
  Widget _socialButton(IconData icon, Color color, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[900],
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  // --- WIDGET CON: DÒNG BẠN BÈ (CÓ AVATAR VIỀN VÀNG & NÚT X) ---
  Widget _buildFriendItem(String email) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get(),
      builder: (context, snapshot) {
        String name = email.split('@')[0];
        String? avatarUrl;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var uData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          name = uData['displayName'] ?? name;
          avatarUrl = uData['avatarUrl'];
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              // Avatar viền vàng
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 15),

              // Tên
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              // Nút Xóa (X)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () => _removeFriend(email),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET CON: DÒNG YÊU CẦU (NÚT CHẤP NHẬN MÀU VÀNG) ---
  Widget _buildRequestItem(String email) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get(),
      builder: (context, snapshot) {
        String name = email.split('@')[0];
        String? avatarUrl;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var uData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          name = uData['displayName'] ?? name;
          avatarUrl = uData['avatarUrl'];
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[800],
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 15),

              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              // Nút Chấp nhận (Viên thuốc màu vàng)
              ElevatedButton(
                onPressed: () => _acceptRequest(email),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  "Chấp nhận",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(width: 10),

              // Nút Từ chối (X)
              GestureDetector(
                onTap: () => _deleteRequest(email),
                child: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }
}
