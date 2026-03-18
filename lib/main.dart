import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // <--- Thư viện để chuột kéo được
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'login_screen.dart';
import 'main_layout.dart';
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
        measurementId: "G-8WMFNFTELR"
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Locket Clone',
      
      // --- KÍCH HOẠT KÉO CHUỘT ---
      scrollBehavior: MyCustomScrollBehavior(), 
      
      theme: ThemeData(
        brightness: Brightness.dark, 
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
        return const MainLayout(); // <--- Đổi từ CameraScreen thành HomeScreen
      }
      return const LoginScreen(); 
        },
      ),
    );
  }
}