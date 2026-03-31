import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'forgot_password_screen.dart';
import 'main_layout.dart';
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _rememberMe = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // Validation
    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar("Vui lòng điền đủ thông tin");
      return;
    }

    if (!_isLogin && name.isEmpty) {
      _showErrorSnackBar("Vui lòng nhập tên hiển thị");
      return;
    }

    if (!_isLogin && password != _confirmPasswordController.text.trim()) {
      _showErrorSnackBar("Mật khẩu không trùng khớp");
      return;
    }

    if (!_isLogin && password.length < 6) {
      _showErrorSnackBar("Mật khẩu phải có ít nhất 6 ký tự");
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // ĐĂNG NHẬP
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // ĐĂNG KÝ
        UserCredential userCred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Tạo profile mặc định trên Firestore cho User mới
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCred.user!.uid)
            .set({
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
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const MainLayout()));
      }
    } on FirebaseAuthException catch (e) {
      String message = "Đã có lỗi xảy ra";
      if (e.code == 'user-not-found') {
        message = "Email này chưa được đăng ký";
      } else if (e.code == 'wrong-password') {
        message = "Mật khẩu không chính xác";
      } else if (e.code == 'email-already-in-use') {
        message = "Email này đã được đăng ký";
      } else if (e.code == 'weak-password') {
        message = "Mật khẩu quá yếu";
      } else if (e.code == 'invalid-email') {
        message = "Email không hợp lệ";
      }

      if (mounted) {
        _showErrorSnackBar(message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // --- LOGO & HEADER ---
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.amber, Colors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.photo_camera_back,
                      color: Colors.black,
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  "Locket",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  _isLogin
                      ? "Chào mừng trở lại"
                      : "Tham gia Locket",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  _isLogin
                      ? "Đạng nhập địa chỉ email của bạn"
                      : "Tạo tài khoản để chia sẻ những khoảnh khắc",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),

                // --- FORM FIELDS ---
                if (!_isLogin)
                  Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: "Tên hiển thị",
                        hint: "Nhập tên của bạn",
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                _buildTextField(
                  controller: _emailController,
                  label: "Email",
                  hint: "Nhập email",
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _buildPasswordField(
                  controller: _passwordController,
                  label: "Mật khẩu",
                  hint: _isLogin ? "Nhập mật khẩu" : "Tối thiểu 6 ký tự",
                  showPassword: _showPassword,
                  onShowPasswordChanged: (value) =>
                      setState(() => _showPassword = value),
                ),
                const SizedBox(height: 16),

                if (!_isLogin)
                  Column(
                    children: [
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: "Xác nhận mật khẩu",
                        hint: "Nhập lại mật khẩu",
                        showPassword: _showConfirmPassword,
                        onShowPasswordChanged: (value) =>
                            setState(() => _showConfirmPassword = value),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                if (_isLogin)
                  Column(
                    children: [
                      // Remember Me
                      GestureDetector(
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color:
                                      _rememberMe ? Colors.amber : Colors.white30,
                                  width: 2,
                                ),
                                color: _rememberMe
                                    ? Colors.amber
                                    : Colors.transparent,
                              ),
                              child: _rememberMe
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.black, size: 14)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Nhớ tôi",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Quên mật khẩu?",
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                // --- SUBMIT BUTTON ---
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? () {} : _submitAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isLogin ? "ĐĂNG NHẬP" : "ĐĂNG KÝ",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- TOGGLE LOGIN/SIGNUP ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? "Chưa có tài khoản? "
                          : "Đã có tài khoản? ",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _isLogin = !_isLogin);
                        _emailController.clear();
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                        _nameController.clear();
                      },
                      child: Text(
                        _isLogin ? "Đăng ký" : "Đăng nhập",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.grey[900],
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          prefixIcon: Icon(icon, color: Colors.amber),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.amber, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool showPassword,
    required Function(bool) onShowPasswordChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: !showPassword,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.grey[900],
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          prefixIcon: const Icon(Icons.lock_rounded, color: Colors.amber),
          suffixIcon: GestureDetector(
            onTap: () => onShowPasswordChanged(!showPassword),
            child: Icon(
              showPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: Colors.amber,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.amber, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}