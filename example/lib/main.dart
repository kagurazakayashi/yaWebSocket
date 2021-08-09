import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:ya_websocket/main.dart';

import 'package:bubble/bubble.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> implements YaWebsocketDelegate {
  String _webSocketURI = ''; // ws://192.168.1.46:8866/chat?user_id=1
  String _webSocketTAG = '0';
  late TextEditingController _textFController;
  List _data = [];
  bool _isConnect = false;
  late YaWebsocket _websocket;
  String _title = "点按屏幕下方蓝色区域输入";

  @override
  void initState() {
    initPlatformState().whenComplete(() {});
    _textFController =
        TextEditingController(text: '{"sub setpoint":[[1,2,3],[1,3],1]}');
    _websocket = YaWebsocket();
    _websocket.delegate = this;
    if (_webSocketURI.length > 0) {
      connect(_webSocketURI, _webSocketTAG);
    } else {
      setState(() {
        _textFController.text = "ws://";
        _data.add([false, "请输入连接地址，以 ws:// 开头。"]);
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    _textFController.dispose();
    _websocket.close();
    super.dispose();
  }

  Future<void> initPlatformState() async {
    // String platformVersion;
    // try {
    //   platformVersion =
    //       await websocket.platformVersion ?? 'Unknown platform version';
    // } on PlatformException {
    //   platformVersion = 'Failed to get platform version.';
    // }
    // if (!mounted) return;
    // setState(() {
    //   _platformVersion = platformVersion;
    //   // child: Text('Running on: $_platformVersion\n'),
    // });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: Text(_title),
            actions: [
              IconButton(
                  onPressed: () async {
                    if (await isOpen()) {
                      close();
                    } else {
                      reconnect();
                    }
                  },
                  icon: _isConnect ? Icon(Icons.link_off) : Icon(Icons.link))
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _data.length, //data.length*2-1,
                  itemBuilder: (context, i) {
                    // if (i.isOdd) return new Divider();
                    // final index = i ~/ 2;
                    return Container(
                      child: InkWell(
                        onLongPress: () {
                          _textFController.text = _data[i][1].toString();
                        },
                        child: Bubble(
                          margin: BubbleEdges.only(top: 10),
                          alignment: _data[i][0]
                              ? Alignment.topRight
                              : Alignment.topLeft,
                          nip: _data[i][0]
                              ? BubbleNip.rightTop
                              : BubbleNip.leftTop,
                          color: _data[i][0]
                              ? Color.fromRGBO(225, 255, 199, 1.0)
                              : Color.fromRGBO(212, 234, 244, 1.0),
                          child: Text(_data[i][1],
                              textAlign: _data[i][0]
                                  ? TextAlign.right
                                  : TextAlign.left),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                height: 50,
                color: Colors.blueAccent,
                child: TextField(
                  controller: _textFController,
                  onSubmitted: (value) {
                    setState(() {
                      _data.add([true, value]);
                    });
                    if (value.substring(0, 5) == "ws://") {
                      connect(value, _webSocketTAG);
                    } else {
                      send(value);
                    }
                    _textFController.text = "";
                  },
                ),
              ),
            ],
          )),
    );
  }

  Future<bool> send(String text) async {
    bool isOK = true;
    Map? info = await _websocket.send(text);
    if (info!["status"] == "-1") {
      setState(() {
        _data.add(
            [false, "发送失败 " + (info.containsKey("info") ? info["info"] : "")]);
      });
      isOK = false;
    }
    return isOK;
  }

  Future<bool> close() async {
    bool isOK = true;
    setState(() {
      _data.add([false, "正在断开..."]);
    });
    Map? info = await _websocket.close();
    if (info!["status"] == "-1") {
      setState(() {
        _data.add([
          false,
          "断开时出现异常 " + (info.containsKey("info") ? info["info"] : "")
        ]);
      });
      isOK = false;
    }
    return isOK;
  }

  Future<bool> reconnect() async {
    bool isOK = true;
    setState(() {
      _data.add([false, "正在尝试连接到上次的地址..."]);
    });
    Map? info = await _websocket.reconnect();
    if (info!["status"] == "-1") {
      setState(() {
        _data.add(
            [false, "未能连接 " + (info.containsKey("info") ? info["info"] : "")]);
      });
      isOK = false;
    }
    return isOK;
  }

  Future<bool> connect(String toURI, String toTAG) async {
    bool isOK = true;
    setState(() {
      _title = toURI;
      _data.add([false, "现在开始尝试连接 $toURI ..."]);
    });
    Map? info = await _websocket.connect(toURI, toTAG);
    if (info!["status"] == "-1") {
      setState(() {
        _data.add(
            [false, "未能连接 " + (info.containsKey("info") ? info["info"] : "")]);
      });
      isOK = false;
    }
    return isOK;
  }

  Future<bool> isOpen() async {
    bool isLinked = false;
    Map? openInfo = await _websocket.isOpen();
    if (openInfo != null && openInfo["status"] == "1") {
      isLinked = true;
    }
    return isLinked;
  }

  @override
  yaWebsocketDelegateOnClose(
      String code, String reason, String remote, String? tag) {
    setState(() {
      _isConnect = false;
      _data.add([false, "连接已被关闭( $remote , $code ) $reason ，请输入新的连接地址或按右上角按钮重新连接到上次的服务器。"]);
    });
  }

  @override
  yaWebsocketDelegateOnError(
      String localizedMessage, String? message, String? tag) {
    setState(() {
      _data.add([false, "发生错误: $localizedMessage ."]);
    });
  }

  @override
  yaWebsocketDelegateOnMessage(String message, String? tag) {
    setState(() {
      _data.add([false, message]);
    });
  }

  @override
  yaWebsocketDelegateOnOpen(
      String httpStatus, String httpStatusMessage, String? tag) {
    setState(() {
      _isConnect = true;
      _data.add([false, "连接已建立( $httpStatus ): $httpStatusMessage 。请输入要发送的消息。"]);
    });
  }

  @override
  yaWebsocketDelegateOnConnecting(String? tag) {
    setState(() {
      _data.add([false, "正在连接 $tag ($_webSocketURI) ，请不要进行其他操作。"]);
    });
  }
}
