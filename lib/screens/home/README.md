# Home Screen Module

This folder contains the refactored home screen with its components separated into individual widgets for better maintainability and reusability.

## Structure

```
lib/screens/home/
├── home_screen.dart          # Main home screen with business logic
├── index.dart                # Exports all widgets for easy importing
└── widgets/
    ├── home_app_bar.dart     # Custom app bar with refresh and favorites buttons
    ├── welcome_banner.dart   # Welcome message and app branding
    ├── ads_slider.dart       # Advertisement carousel slider
    ├── sacred_texts_section.dart   # Sacred texts horizontal scroll section
    ├── temples_section.dart         # Temples horizontal scroll section
    └── biographies_section.dart     # Biographies horizontal scroll section
```

## Components Overview

### HomeScreen
- **File**: `home_screen.dart`
- **Purpose**: Main screen widget that orchestrates all components
- **Features**: 
  - Data fetching and state management
  - Language preference handling
  - Navigation logic
  - Lifecycle management

### Widgets

#### HomeAppBar
- **File**: `widgets/home_app_bar.dart`
- **Purpose**: Custom app bar with app title and action buttons
- **Features**: Refresh button, favorites button, consistent branding

#### WelcomeBanner
- **File**: `widgets/welcome_banner.dart`
- **Purpose**: Welcome message and app introduction
- **Features**: App icon, welcome text, gradient background

#### AdsSlider
- **File**: `widgets/ads_slider.dart`
- **Purpose**: Advertisement carousel with auto-scroll
- **Features**: 
  - PageView with indicators
  - Auto-scrolling timer
  - Loading state handling
  - Error handling for images

#### SacredTextsSection
- **File**: `widgets/sacred_texts_section.dart`
- **Purpose**: Horizontal scrolling list of sacred texts
- **Features**: 
  - Loading skeleton animations
  - Error state handling
  - Empty state handling
  - Refresh functionality
  - Touch handling for navigation

#### TemplesSection
- **File**: `widgets/temples_section.dart`
- **Purpose**: Horizontal scrolling list of temples
- **Features**: 
  - Loading skeleton animations
  - Error and empty states
  - Temple-specific icons
  - "See All" navigation button

#### BiographiesSection
- **File**: `widgets/biographies_section.dart`
- **Purpose**: Horizontal scrolling list of biographies
- **Features**: 
  - Loading skeleton animations
  - Error and empty states
  - Profile icons
  - "See All" navigation button

## Benefits of This Structure

1. **Separation of Concerns**: Each widget has a single responsibility
2. **Reusability**: Widgets can be reused in other screens
3. **Maintainability**: Easier to update individual components
4. **Testability**: Each widget can be tested independently
5. **Code Organization**: Better file structure and imports
6. **Performance**: Smaller widgets rebuild only when needed

## Usage

To use the home screen:

```dart
import 'package:hinduapp/screens/home/home_screen.dart';

// Use in navigation
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const HomeScreen()),
);
```

To use individual widgets:

```dart
import 'package:hinduapp/screens/home/widgets/welcome_banner.dart';

// Use the banner widget
const WelcomeBanner()
```

Or use the index file for multiple imports:

```dart
import 'package:hinduapp/screens/home/index.dart';

// Now you have access to all home widgets
```

## Migration Notes

- Original `home_screen.dart` has been moved to `home_screen_backup.dart`
- Import paths updated in `main_navigation_screen.dart`
- All functionality preserved with improved organization
- No breaking changes to the public API
