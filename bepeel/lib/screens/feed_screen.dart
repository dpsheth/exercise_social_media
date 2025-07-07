import 'package:flutter/material.dart';

class FeedScreen extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final int initialIndex;
  final String? scrollToPostId;

  const FeedScreen({
    Key? key,
    required this.posts,
    this.initialIndex = 0,
    this.scrollToPostId,
  }) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final ScrollController _scrollController;
  bool _hasScrolledToInitialIndex = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollToPostId != null) {
        _scrollToPost(widget.scrollToPostId!);
      } else if (widget.initialIndex > 0) {
        _scrollToInitialIndex();
      }
    });
  }

  void _scrollToInitialIndex() {
    if (_hasScrolledToInitialIndex || 
        widget.initialIndex < 0 || 
        widget.initialIndex >= widget.posts.length) {
      return;
    }

    // Calculate the position to scroll to
    final double itemHeight = 600; // Approximate height of each post
    final double targetPosition = widget.initialIndex * itemHeight;
    
    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    
    _hasScrolledToInitialIndex = true;
  }

  // Scroll to a specific post by ID
  void _scrollToPost(String postId) {
    final index = widget.posts.indexWhere((post) => post['id'] == postId);
    if (index != -1 && _scrollController.hasClients) {
      final double itemHeight = 600; // Approximate height of each post
      final double targetPosition = index * itemHeight;
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Handle route arguments for when navigating from profile
    final routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (routeArgs != null && routeArgs['scrollToPostId'] != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToPost(routeArgs['scrollToPostId']);
      });
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'BePeel',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= widget.posts.length) return null;
              final post = widget.posts[index];
              return _buildPost(post);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPost(Map<String, dynamic> post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[800],
                child: Icon(post['profilePic'], color: Colors.white),
              ),
              SizedBox(width: 10),
              Text(
                post['username'],
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Container(
          height: 400,
          color: Colors.grey[800],
          child: Center(
            child: Icon(
              post['image'],
              size: 100,
              color: Colors.grey[600],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.favorite_border, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () {},
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.bookmark_border, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
              Text(
                '${post['likes']} likes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.white),
                  children: [
                    TextSpan(
                      text: '${post['username']} ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: post['caption']),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'View all ${post['comments']} comments',
                style: TextStyle(
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(height: 4),
              Text(
                post['timeAgo'],
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Divider(color: Colors.grey[800]),
      ],
    );
  }
}