import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'main_layout.dart';
import 'theme.dart';
import 'welcome_screen.dart';
import 'app_navigator.dart';
import 'push_notification_service.dart';
import 'app_theme_controller.dart';

// --- BIẾN CAMERA TOÀN CỤC ---
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // --- CẤU HÌNH FIREBASE THỦ CÔNG (DÙNG CÁI CŨ CỦA BẠN) ---
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        // [QUAN TRỌNG] Bạn hãy dán lại đoạn mã API Key cũ của bạn vào đây nhé
        // Nếu không nhớ thì vào file main.dart cũ lục lại, hoặc vào Firebase Console lấy lại
        apiKey: "AIzaSyBJwxFU2Wco7q3FSS-rf5TtuRsQSwa5fvc",
        authDomain: "locket-clone-c51cc.firebaseapp.com",
        projectId: "locket-clone-c51cc",
        storageBucket: "locket-clone-c51cc.firebasestorage.app",
        messagingSenderId: "65411796315",
        appId: "1:65411796315:web:eb9fdac18131c3bdab5e7e",
        measurementId: "G-8WMFNFTELR",
      ),
    );
  } catch (e) {
    debugPrint("Lỗi Firebase: $e");
  }

  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Không tìm thấy camera: $e');
  }

  try {
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint('Không thể khởi tạo push notifications: $e');
  }

  await AppThemeController.loadThemeMode();

  runApp(const MyApp());
}

// --- LỚP CẤU HÌNH CUỘN CHUỘT (FIX LỖI KHÔNG KÉO ĐƯỢC) ---
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse, // <--- Thêm cái này để chuột kéo được
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, themeMode, child) {
        return ValueListenableBuilder<DarkPalette>(
          valueListenable: AppThemeController.darkPalette,
          builder: (context, darkPalette, _) {
            return MaterialApp(
              navigatorKey: appNavigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'Locket Clone',
              scrollBehavior: MyCustomScrollBehavior(),
              locale: const Locale('vi', 'VN'),
              supportedLocales: const [
                Locale('vi', 'VN'),
                Locale('en', 'US'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              theme: getLightTheme(),
              darkTheme: getDarkTheme(darkPalette),
              themeMode: themeMode,
              home: const AppEntryGate(),
            );
          },
        );
      },
    );
  }
}

class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  static const int _requiredWelcomeVersion = 2;
  bool? _showWelcome;

  @override
  void initState() {
    super.initState();
    _loadWelcomeState();
  }

  Future<void> _loadWelcomeState() async {
    final prefs = await SharedPreferences.getInstance();
    final seenVersion =
        prefs.getInt('welcome_version_seen') ??
        ((prefs.getBool('seen_welcome') ?? false) ? 1 : 0);

    if (!mounted) return;
    setState(() {
      _showWelcome = seenVersion < _requiredWelcomeVersion;
    });
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spinner
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: Colors.amber,
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.amber.shade400,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Loading text with animated dots
              _AnimatedLoadingText(),
              const SizedBox(height: 16),
              Text(
                'Khởi động ứng dụng...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcome == null) {
      return _buildLoadingScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasData) {
          return const MainLayout();
        }

        if (_showWelcome == true) {
          return WelcomeScreen(
            onFinished: () {
              appNavigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}

class _AnimatedLoadingText extends StatefulWidget {
  const _AnimatedLoadingText();

  @override
  State<_AnimatedLoadingText> createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<_AnimatedLoadingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dots =
            '.' * ((_controller.value * 3).toInt() % 4);
        return Text(
          'Đang tải$dots',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.amber,
            letterSpacing: 1.5,
          ),
        );
      },
    );
  }
}
