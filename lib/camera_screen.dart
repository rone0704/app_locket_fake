import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

class _CameraScreenState extends State<CameraScreen>
  with WidgetsBindingObserver {
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
  bool _isSwitchingCamera = false;
  bool _isFriendsDropdownVisible = false;
  OverlayEntry? _friendsDropdownEntry;
  final TextEditingController _friendSearchController = TextEditingController();
  String _friendSearchQuery = '';
  final bool _fastShutterMode = true;
  double _uploadProgress = 0;
  String _uploadStatusText = '';
  DateTime? _lastCaptureTapAt;
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
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb || _isSimulatorMode) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _disposeCameraController();
      if (mounted && _isCameraInitialized) {
        setState(() => _isCameraInitialized = false);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_capturedImage == null && _availableCameras.isNotEmpty) {
        _onNewCameraSelected(_availableCameras[_selectedCameraIndex]);
      }
    }
  }

  Future<void> _disposeCameraController() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    try {
      await controller.dispose();
    } catch (e) {
      debugPrint('Dispose camera failed: $e');
    }
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
    if (_isSwitchingCamera) return;
    _isSwitchingCamera = true;
    await _disposeCameraController();
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
      if (_fastShutterMode) {
        try {
          await newController.setFocusMode(FocusMode.locked);
        } catch (_) {}
      }
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
    _isSwitchingCamera = false;
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
    if (_isUploading || _isSwitchingCamera) return;
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

    final now = DateTime.now();
    if (_lastCaptureTapAt != null &&
        now.difference(_lastCaptureTapAt!) < const Duration(milliseconds: 900)) {
      return;
    }
    _lastCaptureTapAt = now;

    if (_isCapturing || controller.value.isTakingPicture) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      HapticFeedback.lightImpact();
      if (_fastShutterMode) {
        try {
          await controller.setFocusMode(FocusMode.locked);
        } catch (_) {}
      }
      final image = await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _capturedImage = image;
        _capturedPreviewBytes = null;
        _stickers.clear();
      });
      _setMainBarVisible(false);

      // Decode bytes after switching UI to preview, so shutter feels instant.
      image.readAsBytes().then((bytes) {
        if (!mounted) return;
        if (_capturedImage?.path != image.path) return;
        setState(() {
          _capturedPreviewBytes = bytes;
        });
      });
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

  void _setUploadProgress(double value, {String? statusText}) {
    if (!mounted) return;
    setState(() {
      _uploadProgress = value.clamp(0.0, 1.0);
      if (statusText != null) {
        _uploadStatusText = statusText;
      }
    });
  }

  Uint8List _optimizeImageForUpload(
    Uint8List bytes, {
    required bool weakNetwork,
  }) {
    final int thresholdBytes = weakNetwork ? 320 * 1024 : 560 * 1024;
    if (bytes.lengthInBytes <= thresholdBytes) {
      return bytes;
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return bytes;
    }

    final widths = weakNetwork
        ? <int>[920, 840, 760, 680, 620, 560, 520]
        : <int>[1200, 1080, 960, 860, 780, 700, 620];
    final qualities = weakNetwork
        ? <int>[72, 64, 56, 48, 42, 36]
        : <int>[82, 76, 70, 62, 56, 50, 44];

    Uint8List? best;
    for (final width in widths) {
      final resized = decoded.width > width
          ? img.copyResize(decoded, width: width)
          : decoded;
      for (final quality in qualities) {
        final encoded = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
        best = encoded;
        if (encoded.lengthInBytes <= thresholdBytes) {
          return encoded;
        }
      }
    }
    return best ?? bytes;
  }

  Future<String?> _uploadToStorageWithRetry({
    required Uint8List fileBytes,
    required String objectPath,
    required String contentType,
    required bool weakNetwork,
  }) async {
    FirebaseException? lastError;
    final int maxAttempts = weakNetwork ? 3 : 2;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      for (final storage in _storageCandidates()) {
        try {
          _setUploadProgress(
            0.18,
            statusText: 'Đang tải lên (lần $attempt/$maxAttempts)...',
          );
          final ref = storage.ref().child(objectPath);
          final task = ref.putData(
            fileBytes,
            SettableMetadata(contentType: contentType),
          );

          await for (final snapshot in task.snapshotEvents) {
            final total = snapshot.totalBytes <= 0 ? 1 : snapshot.totalBytes;
            final fraction = snapshot.bytesTransferred / total;
            _setUploadProgress(0.18 + (fraction * 0.72));
          }

          final completed = await task;
          _setUploadProgress(0.93, statusText: 'Đang lấy link ảnh...');
          return await _getDownloadUrlWithRetry(completed.ref);
        } on FirebaseException catch (e) {
          lastError = e;
          if (e.code != 'object-not-found' && e.code != 'retry-limit-exceeded') {
            break;
          }
        } catch (e) {
          debugPrint('Upload attempt failed: $e');
        }
      }

      if (attempt < maxAttempts) {
        final backoff = Duration(milliseconds: 500 * attempt);
        _setUploadProgress(0.16, statusText: 'Mạng yếu, thử lại...');
        await Future<void>.delayed(backoff);
      }
    }

    if (lastError != null) throw lastError;
    return null;
  }

  void _addSticker(_StickerPreset preset) {
    setState(() {
      _stickers.add(
        _StickerItem(
          id: _stickerSeed++,
          glyph: preset.glyph,
          color: preset.color,
          offset: const Offset(120, 180),
        ),
      );
    });
  }

  Future<void> _openStickerPicker() async {
    if (_capturedImage == null) return;

    final presets = <_StickerPreset>[
      _StickerPreset('❤️', 'Tim', const Color(0xFFFF4D6D)),
      _StickerPreset('⭐', 'Sao', const Color(0xFFFFC93C)),
      _StickerPreset('🔥', 'Lửa', const Color(0xFFFF7A18)),
      _StickerPreset('😄', 'Vui', const Color(0xFF55D6FF)),
      _StickerPreset('✨', 'Lấp lánh', const Color(0xFF7EE8FA)),
      _StickerPreset('👍', 'Like', const Color(0xFF39D98A)),
      _StickerPreset('🎉', 'Bung', const Color(0xFFF472B6)),
      _StickerPreset('⚡', 'Tia', const Color(0xFFB08CFF)),
    ];

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Sticker picker',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        int? pressedIndex;

        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101216).withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Thêm icon vào ảnh',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.96),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              'Vuốt ngang',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 112,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: presets.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final preset = presets[index];
                              final selected = pressedIndex == index;
                              return GestureDetector(
                                onTapDown: (_) {
                                  HapticFeedback.selectionClick();
                                  setSheetState(() => pressedIndex = index);
                                },
                                onTapCancel: () {
                                  setSheetState(() => pressedIndex = null);
                                },
                                onTap: () async {
                                  setSheetState(() => pressedIndex = index);
                                  await Future<void>.delayed(const Duration(milliseconds: 110));
                                  if (!dialogContext.mounted) return;
                                  Navigator.pop(dialogContext);
                                  _addSticker(preset);
                                },
                                child: AnimatedScale(
                                  scale: selected ? 1.08 : 1.0,
                                  duration: const Duration(milliseconds: 120),
                                  curve: Curves.easeOutBack,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 78,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withValues(alpha: 0.14),
                                          preset.color.withValues(alpha: 0.16),
                                        ],
                                      ),
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: selected ? 0.22 : 0.12),
                                        width: 0.8,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: preset.color.withValues(alpha: selected ? 0.42 : 0.18),
                                          blurRadius: selected ? 18 : 10,
                                          spreadRadius: selected ? 1 : 0,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black.withValues(alpha: 0.26),
                                            boxShadow: [
                                              BoxShadow(
                                                color: preset.color.withValues(alpha: selected ? 0.48 : 0.26),
                                                blurRadius: selected ? 18 : 10,
                                                spreadRadius: selected ? 0.5 : 0,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            preset.glyph,
                                            style: const TextStyle(fontSize: 24),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          preset.label,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.92),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
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
                );
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _uploadPhoto() async {
    if (_capturedImage == null) return;
    if (_isUploading) return;
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.04;
      _uploadStatusText = 'Đang chuẩn bị ảnh...';
    });
    try {
      final uploadStopwatch = Stopwatch()..start();
      String uploadContentType = 'image/jpeg';
      String fileExt = 'jpg';
      if (_stickers.isNotEmpty) {
        fileExt = 'png';
        uploadContentType = 'image/png';
      }
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

      final weakNetwork = _isLikelyWeakNetwork();
      _setUploadProgress(0.1, statusText: 'Đang tối ưu ảnh...');
      fileBytes = _optimizeImageForUpload(fileBytes, weakNetwork: weakNetwork);
      uploadContentType = 'image/jpeg';
      fileExt = 'jpg';
      final objectPath = 'locket_photos/IMG_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      FirebaseException? lastStorageError;
      String? uploadedUrl;
      bool allObjectNotFound = true;
      final targetBase64Length = weakNetwork ? 450000 : 700000;

      if (_preferFirestoreImageStorage) {
        _setUploadProgress(0.14, statusText: 'Đang thử lưu nhẹ...');
        uploadedUrl = await _buildFirestoreDataUrl(
          fileBytes,
          maxBase64Length: targetBase64Length,
        );
      }

      if (uploadedUrl == null) {
        try {
          uploadedUrl = await _uploadToStorageWithRetry(
            fileBytes: fileBytes,
            objectPath: objectPath,
            contentType: uploadContentType,
            weakNetwork: weakNetwork,
          );
        } on FirebaseException catch (e) {
          lastStorageError = e;
          if (e.code != 'object-not-found') {
            allObjectNotFound = false;
          }
        }
      }

      if (uploadedUrl == null) {
        if (allObjectNotFound) {
          _setUploadProgress(0.9, statusText: 'Đang thử kênh dự phòng...');
          uploadedUrl = await _uploadViaStorageRest(
            fileBytes: fileBytes,
            objectPath: objectPath,
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
        _setUploadProgress(0.96, statusText: 'Đang tạo bài viết...');
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
      _setUploadProgress(1, statusText: 'Hoàn tất');
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
        _uploadProgress = 0;
        _uploadStatusText = '';
        _selectedRecipient = 'all';
      });
      _setMainBarVisible(true);
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
          _uploadStatusText = '';
        });
        final friendly = e.code == 'object-not-found'
            ? 'Không lưu được ảnh do lỗi kết nối'
            : 'Lỗi: ${e.message}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gửi ảnh thất bại: $friendly")));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
          _uploadStatusText = '';
        });
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

  Future<void> _toggleFriendsDropdown() async {
    if (_friendsDropdownEntry != null) {
      await _hideFriendsDropdown();
      return;
    }
    _friendSearchController.clear();
    _friendSearchQuery = '';
    _showFriendsDropdown();
  }

  void _showFriendsDropdown() {
    final overlay = Overlay.of(context, rootOverlay: true);

    setState(() {
      _isFriendsDropdownVisible = true;
    });

    _friendsDropdownEntry = OverlayEntry(
      builder: (overlayContext) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    _hideFriendsDropdown();
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
              _buildFriendsDropdownOverlay(),
            ],
          ),
        );
      },
    );

    overlay.insert(_friendsDropdownEntry!);
  }

  Future<void> _hideFriendsDropdown() async {
    final entry = _friendsDropdownEntry;
    if (entry == null) return;

    if (mounted) {
      setState(() {
        _isFriendsDropdownVisible = false;
      });
    }
    entry.markNeedsBuild();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_friendsDropdownEntry == entry) {
      entry.remove();
      _friendsDropdownEntry = null;
    }
  }

  Color _pastelColorFor(String seed) {
    const palette = <Color>[
      Color(0xFFF6C1C1),
      Color(0xFFF9D9A0),
      Color(0xFFF8EEA3),
      Color(0xFFCDECCF),
      Color(0xFFBFE3FF),
      Color(0xFFD7C8FF),
      Color(0xFFFFD4EA),
      Color(0xFFC7D3E8),
    ];
    final hash = seed.codeUnits.fold<int>(0, (acc, code) => acc + code);
    return palette[hash % palette.length];
  }

  Future<List<_FriendProfile>> _loadFriendProfiles(List rawFriends) async {
    final profiles = <_FriendProfile>[];

    for (final raw in rawFriends) {
      final token = raw.toString().trim();
      if (token.isEmpty) continue;

      Map<String, dynamic>? data;
      String email = token.contains('@') ? token : '';

      try {
        if (token.contains('@')) {
          final query = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: token)
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            data = query.docs.first.data();
            email = (data['email'] as String?)?.trim() ?? token;
          }
        } else {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(token)
              .get();
          if (doc.exists) {
            data = doc.data();
            email = (data?['email'] as String?)?.trim() ?? '';
          }
        }
      } catch (_) {}

      final displayName = (data?['displayName'] as String?)?.trim();
      final avatarUrl = (data?['avatarUrl'] as String?)?.trim();
      final ts = data?['lastSeen'];
      DateTime? lastSeen;
      if (ts is Timestamp) {
        lastSeen = ts.toDate();
      }

      final fallback = email.isNotEmpty
          ? email.split('@')[0]
          : (token.contains('@') ? token.split('@')[0] : token);

      profiles.add(
        _FriendProfile(
          displayName: (displayName != null && displayName.isNotEmpty)
              ? displayName
              : fallback,
          email: email,
          avatarUrl: (avatarUrl != null && avatarUrl.isNotEmpty) ? avatarUrl : null,
          isOnline: lastSeen != null &&
              DateTime.now().difference(lastSeen) <= const Duration(minutes: 8),
        ),
      );
    }

    return profiles;
  }

  Widget _buildFriendsDropdownOverlay() {
    if (currentUser == null) return const SizedBox.shrink();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      top: _isFriendsDropdownVisible ? 60 : -300,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final List friends = data != null && data.containsKey('friends')
                ? data['friends'] as List
                : [];
            final myName = (data?['displayName'] as String?)?.trim();
            final myEmail = (data?['email'] as String?)?.trim() ?? (currentUser?.email ?? '');
            final myAvatar = (data?['avatarUrl'] as String?)?.trim();
            final myOnlineTs = data?['lastSeen'];
            final isMeOnline = myOnlineTs is Timestamp &&
                DateTime.now().difference(myOnlineTs.toDate()) <= const Duration(minutes: 8);

            return GestureDetector(
              onTap: () {},
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 430),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A).withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 9),
                        GestureDetector(
                          onTap: _hideFriendsDropdown,
                          child: Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.34),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Bạn bè của bạn',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  _hideFriendsDropdown();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FriendsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                                label: const Text('Tìm thêm'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.amber,
                                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                          child: TextField(
                            controller: _friendSearchController,
                            onChanged: (value) {
                              setState(() {
                                _friendSearchQuery = value.trim().toLowerCase();
                              });
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Tìm bạn bè...',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.08),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          child: FutureBuilder<List<_FriendProfile>>(
                            future: _loadFriendProfiles(friends),
                            builder: (context, friendSnapshot) {
                              if (!friendSnapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: CircularProgressIndicator(color: Colors.amber),
                                );
                              }

                              final allFriends = friendSnapshot.data!;
                              final query = _friendSearchQuery;
                              final filteredFriends = query.isEmpty
                                  ? allFriends
                                  : allFriends.where((friend) {
                                      final name = friend.displayName.toLowerCase();
                                      final email = friend.email.toLowerCase();
                                      return name.contains(query) || email.contains(query);
                                    }).toList();

                              return ListView.separated(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                                itemCount: filteredFriends.length + 2,
                                separatorBuilder: (_, sepIndex) => Divider(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  height: 1,
                                  indent: 64,
                                  endIndent: 18,
                                ),
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      leading: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          const CircleAvatar(
                                            radius: 21,
                                            backgroundColor: Color(0xFFEAB308),
                                            child: Icon(Icons.people_alt_rounded, color: Colors.black),
                                          ),
                                          Positioned(
                                            right: -1,
                                            bottom: -1,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF28C76F),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: const Color(0xFF2A2A2A), width: 1.5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      title: const Text(
                                        'Mọi người',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                                      ),
                                      subtitle: Text(
                                        'Chia sẻ với tất cả bạn bè',
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
                                      ),
                                      trailing: _selectedRecipient == 'all'
                                          ? const Icon(Icons.check_rounded, color: Colors.amber)
                                          : const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                                      onTap: () {
                                        setState(() {
                                          _selectedRecipient = 'all';
                                        });
                                        _hideFriendsDropdown();
                                      },
                                    );
                                  }

                                  if (index == 1) {
                                    final title = (myName != null && myName.isNotEmpty)
                                        ? myName
                                        : (myEmail.isNotEmpty ? myEmail.split('@')[0] : 'Tôi');
                                    final avatarColor = _pastelColorFor(title);
                                    final avatarLetter = title.isNotEmpty ? title[0].toUpperCase() : 'T';

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      leading: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          CircleAvatar(
                                            radius: 21,
                                            backgroundColor: avatarColor,
                                            backgroundImage: (myAvatar != null && myAvatar.isNotEmpty)
                                                ? NetworkImage(myAvatar)
                                                : null,
                                            child: (myAvatar == null || myAvatar.isEmpty)
                                                ? Text(
                                                    avatarLetter,
                                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                                                  )
                                                : null,
                                          ),
                                          if (isMeOnline)
                                            Positioned(
                                              right: -1,
                                              bottom: -1,
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF28C76F),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: const Color(0xFF2A2A2A), width: 1.5),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      title: Text(
                                        title,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                                      ),
                                      subtitle: Text(
                                        myEmail.isNotEmpty ? myEmail : 'Tài khoản của bạn',
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
                                      ),
                                      trailing: _selectedRecipient == myEmail
                                          ? const Icon(Icons.check_rounded, color: Colors.amber)
                                          : const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                                      onTap: () {
                                        setState(() {
                                          _selectedRecipient = myEmail;
                                        });
                                        _hideFriendsDropdown();
                                      },
                                    );
                                  }

                                  final friend = filteredFriends[index - 2];
                                  final avatarColor = _pastelColorFor(friend.displayName);
                                  final avatarLetter = friend.displayName.isNotEmpty
                                      ? friend.displayName[0].toUpperCase()
                                      : 'U';

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    leading: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        CircleAvatar(
                                          radius: 21,
                                          backgroundColor: avatarColor,
                                          backgroundImage: friend.avatarUrl != null
                                              ? NetworkImage(friend.avatarUrl!)
                                              : null,
                                          child: friend.avatarUrl == null
                                              ? Text(
                                                  avatarLetter,
                                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                                                )
                                              : null,
                                        ),
                                        if (friend.isOnline)
                                          Positioned(
                                            right: -1,
                                            bottom: -1,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF28C76F),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: const Color(0xFF2A2A2A), width: 1.5),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    title: Text(
                                      friend.displayName,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15.5),
                                    ),
                                    subtitle: Text(
                                      friend.email,
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
                                    ),
                                    trailing: _selectedRecipient == friend.email
                                        ? const Icon(Icons.check_rounded, color: Colors.amber)
                                        : const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
                                    onTap: () {
                                      setState(() {
                                        _selectedRecipient = friend.email;
                                      });
                                      _hideFriendsDropdown();
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
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
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.97, end: 1),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(scale: value, child: child),
              );
            },
            child: Column(
              children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    const Text("Gửi đến...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.file_upload_outlined, color: Colors.white, size: 24), onPressed: () {}),
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
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.26),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 0.7),
                                          boxShadow: [
                                            BoxShadow(
                                              color: item.color.withValues(alpha: 0.48),
                                              blurRadius: 14,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            item.glyph,
                                            style: TextStyle(
                                              fontSize: 29,
                                              shadows: [
                                                Shadow(
                                                  color: item.color.withValues(alpha: 0.72),
                                                  blurRadius: 12,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                Positioned(
                                  left: 0, right: 0, bottom: 72,
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(minWidth: 196, maxWidth: 252),
                                      child: Container(
                                        height: 42,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.56),
                                          borderRadius: BorderRadius.circular(22),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.28),
                                              blurRadius: 10,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: TextField(
                                          controller: _captionController, textInputAction: TextInputAction.done,
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700), textAlign: TextAlign.center,
                                          cursorColor: Colors.white70,
                                          decoration: const InputDecoration(
                                            hintText: "Thêm một tin nhắn",
                                            hintStyle: TextStyle(
                                              color: Color(0xFFE7EBF2),
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            filled: false,
                                            fillColor: Colors.transparent,
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                                          ),
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
                        ? Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF3F4147),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: CircularProgressIndicator(
                                    value: _uploadProgress <= 0 ? null : _uploadProgress,
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                                Text(
                                  '${(_uploadProgress * 100).clamp(0, 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(onTap: _uploadPhoto, child: Container(width: 74, height: 74, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF44464C), border: Border.all(color: Colors.white.withValues(alpha: 0.18))), child: const Icon(Icons.send_outlined, color: Colors.white, size: 33))),
                    SizedBox(width: 56, height: 56, child: IconButton(icon: const Icon(Icons.text_fields_rounded, color: Colors.white, size: 33), onPressed: _openStickerPicker)),
                  ],
                ),
              ),
              if (_isUploading && _uploadStatusText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _uploadStatusText,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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
                        onTap: _toggleFriendsDropdown,
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
                    _isSimulatorMode
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
                bottom: MediaQuery.of(context).padding.bottom + 96,
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
                        onPressed: (_isCapturing || _isUploading) ? null : () {
                          // BẤM VÀO ĐÂY SẼ GỌI LỆNH MỞ GALLERY CỦA MAINLAYOUT
                          if (widget.onGoToGallery != null) {
                            widget.onGoToGallery!();
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const GalleryScreen()));
                          }
                        },
                      ),
                      GestureDetector(
                        onTap: (_isCapturing || _isUploading) ? null : _takePicture,
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
                                color: (_isCapturing || _isUploading) ? Colors.grey : Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.sync, color: Colors.white, size: 32),
                        onPressed: (_isCapturing || _isUploading) ? null : _switchCamera,
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
    _friendsDropdownEntry?.remove();
    _friendsDropdownEntry = null;
    WidgetsBinding.instance.removeObserver(this);
    _setMainBarVisible(true);
    _disposeCameraController();
    _captionController.dispose();
    _friendSearchController.dispose();
    super.dispose();
  }
}

class _FriendProfile {
  final String displayName;
  final String email;
  final String? avatarUrl;
  final bool isOnline;

  _FriendProfile({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.isOnline,
  });
}

class _StickerItem {
  final int id;
  final String glyph;
  final Color color;
  Offset offset;
  _StickerItem({required this.id, required this.glyph, required this.color, required this.offset});
}

class _StickerPreset {
  final String glyph;
  final String label;
  final Color color;

  const _StickerPreset(this.glyph, this.label, this.color);
}