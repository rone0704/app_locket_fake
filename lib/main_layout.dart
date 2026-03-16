import 'package:flutter/material.dart';
import 'home_screen.dart'; // Màn hình Camera của ông
import 'calendar_screen.dart'; // Màn hình lịch ông mới tạo
import 'settings_screen.dart';
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
      // DÒNG NÀY CỰC QUAN TRỌNG: Cho phép camera tràn xuống tận đáy màn hình, chui ra sau cái thanh
      extendBody: true, 
      body: _screens[_currentIndex],
      
      // Chế lại thanh Taskbar lơ lửng
      bottomNavigationBar: _buildFloatingTaskbar(),
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