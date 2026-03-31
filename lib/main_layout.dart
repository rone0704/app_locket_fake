import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'calendar_screen.dart';
import 'chat_list_screen.dart';
import 'gallery_screen.dart';

class MainLayout extends StatefulWidget {
  final int initialTab;
  final int initialHomeVerticalPage;
  final String? initialPostId;

  const MainLayout({
    super.key,
    this.initialTab = 1, // 0: Lịch, 1: Home(Camera/Feed), 2: Chat, 3: Gallery
    this.initialHomeVerticalPage = 0, // 0: Camera, 1: Feed
    this.initialPostId,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;
  late int _homeVerticalPage;
  late PageController _homePageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _homeVerticalPage = widget.initialHomeVerticalPage;
    _homePageController = PageController(initialPage: _homeVerticalPage);
  }

  @override
  void dispose() {
    _homePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;
    if (_currentIndex == 0) {
      currentScreen = const CalendarScreen();
    } else if (_currentIndex == 1) {
      currentScreen = HomeScreen(
        pageController: _homePageController,
        initialPostId: widget.initialPostId,
        onPageChanged: (page) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _homeVerticalPage != page) {
              setState(() => _homeVerticalPage = page);
            }
          });
        },
        onGoToChat: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _currentIndex = 2);
          });
        },
        onGoToGallery: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _currentIndex = 3);
          });
        },
        onOpenSettings: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
        },
      );
    } else if (_currentIndex == 2) {
      currentScreen = const ChatListScreen();
    } else {
      currentScreen = const GalleryScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              const CalendarScreen(), // Index 0
              
              HomeScreen(             // Index 1
                pageController: _homePageController,
                initialPostId: widget.initialPostId,
                onPageChanged: (page) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _homeVerticalPage != page) {
                      setState(() => _homeVerticalPage = page);
                    }
                  });
                },
                onGoToChat: () => setState(() => _currentIndex = 2),
                onGoToGallery: () => setState(() => _currentIndex = 3),
                onOpenSettings: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                },
              ),
              
              const ChatListScreen(), // Index 2
              const GalleryScreen(),  // Index 3
            ],
          ),
          
          Positioned(
            bottom: 30,
            child: _buildFloatingTaskbar(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTaskbar() {
    return SafeArea(
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. NÚT TRÁI (LỊCH)
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 0),
              child: Icon(
                Icons.calendar_month_rounded, 
                color: _currentIndex == 0 ? Colors.white : Colors.white70, 
                size: 28
              ),
            ),
            const SizedBox(width: 25),
            
            // 2. NÚT GIỮA (BIẾN HÌNH NGÔI NHÀ <-> CHỤP VÀNG)
            GestureDetector(
              onTap: () {
                if (_currentIndex != 1) {
                  // LOGIC MỚI: Nếu đang ở Chat/Lịch/Gallery -> Chỉ chuyển về tab Home. 
                  // Bộ nhớ IndexedStack sẽ tự động hiển thị lại đúng Camera hoặc Feed mà bạn đang xem dở!
                  setState(() => _currentIndex = 1);
                } else if (_homeVerticalPage == 1) {
                  // Đang ở ngay trang Home và đang lướt Feed -> Cuộn ngược lên Camera
                  _homePageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                }
              },
              child: (_currentIndex == 1 && _homeVerticalPage == 0)
                  // Đang ở Camera -> Hiện Ngôi Nhà
                  ? Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.15)),
                      child: const Center(child: Icon(Icons.home_filled, color: Colors.white, size: 28)),
                    )
                  // Đang ở tab khác hoặc đang ở Feed -> Hiện Nút Chụp Vàng
                  : Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.amber, width: 3.5), color: Colors.transparent),
                      child: Center(child: Container(width: 44, height: 44, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
                    ),
            ),
            const SizedBox(width: 25),
            
            // 3. NÚT PHẢI (CHAT)
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 2),
              child: Icon(
                Icons.chat_bubble_rounded, 
                color: _currentIndex == 2 ? Colors.white : Colors.white70, 
                size: 28
              ),
            ),
          ],
        ),
      ),
    );
  }
}