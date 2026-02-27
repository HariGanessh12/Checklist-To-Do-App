import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HomeScreenWidgetService {
  static const MethodChannel _channel = MethodChannel(
    'checklist_app/home_widgets',
  );

  static Future<void> updateWidgets() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('updateHomeWidgets');
    } catch (_) {
      // Ignore widget update failures to avoid affecting core app flows.
    }
  }
}
