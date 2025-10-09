import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class ReadingSettingsWidget extends StatefulWidget {
  // Initial values passed from the parent screen
  final double initialTextSize;
  final Color initialBackgroundColor;
  final double initialTextSpacing;

  // Callbacks to notify the parent screen of changes
  final ValueChanged<double> onTextSizeChanged;
  final ValueChanged<Color> onBackgroundColorChanged;
  final ValueChanged<double> onTextSpacingChanged;

  const ReadingSettingsWidget({
    super.key,
    required this.initialTextSize,
    required this.initialBackgroundColor,
    required this.initialTextSpacing,
    required this.onTextSizeChanged,
    required this.onBackgroundColorChanged,
    required this.onTextSpacingChanged,
  });

  // Static method to easily show the modal
  static void showReadingSettings({
    required BuildContext context,
    required double textSize,
    required Color backgroundColor,
    required double textSpacing,
    required ValueChanged<double> onTextSizeChanged,
    required ValueChanged<Color> onBackgroundColorChanged,
    required ValueChanged<double> onTextSpacingChanged,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReadingSettingsWidget(
          initialTextSize: textSize,
          initialBackgroundColor: backgroundColor,
          initialTextSpacing: textSpacing,
          onTextSizeChanged: onTextSizeChanged,
          onBackgroundColorChanged: onBackgroundColorChanged,
          onTextSpacingChanged: onTextSpacingChanged,
        );
      },
    );
  }

  // Static properties for background colors and names
  static const List<Color> backgroundColors = [
    Colors.white,
    Color(0xFFF5F5DC), // Beige
    AppTheme.ashColor, // Ash (semi-dark)
    AppTheme.darkColor, // Dark
  ];

  static const List<String> backgroundColorNames = [
    'Light',
    'Semi Light',
    'Semi Dark',
    'Dark',
  ];

  static Color getTextColor(Color backgroundColor) {
    // Return appropriate text color based on background
    if (backgroundColor == AppTheme.darkColor) {
      return Colors.white; // White text for dark background
    } else if (backgroundColor == AppTheme.ashColor) {
      return Colors.black87; // Dark text for ash background
    } else if (backgroundColor == const Color(0xFFF5F5DC)) {
      return Colors.black54; // Medium dark text for beige background
    } else {
      return Colors.black87; // Dark text for light backgrounds
    }
  }

  static Color getContainerColor(Color backgroundColor) {
    if (backgroundColor == AppTheme.darkColor) {
      return const Color(0xFF2A2A2A); // Darker container for dark theme
    } else if (backgroundColor == AppTheme.ashColor) {
      return const Color(0xFFD0D0D0); // Slightly darker container for ash background
    } else if (backgroundColor == const Color(0xFFF5F5DC)) {
      return const Color(0xFFD0D0D0); // Slightly darker container for beige background
    } else {
      return Colors.white; // White container for light themes
    }
  }
  
  @override
  State<ReadingSettingsWidget> createState() => _ReadingSettingsWidgetState();
}

class _ReadingSettingsWidgetState extends State<ReadingSettingsWidget> {
  // Local state variables to hold the current values for the UI
  late double _currentTextSize;
  late Color _currentBackgroundColor;
  late double _currentTextSpacing;

  @override
  void initState() {
    super.initState();
    // Initialize local state with the values from the parent
    _currentTextSize = widget.initialTextSize;
    _currentBackgroundColor = widget.initialBackgroundColor;
    _currentTextSpacing = widget.initialTextSpacing;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Reading Settings',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF9933),
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextSizeControl(),
            const SizedBox(height: 24),
            _buildBackgroundColorControl(),
            const SizedBox(height: 24),
            _buildTextSpacingControl(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Close',
            style: TextStyle(
              color: Color(0xFFFF9933),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Widget for Text Size Slider
  Widget _buildTextSizeControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Text Size',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Small'),
            Expanded(
              child: Slider(
                value: _currentTextSize,
                min: 12.0,
                max: 24.0,
                divisions: 6,
                activeColor: const Color(0xFFFF9933),
                onChanged: (newSize) {
                  // **THIS IS THE KEY - Update local state first**
                  setState(() {
                    _currentTextSize = newSize;
                  });
                  // Then notify the parent widget of the change
                  widget.onTextSizeChanged(newSize);
                },
              ),
            ),
            const Text('Large'),
          ],
        ),
        Center(
          child: Text(
            '${_currentTextSize.round()}px',
            style: TextStyle(
              fontSize: _currentTextSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Widget for Background Color Selection
  Widget _buildBackgroundColorControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Background Color',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            ReadingSettingsWidget.backgroundColors.length,
            (index) => GestureDetector(
              onTap: () {
                // Update local state first
                setState(() {
                  _currentBackgroundColor = ReadingSettingsWidget.backgroundColors[index];
                });
                // Then notify the parent widget
                widget.onBackgroundColorChanged(ReadingSettingsWidget.backgroundColors[index]);
              },
              child: Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: ReadingSettingsWidget.backgroundColors[index],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _currentBackgroundColor == ReadingSettingsWidget.backgroundColors[index]
                        ? const Color(0xFFFF9933)
                        : Colors.grey.shade300,
                    width: _currentBackgroundColor == ReadingSettingsWidget.backgroundColors[index] ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    ReadingSettingsWidget.backgroundColorNames[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _currentBackgroundColor == ReadingSettingsWidget.backgroundColors[index]
                          ? const Color(0xFFFF9933)
                          : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Widget for Text Spacing Slider
  Widget _buildTextSpacingControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Text Spacing',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Tight'),
            Expanded(
              child: Slider(
                value: _currentTextSpacing,
                min: 1.0,
                max: 2.5,
                divisions: 6,
                activeColor: const Color(0xFFFF9933),
                onChanged: (newSpacing) {
                  // Update local state first
                  setState(() {
                    _currentTextSpacing = newSpacing;
                  });
                  // Then notify the parent widget
                  widget.onTextSpacingChanged(newSpacing);
                },
              ),
            ),
            const Text('Loose'),
          ],
        ),
        Center(
          child: Text(
            '${_currentTextSpacing.toStringAsFixed(1)}x',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
} 