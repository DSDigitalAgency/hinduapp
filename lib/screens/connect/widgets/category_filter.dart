import 'package:flutter/material.dart';

class CategoryFilter extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const CategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  static const List<Map<String, String>> _categories = [
    {'name': 'All', 'value': 'all'},
    {'name': 'Astrology', 'value': 'Astrology'},
    {'name': 'Ayurveda', 'value': 'Ayurveda'},
    {'name': 'Festivals', 'value': 'Festivals'},
    {'name': 'General', 'value': 'General'},
    {'name': 'Knowledge', 'value': 'Knowledge'},
    {'name': 'Nature', 'value': 'Nature'},
    {'name': 'Shastras', 'value': 'Shastras'},
    {'name': 'Vastu', 'value': 'Vastu'},
    {'name': 'Worship', 'value': 'Worship'},
    {'name': 'Yoga', 'value': 'Yoga'},
    {'name': 'Aparam', 'value': 'Aparam'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = selectedCategory == category['name'];

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category['name']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onCategoryChanged(category['name']!);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFFF9933),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? const Color(0xFFFF9933) : Colors.grey[300]!,
                width: 1,
              ),
            ),
          );
        },
      ),
    );
  }
}
