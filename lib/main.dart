import 'dart:async';
import 'package:flutter/services.dart';

abstract class YaWebsocketDelegate {
    yaWebsocketDelegateOnOpen(String httpStatus, String httpStatusMessage, String? tag);
    yaWebsocketDelegateOnConnecting(String? tag);
    yaWebsocketDelegateOnMessage(String message, String? tag);
    yaWebsocketDelegateOnClose(String code, String reason, String remote, String? tag);
    yaWebsocketDelegateOnError(String localizedMessage, String? message, String? tag);
}

class YaWebsocket {

  MethodChannel _methodChannel = const MethodChannel('ya_websocket_m');
  EventChannel _eventChannel = EventChannel('ya_websocket_e');
  YaWebsocketDelegate? delegate;
  String _uri = "";
  String? _tag;

  YaWebsocket() {
    _eventChannel.receiveBroadcastStream().listen(eventChannelData);
    // _methodChannel.setMethodCallHandler((MethodCall methodCall) {
    //   Map arguments = methodCall.arguments;
    //   return Future.value(true);
    // });
  }

  eventChannelData(event) {
    Map arguments = event;
    if (delegate == null) {
      return;
    }
    switch (arguments["id"]) {
        case "onOpen":
          delegate!.yaWebsocketDelegateOnOpen(arguments["httpStatus"], arguments["httpStatusMessage"], arguments["tag"] ?? null);
          break;
        case "onMessage":
          delegate!.yaWebsocketDelegateOnMessage(arguments["message"], arguments["tag"] ?? null);
          break;
        case "onClose":
          delegate!.yaWebsocketDelegateOnClose(arguments["code"], arguments["reason"], arguments["remote"], arguments["tag"] ?? null);
          break;
        case "onError":
          delegate!.yaWebsocketDelegateOnError(arguments["localizedMessage"], arguments["message"], arguments["tag"] ?? null);
          break;
        case "onConnecting":
          delegate!.yaWebsocketDelegateOnConnecting(arguments["tag"] ?? null);
          break;
        default:
          break;
      }
  }

  Future<Map?> reconnect() async {
    final Map? info =
        await _methodChannel.invokeMethod('connect', {'uri': _uri, 'tag': _tag ?? ""});
    // info: Map<String, String>
    //   Keys: status(-1/0), info?
    return info;
  }

  Future<Map?> connect(String uri, String? tag) async {
    _uri = uri;
    _tag = tag;
    final Map? info =
        await _methodChannel.invokeMethod('connect', {'uri': uri, 'tag': tag ?? ""});
    // info: Map<String, String>
    //   Keys: status(-1/0), info?
    return info;
  }

  Future<Map?> send(String text) async {
    final Map? info = await _methodChannel.invokeMethod('send', {'text': text});
    // info: Map<String, String>
    //   Keys: status(-1/0), info?
    return info;
  }

  Future<Map?> close() async {
    final Map? info = await _methodChannel.invokeMethod('close');
    // info: Map<String, String>
    //   Keys: status(-1/0), info?
    return info;
  }

  Future<Map?> isOpen() async {
    final Map? info = await _methodChannel.invokeMethod('isOpen');
    // info: Map<String, String>
    //   Keys: status(-1/0/1), info?
    return info;
  }

  Future<String?> get platformVersion async {
    final String? version = await _methodChannel.invokeMethod('getPlatformVersion');
    return version;
  }
}
