import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';
import 'modern_ui.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      // Đăng nhập thành công -> main.dart tự chuyển trang
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: ${e.message}")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Modern Header
            ModernHeader(
              title: "Chào mừng trở lại",
              subtitle: "Đăng nhập để khám phá những khoảnh khắc từ bạn bè",
              icon: Icons.photo_camera_back,
            ),
            
            // Login Form
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  
                  // Email Input
                  ModernTextField(
                    label: "Email",
                    hintText: "Nhập email của bạn",
                    controller: _emailController,
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Password Input
                  ModernTextField(
                    label: "Mật khẩu",
                    hintText: "Nhập mật khẩu",
                    controller: _passwordController,
                    icon: Icons.lock_rounded,
                    isPassword: true,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Login Button
                  ModernGradientButton(
                    label: _isLoading ? "Đang đăng nhập..." : "ĐĂNG NHẬP",
                    onPressed: _isLoading ? () {} : _login,
                    isLoading: _isLoading,
                  ),
                  
                  // Divider
                  ModernDivider(text: "hoặc"),
                  
                  // Register Link
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.amber, width: 2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_add_rounded, color: Colors.amber),
                          const SizedBox(width: 12),
                          Text(
                            "ĐĂNG KÝ TÀI KHOẢN MỚI",
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
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
}