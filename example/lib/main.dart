import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ya_websocket/main.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> implements YaWebsocketDelegate {
  String _platformVersion = 'Unknown';


  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    YaWebsocket websocket = YaWebsocket(this);
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await websocket.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }

  @override
  yaWebsocketDelegateOnClose(String code, String reason, String remote, String? tag) {
    throw UnimplementedError();
  }

  @override
  yaWebsocketDelegateOnError(String localizedMessage, String? message, String? tag) {
    throw UnimplementedError();
  }

  @override
  yaWebsocketDelegateOnMessage(String message, String? tag) {
    throw UnimplementedError();
  }

  @override
  yaWebsocketDelegateOnOpen(String httpStatus, String httpStatusMessage, String? tag) {
    throw UnimplementedError();
  }
}
