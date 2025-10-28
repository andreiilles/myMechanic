import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformUtils {
  /// Check if the app is running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  
  /// Check if the app is running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  
  /// Check if the app is running on Web
  static bool get isWeb => kIsWeb;
  
  /// Check if the app is running on a mobile platform
  static bool get isMobile => isIOS || isAndroid;
  
  /// Check if the app is running on desktop
  static bool get isDesktop => !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
}
