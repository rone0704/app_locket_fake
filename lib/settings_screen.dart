import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'notification_screen.dart';
import 'locket_gold_screen.dart';
import 'blocking_system.dart';
import 'debug_deeplink_screen.dart';
import 'app_theme_controller.dart';
import 'app_navigator.dart';
import 'welcome_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _chooseThemeMode(BuildContext context, bool hasGoldThemes) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppThemeController.themeMode,
          builder: (context, mode, _) {
            return ValueListenableBuilder<DarkPalette>(
              valueListenable: AppThemeController.darkPalette,
              builder: (context, palette, unusedValue) {
                Widget option(ThemeMode value, IconData icon, String label) {
                  final selected = mode == value;
                  return ListTile(
                    leading: Icon(icon, color: selected ? Colors.amber : Colors.white70),
                    title: Text(
                      label,
                      style: TextStyle(
                        color: selected ? Colors.amber : Colors.white,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_circle_rounded, color: Colors.amber)
                        : null,
                    onTap: () async {
                      await AppThemeController.setThemeMode(value);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                  );
                }

                Widget paletteOption(
                  DarkPalette value,
                  Color swatch,
                  String subtitle,
                ) {
                  final selected = palette == value;
                  return ListTile(
                    leading: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: swatch,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                    title: Text(
                      AppThemeController.labelOfPalette(value),
                      style: TextStyle(
                        color: selected ? Colors.amber : Colors.white,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_circle_rounded, color: Colors.amber)
                        : null,
                    onTap: hasGoldThemes
                        ? () async {
                            await AppThemeController.setThemeMode(ThemeMode.dark);
                            await AppThemeController.setDarkPalette(value);
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nâng cấp Locket Gold để mở khóa Dark Mode nâng cao'),
                              ),
                            );
                          },
                  );
                }

                return SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                    ),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(sheetContext).size.height * 0.84,
                      ),
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15181D),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'Chọn chế độ giao diện',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          option(ThemeMode.system, Icons.auto_mode_rounded, 'Tự động'),
                          option(ThemeMode.dark, Icons.dark_mode_rounded, 'Tối'),
                          option(ThemeMode.light, Icons.light_mode_rounded, 'Sáng'),
                          const Divider(color: Colors.white12, height: 1),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Dark Mode Nâng Cao (Gold)',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          paletteOption(
                            DarkPalette.midnight,
                            const Color(0xFF070809),
                            'Đen xì OLED',
                          ),
                          paletteOption(
                            DarkPalette.deepSea,
                            const Color(0xFF0E1D2B),
                            'Xanh dương cực đậm',
                          ),
                          paletteOption(
                            DarkPalette.spaceGray,
                            const Color(0xFF23262D),
                            'Xám không gian',
                          ),
                          paletteOption(
                            DarkPalette.amethyst,
                            const Color(0xFF261D33),
                            'Tím đen huyền bí',
                          ),
                          paletteOption(
                            DarkPalette.obsidianGreen,
                            const Color(0xFF16291F),
                            'Xanh lục obsidian',
                          ),
                          paletteOption(
                            DarkPalette.carbonRed,
                            const Color(0xFF2A181B),
                            'Đỏ carbon trầm',
                          ),
                          paletteOption(
                            DarkPalette.arcticDark,
                            const Color(0xFF1C2632),
                            'Xanh bắc cực lạnh',
                          ),
                          paletteOption(
                            DarkPalette.nebulaBrown,
                            const Color(0xFF2A221C),
                            'Nâu đen ngân hà',
                          ),
                          if (!hasGoldThemes)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_rounded, color: Colors.white54, size: 16),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      'Bạn cần Gold còn hạn để dùng các palette nâng cao',
                                      style: TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(sheetContext);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const LocketGoldScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text('Nâng cấp'),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- HÀM ĐỔI MẬT KHẨU ---
  void _changePassword(BuildContext context) {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    bool showCurrentPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Đổi mật khẩu",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current Password
                TextField(
                  controller: currentPasswordController,
                  obscureText: !showCurrentPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Mật khẩu hiện tại",
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: "Nhập mật khẩu hiện tại",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.grey[800],
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.amber,
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(
                        () => showCurrentPassword = !showCurrentPassword,
                      ),
                      child: Icon(
                        showCurrentPassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: Colors.amber,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // New Password
                TextField(
                  controller: newPasswordController,
                  obscureText: !showNewPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Mật khẩu mới",
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: "Tối thiểu 6 ký tự",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.grey[800],
                    prefixIcon: const Icon(
                      Icons.lock_rounded,
                      color: Colors.amber,
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () =>
                          setState(() => showNewPassword = !showNewPassword),
                      child: Icon(
                        showNewPassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: Colors.amber,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !showConfirmPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Xác nhận mật khẩu",
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: "Nhập lại mật khẩu mới",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.grey[800],
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.amber,
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(
                        () => showConfirmPassword = !showConfirmPassword,
                      ),
                      child: Icon(
                        showConfirmPassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: Colors.amber,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text("Hủy", style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final currentPassword = currentPasswordController.text
                          .trim();
                      final newPassword = newPasswordController.text.trim();
                      final confirmPassword = confirmPasswordController.text
                          .trim();

                      if (currentPassword.isEmpty ||
                          newPassword.isEmpty ||
                          confirmPassword.isEmpty) {
                        _showPasswordErrorSnackBar(
                          "Vui lòng điền đủ thông tin",
                        );
                        return;
                      }

                      if (newPassword != confirmPassword) {
                        _showPasswordErrorSnackBar(
                          "Mật khẩu mới không trùng khớp",
                        );
                        return;
                      }

                      if (newPassword.length < 6) {
                        _showPasswordErrorSnackBar(
                          "Mật khẩu phải có ít nhất 6 ký tự",
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          throw FirebaseAuthException(
                            code: 'user-not-found',
                            message: 'Không tìm thấy người dùng',
                          );
                        }

                        // Reauthenticate
                        final credentials = EmailAuthProvider.credential(
                          email: user.email!,
                          password: currentPassword,
                        );
                        await user.reauthenticateWithCredential(credentials);

                        // Update password
                        await user.updatePassword(newPassword);

                        if (context.mounted) {
                          Navigator.pop(context);
                          _showPasswordSuccessSnackBar(
                            "Mật khẩu đã được thay đổi thành công",
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        String message = "Đã có lỗi xảy ra";
                        if (e.code == 'wrong-password') {
                          message = "Mật khẩu hiện tại không chính xác";
                        } else if (e.code == 'weak-password') {
                          message = "Mật khẩu mới quá yếu";
                        } else if (e.code == 'user-not-found') {
                          message = "Người dùng không tồn tại";
                        }
                        if (context.mounted) {
                          _showPasswordErrorSnackBar(message);
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Lưu",
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordErrorSnackBar(String message) {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showPasswordSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // --- HÀM CHỈNH SỬA TÊN ---
  void _editName(BuildContext context, String currentName, String uid) {
    TextEditingController nameController = TextEditingController(
      text: currentName,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Đổi tên hiển thị",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          enableInteractiveSelection: false,
          cursorColor: Colors.amber,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Nhập tên mới...",
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.amber, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'displayName': nameController.text.trim()});
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text(
              "Lưu",
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HÀM ĐĂNG XUẤT ---
  void _signOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Đăng xuất?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Bạn có chắc muốn thoát tài khoản không?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                appNavigatorKey.currentState?.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => WelcomeScreen(
                      onFinished: () {
                        appNavigatorKey.currentState?.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                  (route) => false,
                );
              } catch (e) {
                if (!mounted) return;
                _showPasswordErrorSnackBar('Dang xuat that bai: $e');
              }
            },
            child: const Text(
              "Đăng xuất",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final passwordController = TextEditingController();
    bool isLoading = false;

    Future<void> performDelete(StateSetter setSheetState) async {
      final password = passwordController.text.trim();
      if (password.isEmpty) {
        _showPasswordErrorSnackBar('Vui lòng nhập mật khẩu để xác nhận');
        return;
      }

      setSheetState(() {
        isLoading = true;
      });

      try {
        if (user.email == null || user.email!.isEmpty) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Không tìm thấy email của tài khoản',
          );
        }

        final credentials = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credentials);

        final postsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (final doc in postsSnapshot.docs) {
          final data = doc.data();
          final imageUrl = data['imageUrl']?.toString().trim() ?? '';

          if (imageUrl.isNotEmpty && !imageUrl.startsWith('data:image/')) {
            try {
              await FirebaseStorage.instance.refFromURL(imageUrl).delete();
            } catch (_) {
              // Best-effort cleanup; continue deleting account data.
            }
          }

          await doc.reference.delete();
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        await user.delete();
        await FirebaseAuth.instance.signOut();

        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      } on FirebaseAuthException catch (e) {
        String message = 'Không thể xóa tài khoản';
        if (e.code == 'wrong-password') {
          message = 'Mật khẩu không chính xác';
        } else if (e.code == 'requires-recent-login') {
          message = 'Cần đăng nhập lại trước khi xóa tài khoản';
        } else if (e.code == 'user-not-found') {
          message = 'Không tìm thấy tài khoản';
        }

        if (context.mounted) {
          setSheetState(() {
            isLoading = false;
          });
          _showPasswordErrorSnackBar(message);
        }
      } catch (e) {
        if (context.mounted) {
          setSheetState(() {
            isLoading = false;
          });
          _showPasswordErrorSnackBar('Xóa tài khoản thất bại: $e');
        }
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Xóa tài khoản?',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thao tác này sẽ xóa vĩnh viễn tài khoản, bài viết và dữ liệu hồ sơ của bạn.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    enabled: !isLoading,
                    cursorColor: Colors.redAccent,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nhập mật khẩu để xác nhận',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: isLoading ? null : () async => performDelete(setSheetState),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                          ),
                        )
                      : const Text(
                          'Xóa',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- HÀM QUẢN LÝ LOCKET GOLD ---
  void _showGoldMemberMenu(BuildContext context, bool isExpired, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Locket Gold",
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isExpired
              ? "Gói Gold của bạn đã hết hạn. Hãy gia hạn để tiếp tục sử dụng các tính năng premium!"
              : "Bạn đang sử dụng Locket Gold. Hãy gia hạn trước khi hết hạn!",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Xóa Gold membership
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({
                    'isGoldMember': false,
                    'goldMemberExpiryDate': null,
                  });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("❌ Đã hủy Locket Gold"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text(
              "Hủy Gold",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!isExpired)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocketGoldScreen(),
                  ),
                );
              },
              child: const Text(
                "Gia hạn",
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final titleColor = Theme.of(context).colorScheme.onSurface;
    final sectionColor = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.color
        ?.withValues(alpha: 0.85);

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: scaffoldColor,
        appBar: AppBar(
          title: Text(
            "Cài đặt",
            style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
          ),
          backgroundColor: scaffoldColor,
          foregroundColor: titleColor,
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: Text(
          "Cài đặt",
          style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
        ),
        backgroundColor: scaffoldColor,
        foregroundColor: titleColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Khong the tai du lieu cai dat',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>?;
          String email = data?['email'] ?? currentUser.email ?? "";
          String displayName = data?['displayName'] ?? email.split('@')[0];
          String? avatarUrl = data?['avatarUrl'];
            final bool isGoldMember = data?['isGoldMember'] == true;
            final DateTime? goldExpiry = data?['goldMemberExpiryDate']?.toDate();
            final bool hasGoldThemes =
              isGoldMember && goldExpiry != null && DateTime.now().isBefore(goldExpiry);
          String username = "@${email.split('@')[0]}";
          String avatarChar = displayName.isNotEmpty
              ? displayName[0].toUpperCase()
              : "A";

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              const SizedBox(height: 20),

              // --- AVATAR & THÔNG TIN ---
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              avatarChar,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      username,
                      style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- LOCKET GOLD SECTION ---
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final colorScheme = Theme.of(context).colorScheme;
                  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

                  var userData = snapshot.data!.data() as Map<String, dynamic>?;
                  bool isGoldMember = userData?['isGoldMember'] ?? false;
                  DateTime? expiryDate = userData?['goldMemberExpiryDate']
                      ?.toDate();

                  if (isGoldMember && expiryDate != null) {
                    String expiryDateFormatted =
                        "${expiryDate.day}/${expiryDate.month}/${expiryDate.year}";
                    bool isExpired = DateTime.now().isAfter(expiryDate);

                    return Container(
                      decoration: BoxDecoration(
                        color: isExpired
                            ? colorScheme.errorContainer.withValues(
                                alpha: isDarkMode ? 0.34 : 0.72,
                              )
                            : colorScheme.primaryContainer.withValues(
                                alpha: isDarkMode ? 0.34 : 0.80,
                              ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isExpired
                              ? colorScheme.error
                              : colorScheme.primary.withValues(
                                  alpha: isDarkMode ? 1 : 0.92,
                                ),
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isExpired
                              ? Icons.star_outline_rounded
                              : Icons.star_rounded,
                          color: isExpired
                              ? colorScheme.error
                              : colorScheme.onPrimaryContainer,
                        ),
                        title: Text(
                          isExpired
                              ? "Locket Gold đã hết hạn"
                              : "✨ Locket Gold Active",
                          style: TextStyle(
                            color: isExpired
                                ? colorScheme.onErrorContainer
                                : colorScheme.onPrimaryContainer,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          isExpired
                              ? "Hết hạn: $expiryDateFormatted"
                              : "Hết hạn: $expiryDateFormatted",
                          style: TextStyle(
                            color: isExpired
                                ? colorScheme.onErrorContainer.withValues(alpha: 0.82)
                                : colorScheme.onPrimaryContainer.withValues(alpha: 0.82),
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: isExpired
                              ? colorScheme.error
                              : colorScheme.onPrimaryContainer,
                        ),
                        onTap: () {
                          _showGoldMemberMenu(
                            context,
                            isExpired,
                            currentUser.uid,
                          );
                        },
                      ),
                    );
                  }

                  // Chưa subscribe Gold
                  return Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: isDarkMode ? 0.34 : 0.80,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: colorScheme.primary.withValues(
                          alpha: isDarkMode ? 1 : 0.92,
                        ),
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.star_rounded,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      title: Text(
                        "Đăng ký Locket Gold",
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Mở khóa tính năng cao cấp",
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.82),
                          fontSize: 12,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LocketGoldScreen(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),
              Text(
                "TÀI KHOẢN",
                style: TextStyle(
                  color: sectionColor ?? Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              // --- SỬA TÊN / EMAIL ---
              _buildMenuTile(
                icon: Icons.edit_rounded,
                title: "Sửa tên, email",
                color: Colors.white,
                onTap: () => _editName(context, displayName, currentUser.uid),
              ),

              ValueListenableBuilder<ThemeMode>(
                valueListenable: AppThemeController.themeMode,
                builder: (context, mode, _) {
                  return ValueListenableBuilder<DarkPalette>(
                    valueListenable: AppThemeController.darkPalette,
                    builder: (context, palette, unusedValue) {
                      final modeLabel = AppThemeController.labelOf(mode);
                      final paletteLabel = AppThemeController.labelOfPalette(palette);
                      return _buildMenuTile(
                        icon: Icons.palette_rounded,
                        title: mode == ThemeMode.dark
                            ? "Giao diện: $modeLabel · $paletteLabel"
                            : "Giao diện: $modeLabel",
                        color: Colors.amber,
                        onTap: () => _chooseThemeMode(context, hasGoldThemes),
                      );
                    },
                  );
                },
              ),

              // --- ĐỔI MẬT KHẨU ---
              _buildMenuTile(
                icon: Icons.lock_rounded,
                title: "Đổi mật khẩu",
                color: Colors.cyan,
                onTap: () => _changePassword(context),
              ),

              // --- THÔNG BÁO ---
              _buildMenuTile(
                icon: Icons.notifications_rounded,
                title: "Thông báo",
                color: Colors.white,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
              ),

              // --- NGƯỜI DÙNG BỊ CHẶN ---
              _buildMenuTile(
                icon: Icons.block,
                title: "Người dùng bị chặn",
                color: Colors.redAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BlockedUsersScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),
              Text(
                "HỖ TRỢ & PHẢN HỒI",
                style: TextStyle(
                  color: sectionColor ?? Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              // --- HỖ TRỢ ---
              _buildMenuTile(
                icon: Icons.help_outline_rounded,
                title: "Hỗ trợ",
                color: Colors.white,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Chức năng hỗ trợ đang phát triển!"),
                    ),
                  );
                },
              ),

              // --- BÁO CÁO SỰ CỐ ---
              _buildMenuTile(
                icon: Icons.report_problem_rounded,
                title: "Báo cáo sự cố",
                color: Colors.orangeAccent,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cảm ơn bạn đã báo cáo!")),
                  );
                },
              ),

              // --- GỬI ĐỀ XUẤT ---
              _buildMenuTile(
                icon: Icons.lightbulb_outline_rounded,
                title: "Gửi đề xuất",
                color: Colors.blueAccent,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cảm ơn bạn đã gửi đề xuất!")),
                  );
                },
              ),

              _buildMenuTile(
                icon: Icons.bug_report_rounded,
                title: "Debug deeplink",
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DebugDeepLinkScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),

              // --- ĐĂNG XUẤT ---
              _buildMenuTile(
                icon: Icons.logout_rounded,
                title: "Đăng xuất",
                color: Colors.redAccent,
                onTap: () => _signOut(context),
              ),

              _buildMenuTile(
                icon: Icons.delete_forever_rounded,
                title: "Xóa tài khoản",
                color: Colors.red,
                onTap: () => _deleteAccount(context),
              ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  // --- HÀM TẠO MENU TILE ---
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required Color color,
    VoidCallback? onTap,
  }) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final mutedIconColor = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.color
        ?.withValues(alpha: 0.5);
    final bool isWhiteLabel = color == Colors.white;
    final titleColor = isWhiteLabel ? onSurface : color;
    final iconColor = isWhiteLabel ? onSurface.withValues(alpha: 0.85) : color;
    final iconBgColor = isWhiteLabel
        ? onSurface.withValues(alpha: 0.10)
        : color.withValues(alpha: 0.2);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: mutedIconColor ?? Colors.white24,
          size: 20,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
    );
  }
}
