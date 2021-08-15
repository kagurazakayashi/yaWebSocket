import 'dart:async';
import 'package:flutter/services.dart';

abstract class YaWebsocketDelegate {
  /// 已连接时
  ///
  /// String [httpStatus] HTTP 状态码
  ///
  /// String [httpStatusMessage] 状态描述文本
  ///
  /// String [tag] 自定义标记
  yaWebsocketDelegateOnOpen(
      String httpStatus, String httpStatusMessage, String? tag);

  /// 开始尝试连接时
  ///
  /// String [tag] 自定义标记
  yaWebsocketDelegateOnConnecting(String? tag);

  /// 收到信息时
  ///
  /// String [message] 信息内容
  ///
  /// String [tag] 自定义标记
  yaWebsocketDelegateOnMessage(String message, String? tag);

  /// 连接关闭时 (Android 和 iOS 返回信息可能有区别)
  ///
  /// String [code] 代码
  ///
  /// String [reason] 描述文本
  ///
  /// String [remote] 是否由远程关闭
  ///
  /// String [tag] 自定义标记
  yaWebsocketDelegateOnClose(
      String code, String reason, String remote, String? tag);

  /// 连接发生错误时 (Android 和 iOS 返回信息可能有区别)
  ///
  /// String [localizedMessage] 本地化描述文本
  ///
  /// String [message] 描述文本
  ///
  /// String [tag] 自定义标记
  yaWebsocketDelegateOnError(
      String localizedMessage, String? message, String? tag);
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
        delegate!.yaWebsocketDelegateOnOpen(arguments["httpStatus"],
            arguments["httpStatusMessage"], arguments["tag"] ?? null);
        break;
      case "onMessage":
        delegate!.yaWebsocketDelegateOnMessage(
            arguments["message"], arguments["tag"] ?? null);
        break;
      case "onClose":
        delegate!.yaWebsocketDelegateOnClose(arguments["code"],
            arguments["reason"], arguments["remote"], arguments["tag"] ?? null);
        break;
      case "onError":
        delegate!.yaWebsocketDelegateOnError(arguments["localizedMessage"],
            arguments["message"], arguments["tag"] ?? null);
        break;
      case "onConnecting":
        delegate!.yaWebsocketDelegateOnConnecting(arguments["tag"] ?? null);
        break;
      default:
        break;
    }
  }

  /// 重新连接
  /// 会重新连接上次连接过的webSocket连接
  Future<Map?> reconnect() async {
    final Map? info = await _methodChannel
        .invokeMethod('connect', {'uri': _uri, 'tag': _tag ?? ""});
    // info: Map<String, String>
    //   Keys: status(-1/0), info?
    return info;
  }

  /// 连接
  /// 根据[uri]连接webSocket
  ///
  /// String [uri] 连接地址
  ///
  /// String? [tag] 此连接的自定义标记
  Future<Map?> connect(String uri,
      {String tag = "", String timeout = "10"}) async {
    _uri = uri;
    _tag = tag;
    final Map? info = await _methodChannel
        .invokeMethod('connect', {'uri': uri, 'timeout': timeout, 'tag': tag});
    // info: Map<String, String>
    //   Keys: status(-1/0), info?
    return info;
  }

  /// 发送消息
  ///
  /// String? [text] 需发送的消息
  Future<Map?> send(String? text) async {
    final Map? info = await _methodChannel.invokeMethod('send', {'text': text});
    // info: Map<String, String>
    //   Keys: status(-1/0), info?
    return info;
  }

  /// 关闭连接
  Future<Map?> close() async {
    final Map? info = await _methodChannel.invokeMethod('close');
    // info: Map<String, String>
    //   Keys: status(-1/0), info?
    return info;
  }

  /// 判断是否正在保持连接
  Future<bool> get isOpen async {
    final Map? info = await _methodChannel.invokeMethod('isOpen');
    // info: Map<String, String>
    //   Keys: status(-1/0/1), info?
    if (info!['status'] == "1") {
      return true;
    }
    return false;
  }

  Future<String?> get platformVersion async {
    final String? version =
        await _methodChannel.invokeMethod('getPlatformVersion');
    return version;
  }
}
