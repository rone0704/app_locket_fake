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
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _agreeToTerms = false;

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showErrorSnackBar("Vui lòng điền đủ thông tin");
      return;
    }

    if (password != confirmPassword) {
      _showErrorSnackBar("Mật khẩu không trùng khớp");
      return;
    }

    if (password.length < 6) {
      _showErrorSnackBar("Mật khẩu phải có ít nhất 6 ký tự");
      return;
    }

    if (!_agreeToTerms) {
      _showErrorSnackBar("Vui lòng chấp nhận điều khoản và chính sách bảo mật");
      return;
    }

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

  Future<void> _showTermsAndPolicySheet() async {
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Điều khoản dịch vụ & Chính sách bảo mật",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  child: SingleChildScrollView(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.55,
                        ),
                        children: [
                          TextSpan(
                            text:
                                "1. Mục đích sử dụng:\nỨng dụng cung cấp dịch vụ chia sẻ ảnh và tương tác xã hội cho người dùng.\n\n",
                          ),
                          TextSpan(
                            text:
                                "2. Trách nhiệm tài khoản:\nBạn chịu trách nhiệm bảo mật thông tin đăng nhập và mọi hoạt động trên tài khoản của mình.\n\n",
                          ),
                          TextSpan(
                            text:
                                "3. Nội dung người dùng:\nBạn cam kết không đăng tải nội dung vi phạm pháp luật, xúc phạm, hoặc xâm phạm quyền riêng tư của người khác.\n\n",
                          ),
                          TextSpan(
                            text:
                                "4. Thu thập dữ liệu:\nChúng tôi có thể thu thập email, thông tin hồ sơ và dữ liệu sử dụng để cải thiện chất lượng dịch vụ.\n\n",
                          ),
                          TextSpan(
                            text:
                                "5. Bảo mật thông tin:\nDữ liệu cá nhân được bảo vệ theo chính sách bảo mật và chỉ dùng cho mục đích vận hành hệ thống.\n\n",
                          ),
                          TextSpan(
                            text:
                                "6. Chấm dứt dịch vụ:\nChúng tôi có quyền tạm khóa hoặc chấm dứt tài khoản nếu phát hiện hành vi vi phạm điều khoản.\n\n",
                          ),
                          TextSpan(
                            text:
                                "7. Cập nhật điều khoản:\nĐiều khoản có thể được cập nhật theo thời gian và sẽ có hiệu lực khi được công bố trên ứng dụng.",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text("Để sau"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text(
                          "Tôi đồng ý",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (mounted && accepted == true) {
      setState(() => _agreeToTerms = true);
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
                  compact: true,
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  child: Material(
                    color: Colors.grey[900],
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.amber,
                        ),
                      ),
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 6, bottom: 8),
                      child: Text(
                        'Email',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Container(
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
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "Nhập email của bạn",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.grey[900],
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        prefixIcon: const Icon(Icons.email_rounded, color: Colors.amber),
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
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Password Input with show/hide toggle
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 6, bottom: 8),
                      child: Text(
                        'Mật khẩu',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Container(
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
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "Tối thiểu 6 ký tự",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.grey[900],
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        prefixIcon: const Icon(Icons.lock_rounded, color: Colors.amber),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _showPassword = !_showPassword),
                          child: Icon(
                            _showPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
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
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Confirm Password Input
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 6, bottom: 8),
                      child: Text(
                        'Xác nhận mật khẩu',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Container(
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
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "Nhập lại mật khẩu",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.grey[900],
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.amber),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                          child: Icon(
                            _showConfirmPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
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
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Terms & Conditions Checkbox
                  GestureDetector(
                    onTap: () async {
                      if (_agreeToTerms) {
                        setState(() => _agreeToTerms = false);
                        return;
                      }
                      await _showTermsAndPolicySheet();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[900],
                        border: Border.all(
                          color: _agreeToTerms ? Colors.amber : Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _agreeToTerms ? Colors.amber : Colors.white30,
                                width: 2,
                              ),
                              color: _agreeToTerms
                                  ? Colors.amber
                                  : Colors.transparent,
                            ),
                            child: _agreeToTerms
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.black, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                children: [
                                  const TextSpan(text: "Tôi đồng ý với "),
                                  TextSpan(
                                    text: "Điều khoản dịch vụ",
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const TextSpan(text: " và "),
                                  TextSpan(
                                    text: "Chính sách bảo mật",
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white30, width: 1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login_rounded, color: Colors.white70),
                          const SizedBox(width: 12),
                          const Text(
                            "QUAY LẠI ĐĂNG NHẬP",
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}