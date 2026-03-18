import 'package:flutter/material.dart';
import 'home_screen.dart'; 
import 'calendar_screen.dart'; 
import 'settings_screen.dart';
import 'explore_screen.dart';
import 'saved_posts_system.dart';
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Mặc định mở app lên là ở nút Giữa (số 1: Camera)
  int _currentIndex = 1;

  // Danh sách 3 màn hình tương ứng với 3 nút
  final List<Widget> _screens = [
    const SettingsScreen(),
    
    const HomeScreen(), 
    
    // Tab 2 (Nút bên phải): Tôi đang gắn tạm cái Lịch vào đây nhé, ông có thể đổi sau
    const CalendarScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true, 
      drawer: _buildDrawer(),
      body: _screens[_currentIndex],
      
      bottomNavigationBar: _buildFloatingTaskbar(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.menu_rounded, color: Colors.amber, size: 32),
                SizedBox(height: 16),
                Text(
                  "Locket Clone",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.explore, color: Colors.amber),
            title: const Text("Khám phá", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExploreScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark, color: Colors.amber),
            title: const Text("Bài viết đã lưu", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SavedPostsScreen()),
              );
            },
          ),
          const Spacer(),
          const Divider(color: Colors.white24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Phiên bản 1.0.0",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

// Hàm vẽ cái thanh "viên thuốc" lơ lửng
  Widget _buildFloatingTaskbar() {
    return Padding(
      // Ép lề cho nó lơ lửng cách đáy 30px, cách hai bên 80px
      padding: const EdgeInsets.only(bottom: 30, left: 80, right: 80),
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Màu xám đen
          borderRadius: BorderRadius.circular(40), // Bo tròn
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // --- NÚT BÊN TRÁI (Hướng dẫn Widget) ---
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 0),
              child: Icon(
                Icons.settings_rounded,
                color: _currentIndex == 0 ? Colors.white : Colors.grey,
                size: 26,
              ),
            ),
            
            // --- NÚT Ở GIỮA (Home / Camera) ---
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 1),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _currentIndex == 1 ? const Color(0xFF333333) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home_filled,
                  color: _currentIndex == 1 ? Colors.white : Colors.grey,
                  size: 28,
                ),
              ),
            ),
            
            // --- NÚT BÊN PHẢI (Lịch sử) ---
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 2),
              child: Icon(
                Icons.calendar_month_rounded, // <-- Đổi thành Icon Lịch
                color: _currentIndex == 2 ? Colors.white : Colors.grey,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}