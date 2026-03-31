import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'modern_ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _successMessage;

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorSnackBar("Vui lòng nhập email của bạn");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      if (mounted) {
        setState(() {
          _emailSent = true;
          _successMessage = "Hướng dẫn đặt lại mật khẩu đã được gửi đến $email";
        });
      }
    } on FirebaseAuthException catch (e) {
      String message = "Đã có lỗi xảy ra";
      
      if (e.code == 'user-not-found') {
        message = "Email này chưa được đăng ký";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ModernHeader(
              title: "Đặt lại mật khẩu",
              subtitle: "Nhập email của bạn để nhận liên kết đặt lại mật khẩu",
              icon: Icons.lock_reset_rounded,
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: !_emailSent
                  ? Column(
                      children: [
                        const SizedBox(height: 20),
                        ModernTextField(
                          label: "Email",
                          hintText: "Nhập email của bạn",
                          controller: _emailController,
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 28),
                        ModernGradientButton(
                          label: _isLoading
                              ? "ĐANG GỬI LIÊN KẾT..."
                              : "GỬI LIÊN KẾT ĐẶT LẠI",
                          onPressed: _isLoading ? () {} : _resetPassword,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 18),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "QUAY LẠI ĐĂNG NHẬP",
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.withValues(alpha: 0.16),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.8),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 56,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          "Kiểm tra email của bạn",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _successMessage ?? "",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ModernGradientButton(
                          label: "QUAY LẠI ĐĂNG NHẬP",
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
