import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'feed_screen.dart';

class HomeScreen extends StatefulWidget {
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onGoToChat;
  final VoidCallback onGoToGallery;
  final VoidCallback? onOpenSettings;
  final String? initialPostId;

  const HomeScreen({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    required this.onGoToChat,
    required this.onGoToGallery,
    this.onOpenSettings,
    this.initialPostId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: widget.pageController,
        scrollDirection: Axis.vertical,
        physics: const ClampingScrollPhysics(),
        onPageChanged: widget.onPageChanged,
        children: [
          CameraScreen(
            onOpenSettings: widget.onOpenSettings,
            onGoToGallery: widget.onGoToGallery, // Gửi lệnh nhảy sang Tab Gallery
            onGoToFeed: () {
              // Lệnh giúp Camera cuộn xuống Feed khi bấm "Lịch sử"
              widget.pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              final isAtTop = notification.metrics.pixels <= 0;
              var isUserDragging = false;
              if (notification is ScrollUpdateNotification) {
                isUserDragging = notification.dragDetails != null;
              } else if (notification is OverscrollNotification) {
                isUserDragging = notification.dragDetails != null;
              }
              var isPullingDown = false;
              if (notification is ScrollUpdateNotification && notification.dragDetails != null) {
                if (notification.dragDetails!.primaryDelta! > 0) isPullingDown = true;
              } else if (notification is OverscrollNotification && notification.dragDetails != null) {
                if (notification.overscroll < 0) isPullingDown = true;
              }
              if (isAtTop && isUserDragging && isPullingDown) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    widget.pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  }
                });
              }
              return false;
            },
            child: FeedScreen(
              initialPostId: widget.initialPostId,
              onGoToChat: widget.onGoToChat,
              onGoToGallery: widget.onGoToGallery,
            ),
          ),
        ],
      ),
    );
  }
}