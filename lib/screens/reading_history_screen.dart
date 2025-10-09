import 'package:flutter/material.dart';
import '../services/cache_service.dart';
// Removed unused model imports
import 'sacred_text_reading_screen.dart';
import 'temple_reading_screen.dart';
import 'biography_reading_screen.dart';
// Removed unused post reader import

class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({super.key});

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen> {
  final CacheService _cacheService = CacheService();
  List<Map<String, dynamic>> _readingHistory = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  final List<String> _filterOptions = ['All', 'Sacred Texts', 'Temples', 'Biographies'];

  @override
  void initState() {
    super.initState();
    _loadReadingHistory();
  }

  Future<void> _loadReadingHistory() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load cached content from local storage
      final cachedSacredTexts = await _cacheService.getCachedSacredTexts();
      final cachedTemples = await _cacheService.getCachedTemples();
      final cachedBiographies = await _cacheService.getCachedBiographies();
      
      // Convert cached content to list format
      final List<Map<String, dynamic>> allCachedContent = [];
      
      // Add Sacred Texts
      cachedSacredTexts.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          allCachedContent.add({
            ...value,
            'id': key,
            'type': 'sacred_text',
          });
        }
      });
      
      // Add temples
      cachedTemples.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          allCachedContent.add({
            ...value,
            'id': key,
            'type': 'temple',
          });
        }
      });
      
      // Add biographies
      cachedBiographies.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          allCachedContent.add({
            ...value,
            'id': key,
            'type': 'biography',
          });
        }
      });
      
      // Sort by cached timestamp (most recent first)
      allCachedContent.sort((a, b) {
        final aTime = a['cached_at'];
        final bTime = b['cached_at'];
        
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        
        final aDateTime = aTime is String ? DateTime.tryParse(aTime) : aTime;
        final bDateTime = bTime is String ? DateTime.tryParse(bTime) : bTime;
        
        if (aDateTime == null && bDateTime == null) return 0;
        if (aDateTime == null) return 1;
        if (bDateTime == null) return -1;
        
        return bDateTime.compareTo(aDateTime);
      });
      
      setState(() {
        _readingHistory = allCachedContent;
        _isLoading = false;
      });

      // Loaded ${_readingHistory.length} cached content items
    } catch (e) {
      // Error loading cached content: $e
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_selectedFilter == 'All') {
      return _readingHistory;
    }
    
    final filtered = _readingHistory.where((item) {
      final type = item['type'] ?? '';
      final filter = _selectedFilter.toLowerCase();
      
      // Map plural filter names to singular data types
      switch (filter) {
        case 'sacred texts':
          return type == 'sacred_text';
        case 'temples':
          return type == 'temple';
        case 'biographies':
          return type == 'biography';
        default:
          return type.toLowerCase() == filter;
      }
    }).toList();
    
    // Debug logging removed for production
    
    return filtered;
  }

  String _getItemTitle(Map<String, dynamic> item) {
    return item['title'] ?? 
           item['displayTitle'] ?? 
           item['name'] ?? 
           'Unknown Item';
  }

  String _getItemType(Map<String, dynamic> item) {
    final type = item['type'] ?? '';
    switch (type.toLowerCase()) {
      case 'sacred_text':
        return 'Sacred Text';
      case 'temple':
        return 'Temple';
      case 'biography':
        return 'Biography';
      case 'post':
        return 'Post';
      default:
        return 'Unknown';
    }
  }

  IconData _getItemIcon(Map<String, dynamic> item) {
    final type = item['type'] ?? '';
    switch (type.toLowerCase()) {
      case 'sacred_text':
        return Icons.menu_book;
      case 'temple':
        return Icons.temple_hindu;
      case 'biography':
        return Icons.person;
      case 'post':
        return Icons.article;
      default:
        return Icons.article;
    }
  }

  Color _getItemColor(Map<String, dynamic> item) {
    final type = item['type'] ?? '';
    switch (type.toLowerCase()) {
      case 'sacred_text':
        return Colors.blue;
      case 'temple':
        return Colors.orange;
      case 'biography':
        return Colors.green;
      case 'post':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _navigateToItem(Map<String, dynamic> item) {
    final type = item['type'] ?? '';
    final itemId = item['id'] ?? item['_id'] ?? '';
    final itemData = Map<String, dynamic>.from(item);

    switch (type.toLowerCase()) {
      case 'sacred_text':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SacredTextReadingScreen(
              sacredTextId: itemId,
              sacredText: itemData,
            ),
          ),
        );
        break;
      case 'temple':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TempleReadingScreen(
              templeId: itemId,
              temple: itemData,
            ),
          ),
        );
        break;
      case 'biography':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BiographyReadingScreen(
              title: itemData['title'] ?? 'Biography',
              content: itemData['excerpt'] ?? 'Biography content',
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      appBar: AppBar(
        title: const Text(
          'Reading History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFFF9933),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9933)),
              ),
            )
          : Column(
              children: [
                // Filter chips
                if (_readingHistory.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filterOptions.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                              selectedColor: const Color(0xFFFF9933).withValues(alpha: 0.2),
                              checkmarkColor: const Color(0xFFFF9933),
                              labelStyle: TextStyle(
                                color: isSelected ? const Color(0xFFFF9933) : Colors.grey[600],
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                
                // Content
                Expanded(
                  child: _filteredHistory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                                                             Text(
                                 _readingHistory.isEmpty 
                                     ? 'No offline content yet'
                                     : 'No $_selectedFilter items offline',
                                 style: TextStyle(
                                   fontSize: 18,
                                   fontWeight: FontWeight.w600,
                                   color: Colors.grey[600],
                                 ),
                               ),
                               const SizedBox(height: 8),
                               Text(
                                 _readingHistory.isEmpty
                                     ? 'Content you open will be saved for offline reading'
                                     : 'Try opening some $_selectedFilter content',
                                 style: TextStyle(
                                   fontSize: 14,
                                   color: Colors.grey[500],
                                 ),
                                 textAlign: TextAlign.center,
                               ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredHistory.length,
                          itemBuilder: (context, index) {
                            final item = _filteredHistory[index];
                            return _buildHistoryItem(item, index);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item, int index) {
    final title = _getItemTitle(item);
    final type = _getItemType(item);
    final icon = _getItemIcon(item);
    final color = _getItemColor(item);
    final timestamp = item['cached_at'] ?? DateTime.now();
    final dateTime = timestamp is String 
        ? DateTime.tryParse(timestamp) ?? DateTime.now()
        : timestamp;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(dateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 16,
        ),
        onTap: () => _navigateToItem(item),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
} 