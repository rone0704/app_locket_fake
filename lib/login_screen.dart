import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'modern_ui.dart';
import 'main_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'biometric_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isBiometricLoading = false;
  bool _rememberMe = false;
  bool _showPassword = false;
  bool _enableBiometric = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _attemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _prepareBiometricState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_emailFocus);
      }
    });
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (mounted && savedEmail != null && rememberMe) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_email', _emailController.text.trim());
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('saved_email');
        await prefs.setBool('remember_me', false);
      }
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  Future<void> _prepareBiometricState() async {
    final available = await BiometricAuthService.isAvailable();
    final enabled = await BiometricAuthService.isEnabled();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _enableBiometric = enabled;
    });
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Vui lòng nhập email';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) return 'Email không hợp lệ';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (password.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _attemptedSubmit = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showErrorSnackBar('Vui lòng kiểm tra lại email và mật khẩu');
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _saveCredentials();
      if (_biometricAvailable) {
        if (_enableBiometric) {
          await BiometricAuthService.saveCredential(
            email: email,
            password: password,
          );
          await BiometricAuthService.setEnabled(true);
          _biometricEnabled = true;
        } else if (_biometricEnabled) {
          await BiometricAuthService.clearCredential();
          await BiometricAuthService.setEnabled(false);
          _biometricEnabled = false;
        }
      }

      _goToMainLayout();
    } on FirebaseAuthException catch (e) {
      String message = 'Đã có lỗi xảy ra';
      if (e.code == 'user-not-found') {
        message = 'Email này chưa được đăng ký';
      } else if (e.code == 'wrong-password') {
        message = 'Mật khẩu không chính xác';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ';
      } else if (e.code == 'user-disabled') {
        message = 'Tài khoản này đã bị vô hiệu hóa';
      }

      if (mounted) {
        _showErrorSnackBar(message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isGoogleLoading || _isLoading || _isBiometricLoading) return;
    setState(() => _isGoogleLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      await _ensureUserProfile(userCred.user);
      _goToMainLayout();
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar('Google login lỗi: ${e.message ?? e.code}');
    } catch (e) {
      _showErrorSnackBar('Không thể đăng nhập Google: $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _loginWithBiometric() async {
    if (_isBiometricLoading || _isLoading || _isGoogleLoading) return;
    if (!_biometricAvailable) {
      final reason = await BiometricAuthService.getUnavailableReason();
      _showErrorSnackBar(reason ?? 'Thiết bị chưa hỗ trợ đăng nhập sinh trắc học');
      return;
    }

    final enabled = await BiometricAuthService.isEnabled();
    if (!enabled) {
      _showErrorSnackBar('Bạn chưa bật đăng nhập khuôn mặt');
      return;
    }

    final cred = await BiometricAuthService.readCredential();
    if (cred == null) {
      _showErrorSnackBar('Chưa có phiên khuôn mặt. Hãy login thường trước.');
      return;
    }

    setState(() => _isBiometricLoading = true);
    try {
      final ok = await BiometricAuthService.authenticate();
      if (!ok) return;
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: cred['email']!,
        password: cred['password']!,
      );
      _goToMainLayout();
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar('Đăng nhập khuôn mặt lỗi: ${e.message ?? e.code}');
    } catch (e) {
      _showErrorSnackBar('Không thể đăng nhập khuôn mặt: $e');
    } finally {
      if (mounted) setState(() => _isBiometricLoading = false);
    }
  }

  void _goToMainLayout() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainLayout()),
      (route) => false,
    );
  }

  Future<void> _ensureUserProfile(User? user) async {
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await ref.get();
    if (doc.exists) return;
    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? (user.email?.split('@').first ?? 'user'),
      'avatarUrl': user.photoURL,
      'friendRequests': <String>[],
      'friends': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
            // Modern Header
            ModernHeader(
              title: "Chào mừng trở lại",
              subtitle: "Đăng nhập để khám phá những khoảnh khắc từ bạn bè",
              icon: Icons.photo_camera_back,
            ),
            
            // Login Form
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
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
                    child: TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      autovalidateMode: _attemptedSubmit
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      onChanged: (_) {
                        if (_attemptedSubmit) {
                          _formKey.currentState?.validate();
                        }
                      },
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocus);
                      },
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
                    child: TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
                      autovalidateMode: _attemptedSubmit
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      onChanged: (_) {
                        if (_attemptedSubmit) {
                          _formKey.currentState?.validate();
                        }
                      },
                      onFieldSubmitted: (_) => _login(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "Nhập mật khẩu",
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
                  
                  const SizedBox(height: 16),
                  
                  // Remember Me & Forgot Password
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _rememberMe = !_rememberMe),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _rememberMe ? Colors.amber : Colors.white30,
                                          width: 2,
                                        ),
                                        color: _rememberMe
                                            ? Colors.amber
                                            : Colors.transparent,
                                      ),
                                      child: _rememberMe
                                          ? const Icon(Icons.check_rounded,
                                              color: Colors.black, size: 16)
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      "Nhớ tôi",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (!_biometricAvailable) {
                                  BiometricAuthService.getUnavailableReason().then((reason) {
                                    if (!mounted) return;
                                    _showErrorSnackBar(
                                      reason ?? 'Thiết bị chưa hỗ trợ trắc sinh học',
                                    );
                                  });
                                  return;
                                }
                                setState(() => _enableBiometric = !_enableBiometric);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _biometricAvailable
                                      ? Colors.transparent
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.face_rounded,
                                      color: _biometricAvailable
                                          ? (_enableBiometric
                                                ? Colors.amber
                                                : Colors.white54)
                                          : Colors.white54,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Khuôn mặt',
                                      style: TextStyle(
                                        color: _biometricAvailable
                                            ? (_enableBiometric
                                                  ? Colors.amber
                                                  : Colors.white70)
                                            : Colors.white60,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (!_biometricAvailable) ...[
                                      const SizedBox(width: 3),
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        color: Colors.white60,
                                        size: 14,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: const Text(
                            "Quên mật khẩu?",
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _login(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        disabledBackgroundColor: Colors.amber.withValues(alpha: 0.6),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Text(
                              "ĐĂNG NHẬP",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  Text(
                    'Hoặc đăng nhập bằng',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: (_isGoogleLoading || _isLoading)
                            ? null
                            : _loginWithGoogle,
                        icon: _isGoogleLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.g_mobiledata_rounded, size: 24),
                        label: const Text('Google'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: (_isBiometricLoading || _isLoading)
                            ? null
                            : _loginWithBiometric,
                        icon: _isBiometricLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.face_rounded, size: 20),
                        label: const Text('Khuôn mặt'),
                      ),
                    ],
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
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.amber, width: 2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_add_rounded, color: Colors.amber),
                          const SizedBox(width: 12),
                          const Text(
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
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
}