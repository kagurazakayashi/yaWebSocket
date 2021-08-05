import 'dart:async';

import 'package:flutter/services.dart';

abstract class YaWebsocketDelegate {
    yaWebsocketDelegateOnOpen(String httpStatus, String httpStatusMessage, String? tag);
    yaWebsocketDelegateOnMessage(String message, String? tag);
    yaWebsocketDelegateOnClose(String code, String reason, String remote, String? tag);
    yaWebsocketDelegateOnError(String localizedMessage, String? message, String? tag);
}

class YaWebsocket {

  MethodChannel? _channel;

  YaWebsocket(YaWebsocketDelegate delegate) {
    _channel = const MethodChannel('ya_websocket')
    ..setMethodCallHandler((MethodCall methodCall) {
      Map arguments = methodCall.arguments;
      switch (methodCall.arguments) {
        case "onOpen":
          delegate.yaWebsocketDelegateOnOpen(arguments["httpStatus"], arguments["httpStatusMessage"], arguments["tag"] ?? null);
          break;
        case "onMessage":
          delegate.yaWebsocketDelegateOnMessage(arguments["message"], arguments["tag"] ?? null);
          break;
        case "onClose":
          delegate.yaWebsocketDelegateOnClose(arguments["code"], arguments["reason"], arguments["remote"], arguments["tag"] ?? null);
          break;
        case "onError":
          delegate.yaWebsocketDelegateOnError(arguments["localizedMessage"], arguments["message"], arguments["tag"] ?? null);
          break;
        default:
          break;
      }
      // ignore: always_specify_types
      return Future.value(true);
    });
  }

  Future<Map?> connect(String uri, String? tag) async {
    final Map? info =
        await _channel!.invokeMethod('connect', {'uri': uri, 'tag': tag ?? ""});
    // info: Map<String, String>
    //   Keys: status(-1/0), info?
    return info;
  }

  Future<Map?> send(String text) async {
    final Map? info = await _channel!.invokeMethod('send', {'text': text});
    // info: Map<String, String>
    //   Keys: status(-1/0), info?
    return info;
  }

  Future<Map?> close(String text) async {
    final Map? info = await _channel!.invokeMethod('close');
    // info: Map<String, String>
    //   Keys: status(-1/0), info?
    return info;
  }

  Future<Map?> isOpen(String text) async {
    final Map? info = await _channel!.invokeMethod('isOpen');
    // info: Map<String, String>
    //   Keys: status(-1/0/1), info?
    return info;
  }

  Future<String?> get platformVersion async {
    final String? version = await _channel!.invokeMethod('getPlatformVersion');
    return version;
  }
}
