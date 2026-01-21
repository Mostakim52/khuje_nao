/// Centralized API configuration for the app.
/// Update the base URL here to change the backend endpoint across the entire app.
class ApiConfig {
  /// Base URL for the backend API.
  /// 
  /// For local development: 'http://localhost:5000'
  /// For production: Your Vercel deployment URL
  /// For testing with ngrok: Your ngrok URL
  static const String baseUrl = 'http://10.0.2.2:5000';
  
  /// API endpoints
  static const String signup = '/signup';
  static const String login = '/login';
  static const String firebaseGoogleLogin = '/firebase-google-login';
  static const String profile = '/profile';
  static const String lostItems = '/lost-items';
  static const String lostItemsAdmin = '/lost-items-admin';
  static const String foundItems = '/found-items';
  static const String activityFeed = '/activity-feed';
  static const String searchLostItems = '/search-lost-items';
  static const String sendMessage = '/send_message';
  static const String getMessages = '/get_messages';
  static const String getChats = '/get_chats';
  static const String checkUserExists = '/check-user-exists';
  static const String userByEmail = '/user-by-email';
  
  /// Helper method to get full URL for an endpoint
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  /// Helper method to get user by email URL
  static String getUserByEmailUrl(String email) {
    return '$baseUrl/user-by-email/$email';
  }
  
  /// Helper method to get approval URL for a lost item
  static String getApproveUrl(String itemId) {
    return '$baseUrl/lost-items/$itemId/approve';
  }
  
  /// Helper method to get found URL for a lost item
  static String getFoundUrl(String itemId) {
    return '$baseUrl/lost-items/$itemId/found';
  }
}