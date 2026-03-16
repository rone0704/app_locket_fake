import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controller để điều khiển việc chuyển trang
  final PageController _pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical, // Vuốt dọc
        physics: const ClampingScrollPhysics(), // Hiệu ứng dính cho trang Home
        children: [
          // TRANG 0: CAMERA
          const CameraScreen(),
          
          // TRANG 1: FEED (LỊCH SỬ)
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // LOGIC MỚI: BẮT CẢ 2 TRƯỜNG HỢP DI CHUYỂN VÀ KÉO QUÁ ĐÀ (OVERSCROLL)
              
              // Điều kiện 1: Đang ở đỉnh Feed (pixels <= 0)
              bool isAtTop = notification.metrics.pixels <= 0;
              
              // Điều kiện 2: Người dùng đang thực sự kéo tay
              bool isUserDragging = false;
              if (notification is ScrollUpdateNotification) {
                isUserDragging = notification.dragDetails != null;
              } else if (notification is OverscrollNotification) {
                isUserDragging = notification.dragDetails != null;
              }

              // Điều kiện 3: Đang kéo xuống (Muốn về Camera)
              bool isPullingDown = false;
              if (notification is ScrollUpdateNotification && notification.dragDetails != null) {
                // primaryDelta > 0 là đang kéo xuống
                if (notification.dragDetails!.primaryDelta! > 0) isPullingDown = true;
              } 
              else if (notification is OverscrollNotification && notification.dragDetails != null) {
                // overscroll < 0 là đang cố kéo xuống khi đã ở đỉnh
                if (notification.overscroll < 0) isPullingDown = true;
              }

              // ==> CHỐT ĐƠN: NẾU THỎA MÃN TẤT CẢ THÌ VỀ CAMERA
              if (isAtTop && isUserDragging && isPullingDown) {
                 _pageController.animateToPage(
                   0, 
                   duration: const Duration(milliseconds: 300), 
                   curve: Curves.easeOut
                 );
              }
              
              return false; // Cho phép sự kiện tiếp tục chạy
            },
            child: const FeedScreen(),
          ),
        ],
      ),
    );
  }
}