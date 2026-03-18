import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ==========================================
// EXPLORE/TRENDING SCREEN
// ==========================================

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Khám phá",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 18),
                  SizedBox(width: 8),
                  Text("Xu hướng"),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 18),
                  SizedBox(width: 8),
                  Text("Bạn mới"),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_fire_department, size: 18),
                  SizedBox(width: 8),
                  Text("Hot"),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TrendingPostsView(currentUserId: currentUser?.uid ?? ''),
          NewFriendsView(currentUserId: currentUser?.uid ?? ''),
          HotPostsView(currentUserId: currentUser?.uid ?? ''),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ==========================================
// TRENDING POSTS
// ==========================================

class TrendingPostsView extends StatelessWidget {
  final String currentUserId;

  const TrendingPostsView({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "Chưa có bài viết nào",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final post = snapshot.data!.docs[index];
            return _buildPostTile(context, post);
          },
        );
      },
    );
  }

  Widget _buildPostTile(BuildContext context, DocumentSnapshot post) {
    final data = post.data() as Map<String, dynamic>;
    final reactions = data['reactions'] as Map<String, dynamic>?;
    int reactionCount = 0;

    reactions?.forEach((key, value) {
      reactionCount += (value as List?)?.length ?? 0;
    });

    return GestureDetector(
      onTap: () {
        // TODO: Open post detail
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(data['imageUrl'] ?? ''),
            fit: BoxFit.cover,
          ),
          color: Colors.grey[900],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['author'] ?? 'Ẩn danh',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '❤️ $reactionCount',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// NEW FRIENDS/USERS TO FOLLOW
// ==========================================

class NewFriendsView extends StatefulWidget {
  final String currentUserId;

  const NewFriendsView({super.key, required this.currentUserId});

  @override
  State<NewFriendsView> createState() => _NewFriendsViewState();
}

class _NewFriendsViewState extends State<NewFriendsView> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        }

        final userData =
            userSnapshot.data!.data() as Map<String, dynamic>?;
        final myFriends =
            List<String>.from(userData?['friends'] ?? []);
        final myId = widget.currentUserId;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              );
            }

            final allUsers = snapshot.data!.docs
                .where((doc) =>
                    doc.id != myId && !myFriends.contains(doc['email']))
                .toList();

            if (allUsers.isEmpty) {
              return const Center(
                child: Text(
                  "Không có bạn mới",
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }

            return ListView.builder(
              itemCount: allUsers.length,
              itemBuilder: (context, index) {
                final user = allUsers[index];
                return _buildUserCard(context, user);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUserCard(BuildContext context, DocumentSnapshot user) {
    final data = user.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: data['avatarUrl'] != null
                ? NetworkImage(data['avatarUrl'])
                : null,
            backgroundColor: Colors.amber,
            child: data['avatarUrl'] == null
                ? Text(
                    (data['displayName'] ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['displayName'] ?? 'Ẩn danh',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  data['email'] ?? '',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _addFriend(data['email']),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text(
              "Kết bạn",
              style: TextStyle(color: Colors.black, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _addFriend(String friendEmail) async {
    // Add to friends list
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .update({
      'friends': FieldValue.arrayUnion([friendEmail]),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã kết bạn với $friendEmail")),
      );
    }
  }
}

// ==========================================
// HOT POSTS (MOST REACTIONS)
// ==========================================

class HotPostsView extends StatelessWidget {
  final String currentUserId;

  const HotPostsView({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        }

        final posts = snapshot.data!.docs;

        // Sort by reaction count
        posts.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          int aCount = 0, bCount = 0;
          (aData['reactions'] as Map?)?.forEach((key, value) {
            aCount += (value as List?)?.length ?? 0;
          });
          (bData['reactions'] as Map?)?.forEach((key, value) {
            bCount += (value as List?)?.length ?? 0;
          });

          return bCount.compareTo(aCount);
        });

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return _buildHotPostTile(context, posts[index]);
          },
        );
      },
    );
  }

  Widget _buildHotPostTile(BuildContext context, DocumentSnapshot post) {
    final data = post.data() as Map<String, dynamic>;
    final reactions = data['reactions'] as Map<String, dynamic>?;
    int reactionCount = 0;

    reactions?.forEach((key, value) {
      reactionCount += (value as List?)?.length ?? 0;
    });

    return GestureDetector(
      onTap: () {
        // TODO: Open post detail
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(data['imageUrl'] ?? ''),
            fit: BoxFit.cover,
          ),
          color: Colors.grey[900],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_fire_department,
                    color: Colors.white, size: 16),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['author'] ?? 'Ẩn danh',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🔥 $reactionCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
