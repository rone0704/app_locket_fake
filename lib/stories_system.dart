import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ==========================================
// STORIES - ẢNH TẠMTHỜI (24H)
// ==========================================

class StoriesSystem {
  final String userId;

  StoriesSystem({required this.userId});

  // Tạo story
  Future<void> createStory({
    required String imageUrl,
    required String caption,
  }) async {
    final expiryTime = DateTime.now().add(const Duration(hours: 24));

    await FirebaseFirestore.instance.collection('stories').add({
      'userId': userId,
      'imageUrl': imageUrl,
      'caption': caption,
      'timestamp': FieldValue.serverTimestamp(),
      'expiryTime': expiryTime,
      'viewers': [],
      'createdAt': DateTime.now(),
    });
  }

  // Thêm viewer
  Future<void> addStoryViewer(String storyId) async {
    await FirebaseFirestore.instance.collection('stories').doc(storyId).update({
      'viewers': FieldValue.arrayUnion([userId]),
    });
  }

  // Lấy stories của bạn bè
  static Future<List<DocumentSnapshot>> getFriendsStories(
      String currentUserId) async {
    // Lấy danh sách bạn bè
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    final friends = List<String>.from(userDoc['friends'] ?? []);

    // Lấy stories còn hạn
    final now = DateTime.now();
    final snapshot = await FirebaseFirestore.instance
        .collection('stories')
        .where('expiryTime', isGreaterThan: now)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          return friends.contains(data['userId']);
        })
        .toList();
  }

  // Xóa story hết hạn
  static Future<void> deleteExpiredStories() async {
    final now = DateTime.now();
    final snapshot = await FirebaseFirestore.instance
        .collection('stories')
        .where('expiryTime', isLessThan: now)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}

// ==========================================
// STORIES DISPLAY
// ==========================================

class StoriesView extends StatefulWidget {
  final String currentUserId;

  const StoriesView({super.key, required this.currentUserId});

  @override
  State<StoriesView> createState() => _StoriesViewState();
}

class _StoriesViewState extends State<StoriesView> {
  late PageController _pageController;
  late Future<List<DocumentSnapshot>> _storiesFuture;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _storiesFuture = StoriesSystem.getFriendsStories(widget.currentUserId);
    // Xóa stories hết hạn
    StoriesSystem.deleteExpiredStories();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _storiesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        }

        final stories = snapshot.data!;
        if (stories.isEmpty) {
          return Center(
            child: Text(
              "Không có stories",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return PageView.builder(
          controller: _pageController,
          itemCount: stories.length,
          itemBuilder: (context, index) {
            return StoryFrame(
              story: stories[index],
              currentUserId: widget.currentUserId,
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// ==========================================
// SINGLE STORY
// ==========================================

class StoryFrame extends StatefulWidget {
  final DocumentSnapshot story;
  final String currentUserId;

  const StoryFrame({
    super.key,
    required this.story,
    required this.currentUserId,
  });

  @override
  State<StoryFrame> createState() => _StoryFrameState();
}

class _StoryFrameState extends State<StoryFrame> {
  @override
  void initState() {
    super.initState();
    // Thêm view
    StoriesSystem(userId: widget.currentUserId).addStoryViewer(widget.story.id);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.story.data() as Map<String, dynamic>;
    final expiryTime = (data['expiryTime'] as Timestamp).toDate();
    final timeLeft = expiryTime.difference(DateTime.now());
    final hours = timeLeft.inHours;
    final minutes = timeLeft.inMinutes % 60;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ảnh
          Image.network(
            data['imageUrl'] ?? '',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.black,
                child: const Center(
                  child: Text(
                    "Không thể tải ảnh",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              );
            },
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userId'] ?? 'Ẩn danh',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Hết hạn trong ${hours}h ${minutes}m",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Caption
          if ((data['caption'] ?? '').isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Text(
                  data['caption'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          // Viewers count
          Positioned(
            bottom: 20,
            right: 16,
            child: GestureDetector(
              onTap: () => _showViewers(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "${((data['viewers'] ?? [])).length}",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showViewers() {
    final data = widget.story.data() as Map<String, dynamic>;
    final viewers = List<String>.from(data['viewers'] ?? []);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Những ai đã xem",
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: viewers.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  viewers[index],
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// ==========================================
// STORY CREATOR
// ==========================================

class StoryCreator extends StatelessWidget {
  final VoidCallback onStoryCreated;

  const StoryCreator({
    super.key,
    required this.onStoryCreated,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Chọn cách tạo story",
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.amber),
                  title: const Text("Chụp ảnh", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement camera
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image, color: Colors.amber),
                  title: const Text("Chọn từ thư viện", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement gallery picker
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: 60,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: Colors.amber, size: 28),
            SizedBox(height: 4),
            Text(
              "Story",
              style: TextStyle(
                color: Colors.amber,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
