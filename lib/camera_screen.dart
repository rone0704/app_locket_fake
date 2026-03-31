import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'main.dart';
import 'friends_screen.dart';
import 'profile_screen.dart'; 
import 'gallery_screen.dart';
import 'feed_screen.dart';
import 'in_app_notifications.dart';
import 'image_url_utils.dart';

class CameraScreen extends StatefulWidget {
  final ValueChanged<bool>? onMainBarVisibilityChanged;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onGoToGallery; // Thêm biến nhận lệnh Gallery
  final VoidCallback? onGoToFeed;    // Thêm biến nhận lệnh cuộn xuống Feed

  const CameraScreen({
    super.key, 
    this.onMainBarVisibilityChanged, 
    this.onOpenSettings,
    this.onGoToGallery,
    this.onGoToFeed,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  static const bool _preferFirestoreImageStorage = true;
  Duration? _lastSuccessfulUploadDuration;

  CameraController? _controller;
  bool _isCameraInitialized = false;
  List<CameraDescription> _availableCameras = [];
  XFile? _capturedImage;
  Uint8List? _capturedPreviewBytes;
  final GlobalKey _previewBoundaryKey = GlobalKey();
  final List<_StickerItem> _stickers = [];
  int _stickerSeed = 0;
  bool _isSimulatorMode = false;
  bool _isUploading = false;
  bool _isCapturing = false;
  String? _cameraError;
  User? currentUser = FirebaseAuth.instance.currentUser;

  List<FirebaseStorage> _storageCandidates() {
    return [
      FirebaseStorage.instance,
      FirebaseStorage.instanceFor(
        bucket: 'gs://locket-clone-c51cc.firebasestorage.app',
      ),
      FirebaseStorage.instanceFor(
        bucket: 'gs://locket-clone-c51cc.appspot.com',
      ),
    ];
  }

  List<String> _bucketCandidates() {
    final Set<String> buckets = <String>{};

    String normalizeBucket(String raw) {
      var value = raw.trim();
      if (value.startsWith('gs://')) {
        value = value.substring(5);
      }
      return value;
    }

    final appBucket = Firebase.app().options.storageBucket;
    if (appBucket != null && appBucket.trim().isNotEmpty) {
      buckets.add(normalizeBucket(appBucket));
    }

    for (final storage in _storageCandidates()) {
      final bucket = storage.bucket;
      if (bucket.trim().isNotEmpty) {
        buckets.add(normalizeBucket(bucket));
      }
    }

    return buckets.toList();
  }

  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;

  final TextEditingController _captionController = TextEditingController();
  String _selectedRecipient = 'all';

  void _setMainBarVisible(bool isVisible) {
    widget.onMainBarVisibilityChanged?.call(isVisible);
  }

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      if (currentUser != null) {
        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid);
        final userDoc = await userRef.get(); 
        if (!userDoc.exists) {
          await userRef.set({
            'email': currentUser!.email,
            'uid': currentUser!.uid,
            'lastSeen': FieldValue.serverTimestamp(),
            'friendRequests': [],
            'friends': [],
          }, SetOptions(merge: true));
        } else {
          await userRef.set({
            'lastSeen': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint("Lỗi khi kết nối Firebase ở Camera: $e");
    }

    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _isSimulatorMode = true;
          _isCameraInitialized = true;
          _cameraError = null;
        });
      }
      return;
    }

    _availableCameras = List<CameraDescription>.from(cameras);
    if (_availableCameras.isEmpty) {
      try {
        _availableCameras = await availableCameras();
      } catch (e) {
        debugPrint('Retry availableCameras failed: $e');
      }
    }

    if (_availableCameras.isEmpty) {
      if (mounted) {
        setState(() {
          _isSimulatorMode = true;
          _isCameraInitialized = true;
          _cameraError = 'Không tìm thấy camera trên thiết bị này.';
        });
      }
      return;
    }

