class Config {
  // YouTube API Configuration
  static const String youtubeApiKey = 'AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w';
  static const String youtubeApiUrl = 'https://youtubei.googleapis.com/youtubei/v1/player';
  
  // Piped API Configuration
  static const String pipedApiBaseUrl = 'https://pipedapi.kavin.rocks';
  
  // Audio Service Configuration
  static const String androidNotificationChannelId = 'com.example.test_app.channel.audio';
  static const String androidNotificationChannelName = 'YouTube Music Audio';
  static const String androidNotificationIcon = 'mipmap/ic_launcher';
  
  // Performance Configuration
  static const int debounceDelayMs = 100;
  static const int audioServiceDebounceDelayMs = 50;
  
  // UI Configuration
  static const double cardElevation = 4.0;
  static const double borderRadius = 8.0;
  static const double thumbnailAspectRatio = 16.0 / 9.0;
} 