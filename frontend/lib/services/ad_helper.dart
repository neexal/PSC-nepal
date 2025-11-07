import 'dart:io';

class AdHelper {
  // Your AdMob App ID: ca-app-pub-1970087582518289~5246346021
  
  // Banner Ad Unit IDs
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1970087582518289/9704465783';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1970087582518289/9704465783'; // Replace with iOS ad unit when available
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
  
  // Test Ad Unit IDs (use during development)
  static String get testBannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
