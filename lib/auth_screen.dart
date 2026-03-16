import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart'; // Nơi chứa giao diện chính của App sau khi login

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true; // Chuyển đổi giữa Đăng nhập và Đăng ký
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // Dùng cho đăng ký

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền đủ thông tin!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // ĐĂNG NHẬP
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } else {
        // ĐĂNG KÝ
        UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        
        // Tạo profile mặc định trên Firestore cho User mới
        await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
          'uid': userCred.user!.uid,
          'email': email,
          'displayName': name,
          'avatarUrl': null,
          'friends': [],
          'friendRequests': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Thành công -> Chuyển sang màn hình chính
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } on FirebaseAuthException catch (e) {
      String message = "Đã có lỗi xảy ra.";
      if (e.code == 'user-not-found') message = "Không tìm thấy tài khoản.";
      else if (e.code == 'wrong-password') message = "Sai mật khẩu.";
      else if (e.code == 'email-already-in-use') message = "Email này đã được đăng ký.";
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- LOGO & SLOGAN ---
              const Icon(Icons.favorite, color: Colors.amber, size: 80),
              const SizedBox(height: 20),
              const Text(
                "Locket",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 10),
              const Text(
                "Ảnh trực tiếp từ bạn thân\ntới màn hình chính của bạn.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 50),

              // --- FORM NHẬP LIỆU ---
              if (!_isLogin)
                _buildTextField(
                  controller: _nameController,
                  hint: "Tên hiển thị của bạn",
                  icon: Icons.person_outline,
                ),
              if (!_isLogin) const SizedBox(height: 15),

              _buildTextField(
                controller: _emailController,
                hint: "Email",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _passwordController,
                hint: "Mật khẩu",
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 30),

              // --- NÚT XÁC NHẬN ---
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                  : ElevatedButton(
                      onPressed: _submitAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: Text(
                        _isLogin ? "Đăng Nhập" : "Thiết lập Locket của tôi",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
              
              const SizedBox(height: 20),

              // --- NÚT CHUYỂN ĐỔI LOGIN / SIGNUP ---
              TextButton(
                onPressed: () {
                  setState(() => _isLogin = !_isLogin);
                },
                child: Text(
                  _isLogin ? "Chưa có tài khoản? Đăng ký ngay" : "Đã có tài khoản? Đăng nhập",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm phụ để tạo TextField đẹp
  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}