import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      if (e.code == 'weak-password') message = "Mật khẩu quá yếu";
      else if (e.code == 'email-already-in-use') message = "Email này đã được dùng rồi";
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Nền đen cho khác biệt chút
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.amber),
          onPressed: () => Navigator.pop(context), // Quay lại đăng nhập
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Text("TẠO TÀI KHOẢN", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber)),
              const SizedBox(height: 10),
              const Text("Tham gia mạng xã hội Locket", style: TextStyle(color: Colors.white70)),
              
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: Colors.amber),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                  prefixIcon: Icon(Icons.email, color: Colors.white),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Mật khẩu",
                  labelStyle: TextStyle(color: Colors.amber),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                  prefixIcon: Icon(Icons.lock, color: Colors.white),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),

              _isLoading 
              ? const CircularProgressIndicator(color: Colors.amber)
              : SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                    onPressed: _register,
                    child: const Text("ĐĂNG KÝ NGAY", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}