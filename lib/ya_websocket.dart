
import 'dart:async';

import 'package:flutter/services.dart';

class YaWebsocket {
  static const MethodChannel _channel =
      const MethodChannel('ya_websocket');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
