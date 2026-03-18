import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; 
import 'friends_screen.dart';
import 'profile_screen.dart'; // Mở Profile
import 'chat_list_screen.dart'; // Mở Chat
import 'gallery_screen.dart'; 

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  XFile? _capturedImage;
  bool _isSimulatorMode = false;
  bool _isUploading = false;
  User? currentUser = FirebaseAuth.instance.currentUser;

  int _selectedCameraIndex = 0; 
  FlashMode _flashMode = FlashMode.off; 

  final TextEditingController _captionController = TextEditingController();
  String _selectedRecipient = 'all';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      if (currentUser != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
        final userDoc = await userRef.get(); // Nếu lỗi ở đây, nó sẽ nhảy xuống catch thay vì làm đứng app
        if (!userDoc.exists) {
           await userRef.set({
              'email': currentUser!.email, 'uid': currentUser!.uid, 'lastSeen': FieldValue.serverTimestamp(),
              'friendRequests': [], 'friends': []
           }, SetOptions(merge: true));
        } else {
          await userRef.set({'lastSeen': FieldValue.serverTimestamp()}, SetOptions(merge: true));
        }
      }
    } catch (e) {
      // In lỗi ra console để biết, nhưng KHÔNG làm chết app
      debugPrint("Lỗi khi kết nối Firebase ở Camera: $e");
    }

    // 2. KHÚC NÀY LUÔN ĐƯỢC CHẠY DÙ FIREBASE CÓ LỖI HAY KHÔNG
    if (kIsWeb || cameras.isEmpty) {
      if (mounted) {
        setState(() { _isSimulatorMode = true; _isCameraInitialized = true; });
      }
      return;
    }
    _onNewCameraSelected(cameras[_selectedCameraIndex]);
  }

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = _controller;
    if (previousCameraController != null) {
      await previousCameraController.dispose();
    }
    final CameraController newController = CameraController(
      cameraDescription, ResolutionPreset.high, enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = newController;
    try {
      await newController.initialize();
      await newController.setFlashMode(_flashMode);
    } catch (e) { debugPrint('Error initializing camera: $e'); }
    if (mounted) setState(() => _isCameraInitialized = _controller!.value.isInitialized);
  }

  void _switchCamera() {
    if (cameras.length < 2) return;
    setState(() => _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length);
    _onNewCameraSelected(cameras[_selectedCameraIndex]);
  }

  void _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    FlashMode newMode = (_flashMode == FlashMode.off) ? FlashMode.auto : (_flashMode == FlashMode.auto ? FlashMode.always : FlashMode.off);
    try { await _controller!.setFlashMode(newMode); setState(() => _flashMode = newMode); } catch (e) { debugPrint('$e'); }
  }

  Future<void> _takePicture() async {
    if (_isSimulatorMode) { setState(() => _capturedImage = XFile('')); return; }
    try { final image = await _controller!.takePicture(); setState(() => _capturedImage = image); } catch (e) { debugPrint('$e'); }
  }

  Future<void> _uploadPhoto() async {
    if (_capturedImage == null) return;
    setState(() => _isUploading = true);
    try {
      String photoUrl;
      String fileName = "IMG_${DateTime.now().millisecondsSinceEpoch}.jpg";
      if (_isSimulatorMode) {
        await Future.delayed(const Duration(seconds: 1));
        photoUrl = "https://picsum.photos/seed/$fileName/800/1000";
      } else {
        Reference ref = FirebaseStorage.instance.ref().child('locket_photos/$fileName');
        Uint8List fileBytes = await _capturedImage!.readAsBytes();
        await ref.putData(fileBytes, SettableMetadata(contentType: 'image/jpeg'));
        photoUrl = await ref.getDownloadURL();
      }
      String authorName = currentUser?.email?.split('@')[0] ?? "Ẩn danh";
      await FirebaseFirestore.instance.collection('posts').add({
        'imageUrl': photoUrl, 'caption': _captionController.text.trim(), 'timestamp': FieldValue.serverTimestamp(),
        'author': authorName, 'userId': currentUser?.uid, 'email': currentUser?.email, 'recipient': _selectedRecipient, 'reactions': [],
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi ảnh thành công!")));
      }
      _captionController.clear();
      setState(() { _capturedImage = null; _isUploading = false; _selectedRecipient = 'all'; });
    } catch (e) { setState(() => _isUploading = false); }
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off: return Icons.flash_off;
      case FlashMode.auto: return Icons.flash_auto;
      case FlashMode.always: return Icons.flash_on;
      default: return Icons.flash_off;
    }
  }

  // --- HÀM TẠO ICON GIỐNG FEED SCREEN ---
  Widget _headerIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.grey[900], shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));

    // --- GIAO DIỆN PREVIEW ẢNH ---
    if (_capturedImage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 30),
                        const Text("Gửi đến...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                        IconButton(icon: const Icon(Icons.download_rounded, color: Colors.white, size: 30), onPressed: () {}),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35),
                        image: _isSimulatorMode ? null : DecorationImage(image: NetworkImage(_capturedImage!.path), fit: BoxFit.cover),
                        color: _isSimulatorMode ? Colors.amber : Colors.black,
                      ),
                      child: Stack(
                        children: [
                          if (_isSimulatorMode) const Center(child: Text("ẢNH GIẢ LẬP", style: TextStyle(fontWeight: FontWeight.bold))),
                          Positioned(
                            bottom: 30, left: 20, right: 20,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(30)),
                                child: TextField(controller: _captionController, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center, decoration: const InputDecoration(hintText: "Thêm một tin nhắn", hintStyle: TextStyle(color: Colors.white60), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 35), onPressed: () { setState(() => _capturedImage = null); _captionController.clear(); }),
                        _isUploading ? const CircularProgressIndicator(color: Colors.amber) : GestureDetector(onTap: _uploadPhoto, child: Container(width: 80, height: 80, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle), child: const Icon(Icons.send_rounded, color: Colors.white, size: 40))),
                        IconButton(icon: const Icon(Icons.font_download_outlined, color: Colors.white, size: 35), onPressed: () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 90,
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        var userData = snapshot.data!.data() as Map<String, dynamic>?;
                        List friends = userData != null && userData.containsKey('friends') ? userData['friends'] : [];
                        return ListView.builder(
                          scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: friends.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) return _buildRecipientItem(label: "Tất cả", icon: Icons.people, isSelected: _selectedRecipient == 'all', onTap: () => setState(() => _selectedRecipient = 'all'));
                            String friendEmail = friends[index - 1];
                            return _buildRecipientItem(label: friendEmail.split('@')[0], textAvatar: friendEmail[0].toUpperCase(), isSelected: _selectedRecipient == friendEmail, onTap: () => setState(() => _selectedRecipient = friendEmail));
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // --- GIAO DIỆN CAMERA CHÍNH (ĐÃ ĐỒNG BỘ 3 NÚT TRÊN CÙNG) ---
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER 3 NÚT: PROFILE - BẠN BÈ - CHAT (Đã chỉnh kích thước giống Feed)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 5), // Canh chỉnh giống FeedScreen
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Nút Profile (Giống Feed)
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())), 
                    child: _headerIcon(Icons.person),
                  ),

                  // 2. Nút Bạn Bè (Center - Giống nút "Mọi người" bên Feed)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
                    builder: (context, snapshot) {
                      int requestCount = 0;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data = snapshot.data!.data() as Map<String, dynamic>;
                        if (data.containsKey('friendRequests')) requestCount = (data['friendRequests'] as List).length;
                      }
                      
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendsScreen())),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // VIÊN THUỐC (Pill shape) giống Feed
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), 
                              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(20)), 
                              child: const Row(
                                children: [
                                  Text("Bạn bè", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // Chữ đậm giống Feed
                                  SizedBox(width: 5),
                                  Icon(Icons.people, color: Colors.white, size: 16), // Icon nhỏ size 16 giống arrow bên Feed
                                ],
                              ),
                            ),
                            // Thông báo đỏ
                            if (requestCount > 0) 
                              Positioned(
                                right: -5, top: -5, 
                                child: Container(
                                  padding: const EdgeInsets.all(5), 
                                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), 
                                  child: Text(requestCount > 9 ? "9+" : requestCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                                )
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // 3. Nút Chat (Giống Feed)
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListScreen())), 
                    child: _headerIcon(Icons.chat_bubble_outline),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(35), color: Colors.grey[900]),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _isSimulatorMode ? const Center(child: Text("CAMERA GIẢ LẬP", style: TextStyle(color: Colors.white54))) : CameraPreview(_controller!),
                    Positioned(
                      top: 20, left: 20,
                      child: GestureDetector(
                        onTap: _toggleFlash,
                        child: Icon(_getFlashIcon(), color: _flashMode == FlashMode.off ? Colors.white : Colors.amber, size: 30),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.only(bottom: 10, top: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // NÚT THƯ VIỆN ẢNH (BÊN TRÁI)
                      IconButton(
                        icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 30), 
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const GalleryScreen()));
                        },
                      ),
                      
                      // NÚT CHỤP (GIỮA)
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(width: 75, height: 75, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.amber, width: 5), color: Colors.white)),
                      ),
                      
                      // NÚT XOAY CAMERA (BÊN PHẢI)
                      IconButton(
                        icon: const Icon(Icons.cached, color: Colors.white, size: 28),
                        onPressed: _switchCamera, 
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Column(
                    children: [
                      Icon(Icons.keyboard_arrow_up, color: Colors.white54, size: 20),
                      Text("Lịch sử", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientItem({required String label, IconData? icon, String? textAvatar, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(onTap: onTap, child: Container(margin: const EdgeInsets.symmetric(horizontal: 10), child: Column(children: [Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? Colors.amber : Colors.grey[800], border: isSelected ? Border.all(color: Colors.black, width: 2) : null), child: icon != null ? Icon(icon, color: isSelected ? Colors.black : Colors.white, size: 30) : Center(child: Text(textAvatar!, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 24)))), const SizedBox(height: 5), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))])));
  }
}