    final preferredBackIndex = _availableCameras.indexWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
    );
    if (preferredBackIndex >= 0) {
      _selectedCameraIndex = preferredBackIndex;
    } else if (_selectedCameraIndex >= _availableCameras.length) {
      _selectedCameraIndex = 0;
    }

    if (mounted) {
      setState(() {
        _isSimulatorMode = false;
        _cameraError = null;
      });
    }
    await _onNewCameraSelected(_availableCameras[_selectedCameraIndex]);
  }

  Future<void> _onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = _controller;
    if (previousCameraController != null) {
      await previousCameraController.dispose();
    }
    final CameraController newController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _controller = newController;
    bool initialized = false;
    try {
      await newController.initialize();
      await newController.setFlashMode(_flashMode);
      initialized = newController.value.isInitialized;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _cameraError = 'Không thể khởi tạo camera: $e';
      initialized = false;
      await newController.dispose();
      _controller = null;
    }
    if (mounted) {
      setState(() {
        _isCameraInitialized = initialized;
        if (initialized) {
          _cameraError = null;
        }
      });
    }
  }

  void _switchCamera() {
    if (_isSimulatorMode) return;
    if (_availableCameras.length < 2) return;
    setState(
      () => _selectedCameraIndex =
          (_selectedCameraIndex + 1) % _availableCameras.length,
    );
    _onNewCameraSelected(_availableCameras[_selectedCameraIndex]);
  }

  Future<void> _retryRealCamera() async {
    if (!mounted) return;
    setState(() {
      _isCameraInitialized = false;
      _cameraError = null;
    });
    await _initCamera();
  }

  void _toggleFlash() async {
    if (_isSimulatorMode) return;
    if (_controller == null || !_controller!.value.isInitialized) return;
    FlashMode newMode = (_flashMode == FlashMode.off)
        ? FlashMode.auto
        : (_flashMode == FlashMode.auto ? FlashMode.always : FlashMode.off);
    try {
      await _controller!.setFlashMode(newMode);
      setState(() => _flashMode = newMode);
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> _takePicture() async {
    if (_isSimulatorMode) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Thiết bị hiện tại chưa hỗ trợ chụp ảnh bằng camera.',
            ),
          ),
        );
      }
      return;
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera chưa sẵn sàng.')),
        );
      }
      return;
    }

    if (_isCapturing || controller.value.isTakingPicture) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final image = await controller.takePicture();
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _capturedImage = image;
        _capturedPreviewBytes = bytes;
        _stickers.clear();
      });
      _setMainBarVisible(false);
    } catch (e) {
      debugPrint('Take picture failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chụp ảnh thất bại: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<Uint8List?> _captureComposedPreviewBytes() async {
    try {
      final boundary =
          _previewBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Capture composed preview failed: $e');
      return null;
    }
  }

  Future<String> _getDownloadUrlWithRetry(Reference ref) async {
    FirebaseException? lastError;
    for (int attempt = 0; attempt < 4; attempt++) {
      try {
        return await ref.getDownloadURL();
      } on FirebaseException catch (e) {
        lastError = e;
        if (e.code != 'object-not-found' || attempt == 3) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
      }
    }
    throw lastError ??
        FirebaseException(
          plugin: 'firebase_storage',
          code: 'object-not-found',
          message: 'Khong the lay download URL sau khi upload.',
        );
  }

  Future<String?> _uploadViaStorageRest({
    required Uint8List fileBytes,
    required String objectPath,
    required String contentType,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) return null;

    for (final bucket in _bucketCandidates()) {
      try {
        final uri = Uri.parse(
          'https://firebasestorage.googleapis.com/v0/b/$bucket/o?name=${Uri.encodeComponent(objectPath)}',
        );

        final response = await http.post(
          uri,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': contentType,
          },
          body: fileBytes,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final map = jsonDecode(response.body) as Map<String, dynamic>;
          final name = (map['name'] as String?)?.trim();
          if (name == null || name.isEmpty) continue;

          final downloadTokens =
              (map['downloadTokens'] as String?)?.trim() ?? '';
          final encodedName = Uri.encodeComponent(name);
          if (downloadTokens.isNotEmpty) {
            final token = downloadTokens.split(',').first;
            return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedName?alt=media&token=$token';
          }
          return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedName?alt=media';
        }
      } catch (e) {
        debugPrint('REST upload exception on bucket $bucket: $e');
      }
    }

    return null;
  }

  bool _isLikelyWeakNetwork() {
    final d = _lastSuccessfulUploadDuration;
    return d != null && d > const Duration(milliseconds: 2200);
  }

  Future<String?> _buildFirestoreDataUrl(
    Uint8List originalBytes, {
    int maxBase64Length = 700000,
  }) async {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(originalBytes);
    } catch (_) {
      decoded = null;
    }

    if (decoded == null) {
      final rawB64 = base64Encode(originalBytes);
      if (rawB64.length <= maxBase64Length) {
        return 'data:image/jpeg;base64,$rawB64';
      }
      return null;
    }

    const widths = <int>[1280, 1024, 840, 720, 640, 540, 480, 420, 360, 320, 280, 240, 220, 200];
    const qualities = <int>[82, 74, 66, 58, 50, 44, 38, 32, 28, 24, 20, 16];

    for (final width in widths) {
      final resized = decoded.width > width
          ? img.copyResize(decoded, width: width)
          : decoded;

      for (final quality in qualities) {
        final jpg = img.encodeJpg(resized, quality: quality);
        final b64 = base64Encode(jpg);
        if (b64.length <= maxBase64Length) {
          return 'data:image/jpeg;base64,$b64';
        }
      }
    }

    return null;
  }

  void _addSticker(IconData icon) {
    setState(() {
      _stickers.add(
        _StickerItem(
          id: _stickerSeed++,
          icon: icon,
          offset: const Offset(120, 180),
        ),
      );
    });
  }

  Future<void> _openStickerPicker() async {
    if (_capturedImage == null) return;

    final icons = <IconData>[
      Icons.favorite_rounded, Icons.star_rounded, Icons.local_fire_department_rounded,
      Icons.sentiment_very_satisfied_rounded, Icons.auto_awesome_rounded, Icons.thumb_up_rounded,
      Icons.celebration_rounded, Icons.flash_on_rounded,
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF17191D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thêm icon vào ảnh',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: icons
                      .map(
                        (icon) => GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _addSticker(icon);
                          },
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Icon(icon, color: Colors.amber, size: 28),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadPhoto() async {
    if (_capturedImage == null) return;
    setState(() => _isUploading = true);
    try {
      final uploadStopwatch = Stopwatch()..start();
      String uploadContentType = 'image/jpeg';
      String fileExt = 'jpg';
      if (_stickers.isNotEmpty) {
        fileExt = 'png';
        uploadContentType = 'image/png';
      }
      final fileName = "IMG_${DateTime.now().millisecondsSinceEpoch}.$fileExt";
      Uint8List fileBytes;
      if (_stickers.isNotEmpty) {
        final composed = await _captureComposedPreviewBytes();
        fileBytes = composed ?? await _capturedImage!.readAsBytes();
        if (composed == null) {
          uploadContentType = 'image/jpeg';
          fileExt = 'jpg';
        }
      } else {
        fileBytes = await _capturedImage!.readAsBytes();
      }

      FirebaseException? lastStorageError;
      String? uploadedUrl;
      bool allObjectNotFound = true;
      final targetBase64Length = _isLikelyWeakNetwork() ? 450000 : 700000;

      if (_preferFirestoreImageStorage) {
        uploadedUrl = await _buildFirestoreDataUrl(
          fileBytes,
          maxBase64Length: targetBase64Length,
        );
      }

      if (uploadedUrl == null) {
        for (final storage in _storageCandidates()) {
          try {
            final ref = storage.ref().child('locket_photos/$fileName');
            final taskSnapshot = await ref.putData(
              fileBytes,
              SettableMetadata(contentType: uploadContentType),
            );
            uploadedUrl = await _getDownloadUrlWithRetry(taskSnapshot.ref);
            break;
          } on FirebaseException catch (e) {
            lastStorageError = e;
            if (e.code != 'object-not-found') {
              allObjectNotFound = false;
            }
          }
        }
      }

      if (uploadedUrl == null) {
        if (allObjectNotFound) {
          uploadedUrl = await _uploadViaStorageRest(
            fileBytes: fileBytes,
            objectPath: 'locket_photos/$fileName',
            contentType: uploadContentType,
          );
          uploadedUrl ??= await _buildFirestoreDataUrl(
            fileBytes,
            maxBase64Length: targetBase64Length,
          );
        }

        if (uploadedUrl == null) {
          throw lastStorageError ??
              FirebaseException(
                plugin: 'firebase_storage',
                code: 'object-not-found',
                message: 'Khong luu duoc anh do vuot gioi han dung luong.',
              );
        }
      }
      final String photoUrl = uploadedUrl;
      String authorName = currentUser?.email?.split('@')[0] ?? "Ẩn danh";
      final recipientUid = _selectedRecipient == 'all'
          ? null
          : await _findUserUidByEmail(_selectedRecipient);
      final postRef = await FirebaseFirestore.instance.collection('posts').add({
        'imageUrl': photoUrl,
        'caption': _captionController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'author': authorName,
        'userId': currentUser?.uid,
        'email': currentUser?.email,
        'recipient': _selectedRecipient,
        'recipientUid': recipientUid,
        'visibility': _selectedRecipient == 'all' ? 'friends' : 'single',
        'reactions': [],
      });

      await _notifyRecipientsAboutNewPost(
        postId: postRef.id,
        authorName: authorName,
      );
      uploadStopwatch.stop();
      _lastSuccessfulUploadDuration = uploadStopwatch.elapsed;

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đã gửi ảnh thành công!")));
      }
      _captionController.clear();
      setState(() {
        _capturedImage = null;
        _capturedPreviewBytes = null;
        _stickers.clear();
        _isUploading = false;
        _selectedRecipient = 'all';
      });
      _setMainBarVisible(true);
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        final friendly = e.code == 'object-not-found'
            ? 'Không lưu được ảnh do lỗi kết nối'
            : 'Lỗi: ${e.message}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gửi ảnh thất bại: $friendly")));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gửi ảnh thất bại: $e")));
      }
    }
  }

  Future<void> _notifyRecipientsAboutNewPost({
    required String postId,
    required String authorName,
  }) async {
    final user = currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = userDoc.data();
      final friends = List<String>.from(data?['friends'] ?? []);
      final friendUids = List<String>.from(data?['friendUids'] ?? []);

      final Set<String> recipientUids = <String>{};

      if (_selectedRecipient == 'all') {
        recipientUids.addAll(friendUids);
      }

      if (recipientUids.isEmpty) {
        final recipients = _selectedRecipient == 'all'
            ? friends
            : <String>[_selectedRecipient];
        final uniqueEmails = recipients
            .whereType<String>()
            .where((email) => email.isNotEmpty && email != user.email)
            .toSet();

        for (final email in uniqueEmails) {
          final uid = await _findUserUidByEmail(email);
          if (uid != null && uid != user.uid) {
            recipientUids.add(uid);
          }
        }
      }

      for (final recipientId in recipientUids) {
        await NotificationsSystem(userId: user.uid).sendNotification(
          recipientId: recipientId,
          type: 'newPost',
          title: '$authorName vừa đăng ảnh mới',
          body: 'Nhấn để mở bài viết mới nhất.',
          relatedPostId: postId,
          relatedUserId: user.uid,
        );
      }
    } catch (e) {
      debugPrint('Không thể tạo notifications cho bài mới: $e');
    }
  }

  Future<String?> _findUserUidByEmail(String email) async {
    if (email.trim().isEmpty) return null;
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off: return Icons.flash_off;
      case FlashMode.auto: return Icons.flash_auto;
      case FlashMode.always: return Icons.flash_on;
      default: return Icons.flash_off;
    }
  }

  Widget _headerIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text("Vui lòng đăng nhập lại để dùng camera", style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    if (!_isCameraInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: _cameraError == null
              ? const CircularProgressIndicator(color: Colors.amber)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 42),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(_cameraError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _retryRealCamera,
                      child: const Text('Thử lại camera'),
                    ),
                  ],
                ),
        ),
      );
    }

    // --- GIAO DIỆN PREVIEW ẢNH ---
    if (_capturedImage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    const Text("Gửi đến...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.file_upload_outlined, color: Colors.white, size: 25), onPressed: () {}),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      color: const Color(0xFF202126),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: RepaintBoundary(
                        key: _previewBoundaryKey,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: _capturedPreviewBytes == null
                                      ? Container(
                                          color: const Color(0xFF222427),
                                          alignment: Alignment.center,
                                          child: const Text("LỖI ẢNH - CHỤP LẠI", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                                        )
                                      : Image.memory(_capturedPreviewBytes!, fit: BoxFit.cover),
                                ),
                                ..._stickers.map((item) {
                                  final maxX = constraints.maxWidth - 56;
                                  final maxY = constraints.maxHeight - 130;
                                  final x = item.offset.dx.clamp(0.0, maxX);
                                  final y = item.offset.dy.clamp(0.0, maxY);
                                  return Positioned(
                                    left: x, top: y,
                                    child: GestureDetector(
                                      onPanUpdate: (details) {
                                        setState(() {
                                          item.offset = Offset((item.offset.dx + details.delta.dx).clamp(0.0, maxX), (item.offset.dy + details.delta.dy).clamp(0.0, maxY));
                                        });
                                      },
                                      onLongPress: () { setState(() { _stickers.removeWhere((s) => s.id == item.id); }); },
                                      child: Container(width: 54, height: 54, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), shape: BoxShape.circle, border: Border.all(color: Colors.white24)), child: Icon(item.icon, color: Colors.amber, size: 30)),
                                    ),
                                  );
                                }),
                                Positioned(
                                  left: 0, right: 0, bottom: 62,
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(minWidth: 186, maxWidth: 240),
                                      child: Container(
                                        height: 40,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.46), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFC88357).withValues(alpha: 0.9), width: 1.3)),
                                        child: TextField(
                                          controller: _captionController, textInputAction: TextInputAction.done,
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700), textAlign: TextAlign.center,
                                          decoration: const InputDecoration(hintText: "Thêm một tin nhắn", hintStyle: TextStyle(color: Color(0xFFE7EBF2), fontSize: 13.5, fontWeight: FontWeight.w600), filled: false, fillColor: Colors.transparent, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 9)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(7, (index) => Container(width: 7, height: 7, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: index == 0 ? Colors.white : Colors.white30, shape: BoxShape.circle)))),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 56, height: 56, child: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white, size: 40), onPressed: () { setState(() { _capturedImage = null; _capturedPreviewBytes = null; _stickers.clear(); }); _captionController.clear(); _setMainBarVisible(true); })),
                    _isUploading
                        ? const SizedBox(width: 74, height: 74, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : GestureDetector(onTap: _uploadPhoto, child: Container(width: 74, height: 74, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF44464C), border: Border.all(color: Colors.white.withValues(alpha: 0.18))), child: const Icon(Icons.send_outlined, color: Colors.white, size: 33))),
                    SizedBox(width: 56, height: 56, child: IconButton(icon: const Icon(Icons.text_fields_rounded, color: Colors.white, size: 33), onPressed: _openStickerPicker)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity, padding: const EdgeInsets.fromLTRB(16, 10, 16, 12), decoration: BoxDecoration(color: const Color(0xFF15161A), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08)))),
                child: SizedBox(
                  height: 84,
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final userData = snapshot.data!.data() as Map<String, dynamic>?;
                      final List friends = userData != null && userData.containsKey('friends') ? userData['friends'] : [];
                      return ListView.builder(
                        scrollDirection: Axis.horizontal, itemCount: friends.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) return _buildRecipientItem(label: "Tất cả", icon: Icons.people, isSelected: _selectedRecipient == 'all', onTap: () => setState(() => _selectedRecipient = 'all'));
                          final friendEmail = friends[index - 1];
                          return _buildRecipientItem(label: friendEmail.split('@')[0], textAvatar: friendEmail[0].toUpperCase(), isSelected: _selectedRecipient == friendEmail, onTap: () => setState(() => _selectedRecipient = friendEmail));
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --- GIAO DIỆN CAMERA CHÍNH
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER 3 NÚT: PROFILE - BẠN BÈ - CHAT
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 5), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Nút Cài đặt / Chuông
                  GestureDetector(
                    onTap: () {
                      if (widget.onOpenSettings != null) {
                        widget.onOpenSettings!();
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                      }
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _headerIcon(Icons.notifications_rounded),
                        Positioned(
                          top: -6, left: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                            child: const Text('NEW', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Nút Bạn Bè
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
                    builder: (context, snapshot) {
                      int requestCount = 0;
                      int friendCount = 0;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data = snapshot.data!.data() as Map<String, dynamic>;
                        if (data.containsKey('friendRequests')) requestCount = (data['friendRequests'] as List).length;
                        if (data.containsKey('friends')) friendCount = (data['friends'] as List).length;
                      }

                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendsScreen())),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.42),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.people_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text('$friendCount người bạn', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 3),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 16),
                                ],
                              ),
                            ),
                            if (requestCount > 0)
                              Positioned(
                                right: -5, top: -5,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                  child: Text(requestCount > 9 ? "9+" : requestCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  // 3. Avatar
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
                      builder: (context, snapshot) {
                        String? avatarUrl;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          avatarUrl = data?['avatarUrl'];
                        }
                        return Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.4),
                            color: Colors.black.withValues(alpha: 0.42),
                          ),
                          child: ClipOval(
                            child: avatarUrl != null
                                ? Image.network(avatarUrl, fit: BoxFit.cover)
                                : Container(
                                    color: Colors.grey[800],
                                    alignment: Alignment.center,
                                    child: Text(
                                      (currentUser?.email?.isNotEmpty ?? false) ? currentUser!.email![0].toUpperCase() : 'U',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // KHU VỰC CAMERA
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  color: Colors.grey[900],
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _isSimulatorMode || _controller == null || !_isCameraInitialized
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("CAMERA KHÔNG KHẢ DỤNG", style: TextStyle(color: Colors.white54)),
                                const SizedBox(height: 10),
                                ElevatedButton(onPressed: _retryRealCamera, child: const Text('Thử lại camera thật')),
                              ],
                            ),
                          )
                        : CameraPreview(_controller!),
                    Positioned(
                      top: 20, left: 20,
                      child: GestureDetector(
                        onTap: _toggleFlash,
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.34),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Icon(_getFlashIcon(), color: _flashMode == FlashMode.off ? Colors.white : Colors.amber, size: 24),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20, right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.36),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: const Text('1x', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // KHU VỰC NÚT BẤM
            Container(
              padding: EdgeInsets.only(
                top: 10,
                bottom: MediaQuery.of(context).padding.bottom + 90,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  
                  // ROW 3 NÚT NỔI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 32),
                        onPressed: () {
                          // BẤM VÀO ĐÂY SẼ GỌI LỆNH MỞ GALLERY CỦA MAINLAYOUT
                          if (widget.onGoToGallery != null) {
                            widget.onGoToGallery!();
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const GalleryScreen()));
                          }
                        },
                      ),
                      GestureDetector(
                        onTap: _isCapturing ? null : _takePicture,
                        child: Container(
                          width: 85, height: 85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.amber, width: 3.5),
                          ),
                          child: Center(
                            child: Container(
                              width: 68, height: 68,
                              decoration: BoxDecoration(
                                color: _isCapturing ? Colors.grey : Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.sync, color: Colors.white, size: 32),
                        onPressed: _switchCamera,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Nút Lịch Sử
                  GestureDetector(
                    onTap: () {
                      // BẤM VÀO ĐÂY SẼ GỌI LỆNH TRƯỢT XUỐNG FEED
                      if (widget.onGoToFeed != null) {
                        widget.onGoToFeed!();
                      } else {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedScreen()));
                      }
                    },
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .where('email', isEqualTo: currentUser?.email)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String? thumbUrl;
                        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                          final docs = snapshot.data!.docs;
                          docs.sort((a, b) {
                            final ta = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                            final tb = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                            return (tb?.millisecondsSinceEpoch ?? 0).compareTo(ta?.millisecondsSinceEpoch ?? 0);
                          });
                          final data = docs.first.data() as Map<String, dynamic>;
                          thumbUrl = data['imageUrl'];
                        }

                        final thumbProvider = thumbUrl == null ? null : resolveImageProvider(thumbUrl);

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                                image: thumbProvider != null ? DecorationImage(image: thumbProvider, fit: BoxFit.cover) : null,
                              ),
                              child: thumbProvider == null ? const Icon(Icons.history, color: Colors.white70, size: 17) : null,
                            ),
                            const SizedBox(width: 8),
                            const Text("Lịch sử", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15.5)),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 18),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientItem({required String label, IconData? icon, String? textAvatar, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? Colors.amber : Colors.grey[800], border: isSelected ? Border.all(color: Colors.black, width: 2) : null),
              child: icon != null ? Icon(icon, color: isSelected ? Colors.black : Colors.white, size: 27) : Center(child: Text(textAvatar!, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 22))),
            ),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(color: isSelected ? Colors.amber : Colors.white, fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _setMainBarVisible(true);
    _controller?.dispose();
    _controller = null;
    _captionController.dispose();
    super.dispose();
  }
}

class _StickerItem {
  final int id;
  final IconData icon;
  Offset offset;
  _StickerItem({required this.id, required this.icon, required this.offset});
}