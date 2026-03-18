import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'modern_ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Hàm tạo tài khoản mới
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Sau khi đăng ký xong, Firebase tự động log-in luôn.
      // Ta đóng màn hình đăng ký này lại để main.dart lo phần còn lại
      if (mounted) Navigator.pop(context); 

    } on FirebaseAuthException catch (e) {
      String message = "Lỗi xảy ra";
      if (e.code == 'weak-password') {
        message = "Mật khẩu quá yếu";
      } else if (e.code == 'email-already-in-use') {
        message = "Email này đã được dùng rồi";
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
            // Modern Header with back button
            Stack(
              children: [
                ModernHeader(
                  title: "Tạo tài khoản mới",
                  subtitle: "Tham gia mạng xã hội Locket ngay",
                  icon: Icons.person_add_alt_1_rounded,
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[900],
                      border: Border.all(color: Colors.amber, width: 1.5),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.amber),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
            
            // Register Form
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  
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
                    hintText: "Tối thiểu 6 ký tự",
                    controller: _passwordController,
                    icon: Icons.lock_rounded,
                    isPassword: true,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Register Button
                  ModernGradientButton(
                    label: _isLoading ? "Đang tạo tài khoản..." : "ĐĂNG KÝ",
                    onPressed: _isLoading ? () {} : _register,
                    isLoading: _isLoading,
                  ),
                  
                  // Divider
                  ModernDivider(text: "hoặc"),
                  
                  // Login Link
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54, width: 1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login_rounded, color: Colors.white70),
                          const SizedBox(width: 12),
                          Text(
                            "QUAY LẠI ĐĂNG NHẬP",
                            style: TextStyle(
                              color: Colors.white70,
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