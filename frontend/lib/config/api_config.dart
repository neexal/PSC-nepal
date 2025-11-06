import 'dart:io';

class ApiConfig {
  // ============================================
  // CONFIGURATION
  // ============================================
  
  // Set this to true to use production backend (Render)
  // Set to false to use local development backend
  static const bool useProductionBackend = true;
  
  // Production backend URL
  static const String productionUrl = 'https://psc-nepal-backend.onrender.com/api';
  
  // Set this to true if testing on a physical Android device
  // Set to false if using Android emulator
  static const bool usePhysicalDevice = true;
  
  // If using physical device, set your computer's IP address here
  // To find your IP:
  // - Windows: Open CMD and type "ipconfig" - look for IPv4 Address
  // - Mac/Linux: Open Terminal and type "ifconfig" or "ip addr"
  // Example: '192.168.1.100'
  static const String computerIpAddress = '192.168.1.117';
  
  // ============================================
  // AUTO DETECTION - DON'T CHANGE BELOW
  // ============================================
  
  static String get baseUrl {
    // Use production backend if enabled
    if (useProductionBackend) {
      return productionUrl;
    }
    
    // Otherwise use local development
    if (Platform.isAndroid) {
      if (usePhysicalDevice) {
        // Physical Android device - use computer's IP
        return 'http://$computerIpAddress:8000/api';
      } else {
        // Android emulator - use special alias for host machine
        return 'http://10.0.2.2:8000/api';
      }
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      return 'http://localhost:8000/api';
    } else {
      // Web or desktop
      return 'http://localhost:8000/api';
    }
  }
  
  static String get wsUrl {
    // For WebSocket connections (if needed in future)
    if (useProductionBackend) {
      return 'wss://psc-nepal-backend.onrender.com';
    }
    
    if (Platform.isAndroid) {
      if (usePhysicalDevice) {
        return 'ws://$computerIpAddress:8000';
      } else {
        return 'ws://10.0.2.2:8000';
      }
    } else {
      return 'ws://localhost:8000';
    }
  }
  
  // Helper to display current configuration
  static String get currentConfig {
    if (useProductionBackend) {
      return 'Production: psc-nepal-backend.onrender.com';
    }
    
    if (Platform.isAndroid) {
      if (usePhysicalDevice) {
        return 'Physical Device: $computerIpAddress';
      } else {
        return 'Android Emulator: 10.0.2.2';
      }
    } else if (Platform.isIOS) {
      return 'iOS Simulator: localhost';
    } else {
      return 'Web/Desktop: localhost';
    }
  }
}
