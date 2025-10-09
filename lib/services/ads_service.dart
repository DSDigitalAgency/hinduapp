class AdsService {
  // Static ad image URLs
  static const String _splashAdImage = 'https://hinduconnect.app/appimgs/ads.jpg';
  static const List<String> _sliderImages = [
    'https://hinduconnect.app/appimgs/1.jpg',
    'https://hinduconnect.app/appimgs/2.jpg',
    'https://hinduconnect.app/appimgs/3.jpg',
    'https://hinduconnect.app/appimgs/4.jpg',
    'https://hinduconnect.app/appimgs/5.jpg',
  ];
  
  // Fallback image (you can replace this with a local asset if needed)
  static const String _fallbackImage = 'https://hinduconnect.app/appimgs/ads.jpg';
  
  /// Get the splash screen ad image URL
  String getSplashAdImage() {
    return _splashAdImage;
  }
  
  /// Get all slider images
  List<String> getSliderImages() {
    return List.from(_sliderImages);
  }
  
  /// Get random ad image URL (for backward compatibility)
  String getRandomAdImage() {
    return _splashAdImage;
  }
  
  /// Get multiple ad images for slider (for backward compatibility)
  List<String> getAdImagesForSlider({int count = 5}) {
    final images = getSliderImages();
    if (count > images.length) count = images.length;
    return images.take(count).toList();
  }
  
  /// Get fallback image URL
  String getFallbackImage() {
    return _fallbackImage;
  }
}
