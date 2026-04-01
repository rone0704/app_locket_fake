import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const WelcomeScreen({
    super.key,
    required this.onFinished,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const int _welcomeVersion = 2;
  final PageController _pageController = PageController();
  late final AnimationController _ambientController;
  int _currentIndex = 0;

  final List<_WelcomeItem> _items = const [
    _WelcomeItem(
      icon: Icons.photo_camera_back_rounded,
      title: 'Chia sẻ khoảnh khắc',
      subtitle: 'Đăng ảnh nhanh với bạn bè chỉ trong vài giây.',
    ),
    _WelcomeItem(
      icon: Icons.lock_rounded,
      title: 'Riêng tư an toàn',
      subtitle: 'Bạn kiểm soát ai có thể xem và tương tác với nội dung.',
    ),
    _WelcomeItem(
      icon: Icons.auto_awesome_rounded,
      title: 'Trải nghiệm mượt mà',
      subtitle: 'Giao diện hiện đại, nhanh và dễ dùng trên mọi thiết bị.',
    ),
  ];

  Future<void> _finishWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('welcome_version_seen', _welcomeVersion);
    await prefs.setBool('seen_welcome', true);
    if (!mounted) return;
    widget.onFinished();
  }

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
  }

  void _nextOrFinish() {
    if (_currentIndex == _items.length - 1) {
      _finishWelcome();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        final t = _ambientController.value;
        final y1 = -180 + (t * 54);
        final y2 = 170 - (t * 62);
        final x1 = -80 + (t * 36);
        final x2 = 210 - (t * 42);

        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0B0B0D),
                    Color(0xFF121316),
                    Color(0xFF0A0A0A),
                  ],
                ),
              ),
            ),
            Positioned(
              left: x1,
              top: y1,
              child: Container(
                width: 290,
                height: 290,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.18),
                      blurRadius: 120,
                      spreadRadius: 24,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: x2,
              bottom: y2,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 0.08),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.14),
                      blurRadius: 110,
                      spreadRadius: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPage(_WelcomeItem item, int index) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pageController, _ambientController]),
      builder: (context, child) {
        double page = _currentIndex.toDouble();
        if (_pageController.hasClients) {
          page = _pageController.page ?? _currentIndex.toDouble();
        }

        final distance = (page - index).abs().clamp(0.0, 1.0);
        final contentScale = 1 - (distance * 0.06);
        final contentOpacity = 1 - (distance * 0.45);
        final contentShiftX = (page - index) * 26;
        final pulse = 0.96 + (_ambientController.value * 0.08);

        return Opacity(
          opacity: contentOpacity,
          child: Transform.translate(
            offset: Offset(contentShiftX, 0),
            child: Transform.scale(
              scale: contentScale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: pulse,
                    child: Container(
                      width: 122,
                      height: 122,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.amber.withValues(alpha: 0.3),
                            Colors.orange.withValues(alpha: 0.16),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.36),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.25),
                            blurRadius: 28,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        item.icon,
                        color: Colors.amber,
                        size: 54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.45,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      item.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        letterSpacing: 0.1,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _finishWelcome,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      child: const Text('Bỏ qua'),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _buildPage(item, index);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_items.length, (index) {
                      final isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.amber : Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextOrFinish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentIndex == _items.length - 1
                                ? 'BẮT ĐẦU'
                                : 'TIẾP TỤC',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
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
    );
  }
}

class _WelcomeItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _WelcomeItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}