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

  /// 使用 WebSocket 连接到 [uri] 。
  ///
  /// 可以单独设置 [tag] 此连接的自定义标记和 [timeout] 超时时间（秒）
  ///
  /// 返回值 ["status"] ：
  /// 0: 现在开始连接，请等待接口收到 `yaWebsocketDelegateOnOpen` 或 `yaWebsocketDelegateOnClose` 调用后再进行下一步；
  /// -1: 未能开始连接， ["info"] 提供错误信息描述。
  Future<Map?> connect(String uri,
      {String tag = "", String timeout = "10"}) async {
    _uri = uri;
    _tag = tag;
    final Map? info = await _methodChannel
        .invokeMethod('connect', {'uri': uri, 'timeout': timeout, 'tag': tag});
    return info;
  }

  /// 将消息 [text] 发送
  ///
  /// 返回值 ["status"] ：
  /// 0: 已发送；
  /// -1: 未发送， ["info"] 提供错误信息描述。
  Future<Map?> send(String? text) async {
    final Map? info = await _methodChannel.invokeMethod('send', {'text': text});
    // info: Map<String, String>
    //   Keys: status(-1/0), info?
    return info;
  }

  /// 关闭连接
  ///
  /// 返回值 ["status"] ：
  /// 0: 关闭成功或已经处于关闭状态，关闭成功接口将收到 `yaWebsocketDelegateOnClose` 调用；
  /// -1: 遇到问题， ["info"] 提供错误信息描述。
  Future<Map?> close() async {
    final Map? info = await _methodChannel.invokeMethod('close');
    // info: Map<String, String>
    //   Keys: status(-1/0), info?
    return info;
  }

  /// 判断是否正在保持连接
  ///
  /// 返回值 ["status"] ：
  /// 1: 已连接；
  /// 0: 未连接；
  /// -1: 未能查询， ["info"] 提供错误信息描述。
  Future<bool> get isOpen async {
    final Map? info = await _methodChannel.invokeMethod('isOpen');
    // info: Map<String, String>
    //   Keys: status(-1/0/1), info?
    if (info!['status'] == "1") {
      return true;
    }
    return false;
  }

  /// 获取操作系统版本信息
  Future<String?> get platformVersion async {
    final String? version =
        await _methodChannel.invokeMethod('getPlatformVersion');
    return version;
  }
}
