# Connect Screen Module

This module contains the Connect Screen implementation divided into reusable widgets for better maintainability and organization.

## Structure

```
connect/
├── connect_screen.dart          # Main screen implementation
├── index.dart                   # Module exports
├── widgets/
│   ├── connect_app_bar.dart     # App bar with search functionality
│   ├── connect_header.dart      # Header section
│   ├── search_results_indicator.dart # Search results display
│   ├── category_filter.dart     # Category filter chips
│   ├── posts_list.dart         # Posts list with loading states
│   └── post_card.dart          # Individual post card widget
└── README.md                    # This file
```

## Widgets Overview

### ConnectScreen
Main screen that orchestrates all components. Handles:
- API calls and data management
- Search functionality
- Pagination and caching
- Navigation between posts

### ConnectAppBar
App bar component with:
- Animated search bar expansion
- Search input with debouncing
- Sort options button

### ConnectHeader
Header section displaying:
- Screen title and icon
- Description text
- Styled container with theme colors

### SearchResultsIndicator
Shows search results information:
- Number of results found
- No results message
- Clear search functionality

### CategoryFilter
Horizontal scrollable category filter:
- Filter chips for different categories
- Selection state management
- Category switching functionality

### PostsList
Main content area handling:
- Loading states with shimmer effect
- Error states with retry functionality
- Posts list with infinite scroll
- Pull-to-refresh functionality

### PostCard
Individual post display widget:
- Post title, author, and date
- Category and language tags
- Favorite toggle functionality
- Tap navigation to post reader

## Usage

```dart
import 'package:your_app/screens/connect/connect_screen.dart';

// Or import the entire module
import 'package:your_app/screens/connect/index.dart';
```

## Features

- **Modular Design**: Each widget has a single responsibility
- **Reusable Components**: Widgets can be used independently
- **Consistent Styling**: Uses app theme colors and styling
- **Performance Optimized**: Proper loading states and caching
- **Accessibility**: Proper semantic labels and focus management

## Migration

The original `connect_screen.dart` file has been moved to `connect/connect_screen.dart`. 
The old file now exports the new implementation for backward compatibility.

## Development Guidelines

1. **Widget Separation**: Keep widgets focused on single responsibilities
2. **State Management**: Pass callbacks for state changes to parent widgets
3. **Theming**: Use consistent colors and styling from the app theme
4. **Performance**: Implement proper loading states and avoid unnecessary rebuilds
5. **Testing**: Each widget should be testable in isolation
