import 'package:flutter/material.dart';

// ==========================================
// APP UTILITIES & HELPERS
// ==========================================

/// Helper class for safe context operations across async gaps
class SafeContext {
  static Future<void> showSnackBar(
    BuildContext? context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) async {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          action: action,
          backgroundColor: Colors.grey[900],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  static Future<void> showErrorSnackBar(
    BuildContext? context,
    String message,
  ) => showSnackBar(
    context,
    message,
    duration: const Duration(seconds: 3),
  );

  static Future<void> navigate(
    BuildContext? context,
    Widget page,
  ) async {
    if (context != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }

  static Future<void> pop(BuildContext? context) async {
    if (context != null && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

// ==========================================
// FORM VALIDATORS
// ==========================================

class FormValidators {
  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Email không được để trống';
    }
    if (!value!.contains('@')) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Mật khẩu không được để trống';
    }
    if ((value?.length ?? 0) < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Tên người dùng không được để trống';
    }
    if ((value?.length ?? 0) < 3) {
      return 'Tên phải có ít nhất 3 ký tự';
    }
    if ((value?.length ?? 0) > 30) {
      return 'Tên không được vượt quá 30 ký tự';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Số điện thoại không được để trống';
    }
    if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value!)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  static String? validateBio(String? value) {
    if ((value?.length ?? 0) > 150) {
      return 'Bio không được vượt quá 150 ký tự';
    }
    return null;
  }
}

// ==========================================
// COMMON WIDGETS
// ==========================================

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            ),
          ),
      ],
    );
  }
}

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color startColor;
  final Color endColor;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.startColor = Colors.amber,
    this.endColor = const Color(0xFFFFB74D),
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.startColor, widget.endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}

// ==========================================
// DIALOG HELPERS
// ==========================================

class DialogHelpers {
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Đồng ý',
    String cancelText = 'Hủy',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText, style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          title,
          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// EXTENSION METHODS
// ==========================================

extension StringExt on String {
  bool get isValidEmail => contains('@') && contains('.');
  
  bool get isValidPhoneNumber => RegExp(r'^[0-9]{10,11}$').hasMatch(this);
  
  String get capitalize => isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

extension ListExt<T> on List<T> {
  List<T> paginate(int page, int pageSize) {
    final startIndex = page * pageSize;
    final endIndex = (page + 1) * pageSize;
    
    if (startIndex >= length) return [];
    return sublist(startIndex, endIndex.clamp(0, length));
  }
}
