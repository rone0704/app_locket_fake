import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false; 

  // Hàm tìm kiếm người dùng
  void _onSearchChanged(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    // Tìm kiếm theo Email
    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: value.trim())
        .where('email', isLessThan: '${value.trim()}z')
        .limit(10)
        .get();

    setState(() {
      _searchResults = querySnapshot.docs.where((doc) => doc.id != currentUser!.uid).toList();
      _isLoading = false;
    });
  }

  // Hàm gửi lời mời
  Future<void> _sendRequest(String targetUid, String targetEmail) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(targetUid).update({
        'friendRequests': FieldValue.arrayUnion([currentUser!.email])
      }).catchError((e) {
        FirebaseFirestore.instance.collection('users').doc(targetUid).set({
          'friendRequests': [currentUser!.email]
        }, SetOptions(merge: true));
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã gửi lời mời tới $targetEmail")));
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Nền đen
      body: SafeArea(
        child: Column(
          children: [
            // 1. THANH TÌM KIẾM
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.grey[900], 
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        autofocus: true,
                        onChanged: _onSearchChanged,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          hintText: "Tìm hoặc thêm bạn bè",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text("Hủy", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),

            // 2. NỘI DUNG CHÍNH
            Expanded(
              child: _isSearching
                  ? _buildSearchResults() // Đang tìm -> Hiện kết quả
                  : _buildSuggestionsAndShare(), // Chưa tìm -> Hiện đề xuất & Share
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: KẾT QUẢ TÌM KIẾM ---
  Widget _buildSearchResults() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.amber));
    if (_searchResults.isEmpty) return const Center(child: Text("Không tìm thấy kết quả", style: TextStyle(color: Colors.white54)));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
      builder: (context, userSnapshot) {
        List myFriends = [];
        List myRequests = []; // Danh sách người đã gửi lời mời cho mình
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
           var myData = userSnapshot.data!.data() as Map<String, dynamic>;
           myFriends = myData['friends'] ?? [];
           myRequests = myData['friendRequests'] ?? [];
        }

        return ListView.builder(
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            var data = _searchResults[index].data() as Map<String, dynamic>;
            String email = data['email'];
            String name = data['displayName'] ?? email.split('@')[0];
            String? avatarUrl = data['avatarUrl'];
            String uid = _searchResults[index].id;
            
            // Check trạng thái
            bool isFriend = myFriends.contains(email);
            bool isIncomingRequest = myRequests.contains(email); // Họ đã gửi cho mình
            List requestsReceived = data['friendRequests'] ?? [];
            bool isSent = requestsReceived.contains(currentUser!.email); // Mình đã gửi cho họ

            // Nếu họ đã gửi lời mời cho mình, hiển thị chữ "Kiểm tra lại" hoặc icon khác
            // Nhưng đơn giản nhất là ẩn nút Thêm đi
            Widget trailingWidget;
            if (isFriend) {
              trailingWidget = const Icon(Icons.check, color: Colors.green);
            } else if (isIncomingRequest) {
              trailingWidget = const Text("Đã nhận lời mời", style: TextStyle(color: Colors.amber, fontSize: 12));
            } else if (isSent) {
              trailingWidget = const Text("Đã gửi", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold));
            } else {
              trailingWidget = ElevatedButton(
                onPressed: () => _sendRequest(uid, email),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                ),
                child: const Text("Thêm", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              );
            }

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[800],
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white)) : null,
              ),
              title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(email, style: const TextStyle(color: Colors.white54)),
              trailing: trailingWidget,
            );
          },
        );
      }
    );
  }

  // --- WIDGET: ĐỀ XUẤT & CHIA SẺ (ĐÃ SỬA LOGIC LỌC) ---
  Widget _buildSuggestionsAndShare() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. CÁC ĐỀ XUẤT 
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Text("Các đề xuất", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          
          // Stream 1: Lấy dữ liệu CỦA MÌNH (Bạn bè + Lời mời đã nhận)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) return const SizedBox();
              
              var myData = userSnapshot.data!.data() as Map<String, dynamic>;
              List myFriends = myData['friends'] ?? [];
              List myIncomingRequests = myData['friendRequests'] ?? []; // <--- QUAN TRỌNG: Lấy danh sách đang chờ duyệt
              
              // Stream 2: Lấy danh sách User gợi ý
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').limit(20).snapshots(),
                builder: (context, suggestionSnap) {
                  if (!suggestionSnap.hasData) return const SizedBox();
                  
                  // LOGIC LỌC MỚI:
                  // 1. Không phải mình
                  // 2. Không phải bạn bè
                  // 3. KHÔNG NẰM TRONG DANH SÁCH ĐÃ GỬI LỜI MỜI CHO MÌNH (myIncomingRequests)
                  var docs = suggestionSnap.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String email = data['email'];
                    bool isMe = doc.id == currentUser!.uid;
                    bool isFriend = myFriends.contains(email);
                    bool hasSentRequestToMe = myIncomingRequests.contains(email); // <--- Check lỗi logic cũ
                    
                    return !isMe && !isFriend && !hasSentRequestToMe;
                  }).toList();

                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text("Hiện chưa có đề xuất mới", style: TextStyle(color: Colors.white24)),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length > 3 ? 3 : docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      String name = data['displayName'] ?? data['email'].split('@')[0];
                      String? avatarUrl = data['avatarUrl'];
                      
                      List requestsReceived = data['friendRequests'] ?? [];
                      bool isSent = requestsReceived.contains(currentUser!.email);
                      
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null ? Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white)) : null,
                        ),
                        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: const Text("Đã có trên Locket 💛", style: TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: isSent 
                          ? const Text("Đã gửi", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                          : ElevatedButton.icon(
                              onPressed: () => _sendRequest(docs[index].id, data['email']),
                              icon: const Icon(Icons.add, size: 18, color: Colors.black),
                              label: const Text("Thêm", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              ),
                            ),
                      );
                    },
                  );
                },
              );
            },
          ),

          const SizedBox(height: 20),
          const Divider(color: Colors.grey, thickness: 0.2),
          const SizedBox(height: 10),

          // B. CHIA SẺ LIÊN KẾT
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.ios_share, color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Text("Chia sẻ liên kết Locket của bạn", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),

          _buildShareOption(Icons.facebook, Colors.blue, "Messenger"),
          _buildShareOption(Icons.message, Colors.pinkAccent, "Tin nhắn Instagram"),
          _buildShareOption(Icons.camera_alt, Colors.purpleAccent, "Tin Instagram"),
          _buildShareOption(Icons.sms, Colors.green, "Tin nhắn"),
          _buildShareOption(Icons.send, Colors.lightBlue, "Telegram"),
          _buildShareOption(Icons.link, Colors.grey, "Các ứng dụng khác"),
          
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildShareOption(IconData icon, Color color, String label) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã sao chép liên kết mời!")));
      },
    );
  }
}