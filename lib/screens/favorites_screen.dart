import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../services/api_service.dart';
import 'biography_reading_screen.dart';
import 'temple_reading_screen.dart';
import 'sacred_text_reading_screen.dart';
import 'video_player_screen.dart';
import '../models/video_model.dart';
import 'post_reader_screen.dart';
import '../models/post_model.dart';
import '../constants/app_theme.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService();
  late TabController _tabController;
  // Removed unused _selectedFilter to satisfy lints

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    // Listen to tab changes to refresh the lists
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Tab is changing, refresh the current tab's list
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Removed unused _onFilterChanged

  // ignore: unused_element
  int _getTabIndex(String filter) {
    switch (filter) {
      case 'all':
        return 0;
      case 'biography':
        return 1;
      case 'temple':
        return 2;
      case 'sacredText':
        return 3;
      case 'video':
        return 4;
      case 'post':
        return 5;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmCreamColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'My Favorites',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Biographies'),
            Tab(text: 'Temples'),
            Tab(text: 'Sacred Texts'),
            Tab(text: 'Videos'),
            Tab(text: 'Posts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFavoritesList('all'),
          _buildFavoritesList('biography'),
          _buildFavoritesList('temple'),
          _buildFavoritesList('sacredText'),
          _buildFavoritesList('video'),
          _buildFavoritesList('post'),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(String filter) {
    // Create a new future each time this method is called to ensure fresh data
    // This ensures each tab gets its own filtered data
    final future = filter == 'all' 
        ? _favoritesService.getAllFavorites()
        : _favoritesService.getFavoritesByType(filter);
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('favorites_$filter'), // Unique key for each filter to ensure proper rebuild
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: AppTheme.spacingL),
                Text(
                  'Error loading favorites',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }

        final favorites = snapshot.data ?? [];
        
        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getEmptyIcon(filter),
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(filter),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptySubtitle(filter),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Force rebuild by calling setState
            // The ValueKey will ensure FutureBuilder gets a fresh future
            if (mounted) {
              setState(() {});
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              return _buildFavoriteCard(favorite);
            },
          ),
        );
      },
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> favorite) {
    final itemId = favorite['itemId'] ?? '';
    final itemType = favorite['itemType'] ?? '';
    final title = favorite['title'] ?? '';

    return GestureDetector(
      onTap: () => _navigateToItem(itemId, itemType),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.creamColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusL),
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkGrayColor.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Content section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getItemTypeColor(itemType).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getItemTypeLabel(itemType),
                      style: TextStyle(
                        color: _getItemTypeColor(itemType),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Heart icon
            IconButton(
              onPressed: () => _removeFavorite(itemId),
              icon: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToItem(String itemId, String itemType) async {
    if (itemId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid item ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    switch (itemType) {
      case 'biography':
        // For biographies, pass the itemId as biographyId - the screen will load it
        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BiographyReadingScreen(
                title: '', // Will be loaded by the screen
                biographyId: itemId, // Pass the stored ID as biographyId
              ),
            ),
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening biography: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
      case 'temple':
        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TempleReadingScreen(
                templeId: itemId,
              ),
            ),
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening temple: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
      case 'sacredText':
        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SacredTextReadingScreen(
                sacredTextId: itemId,
              ),
            ),
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening sacred text: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
      case 'video':
        // For videos, we need to create a VideoModel from the favorite data
        try {
          final videoData = {
            'id': itemId,
            'videourl': 'https://www.youtube.com/watch?v=$itemId', // Assuming itemId is YouTube ID
            'title': 'Hindu Devotional Video',
            'description': 'Watch this spiritual and devotional content',
          };
          
          final videoModel = VideoModel.fromJson(videoData);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(video: videoModel),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening video: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
      case 'post':
        // For posts, we need to fetch the full post data from API
        try {
          final apiService = ApiService();
          final response = await apiService.getPostById(postId: itemId);
          
          if (response['data'] != null) {
            final postData = response['data'];
            final postModel = PostModel.fromJson(postData);
            
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostReaderScreen(post: postModel),
                ),
              );
            }
          } else {
            // Show error if post not found
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Post not found'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          // Show error if API call fails
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading post: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
      default:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unknown item type: $itemType'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
    }
  }

  void _removeFavorite(String itemId) async {
    try {
      await _favoritesService.removeFromFavorites(itemId);
      if (mounted) {
        // Force rebuild all tabs by calling setState
        // The ValueKey in FutureBuilder will ensure each tab rebuilds with fresh data
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing from favorites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getItemTypeColor(String itemType) {
    switch (itemType) {
      case 'biography':
        return Colors.blue;
      case 'temple':
        return Colors.orange;
      case 'sacredText':
        return Colors.green;
      case 'video':
        return Colors.red;
      case 'post':
        return Colors.purple;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getItemTypeLabel(String itemType) {
    switch (itemType) {
      case 'biography':
        return 'Biography';
      case 'temple':
        return 'Temple';
      case 'sacredText':
        return 'Sacred Text';
      case 'video':
        return 'Video';
      case 'post':
        return 'Post';
      default:
        return 'Item';
    }
  }

  IconData _getEmptyIcon(String filter) {
    switch (filter) {
      case 'biography':
        return Icons.person_outline;
      case 'temple':
        return Icons.temple_hindu;
      case 'sacredText':
        return Icons.menu_book_outlined;
      case 'video':
        return Icons.video_library_outlined;
      case 'post':
        return Icons.article_outlined;
      default:
        return Icons.favorite_border;
    }
  }

  String _getEmptyMessage(String filter) {
    switch (filter) {
      case 'biography':
        return 'No favorite biographies';
      case 'temple':
        return 'No favorite temples';
      case 'sacredText':
        return 'No favorite sacred texts';
      case 'video':
        return 'No favorite videos';
      case 'post':
        return 'No favorite posts';
      default:
        return 'No favorites yet';
    }
  }

  String _getEmptySubtitle(String filter) {
    switch (filter) {
      case 'biography':
        return 'Biographies you favorite will appear here';
      case 'temple':
        return 'Temples you favorite will appear here';
      case 'sacredText':
        return 'Sacred Texts you favorite will appear here';
      case 'video':
        return 'Videos you favorite will appear here';
      case 'post':
        return 'Posts you favorite will appear here';
      default:
        return 'Start favoriting content to see it here';
    }
  }
} 