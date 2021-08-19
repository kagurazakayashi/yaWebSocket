import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:ya_websocket/ya_websocket.dart';

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
  String _title = "点按屏幕下方橙色区域输入";
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    initPlatformState().whenComplete(() {});
    _textFController = TextEditingController(text: '');
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
    Map? info = await _websocket.connect(toURI, tag: toTAG);
    if (info!["status"] == "-1") {
      setState(() {
        _data.add(
            [false, "未能连接 " + (info.containsKey("info") ? info["info"] : "")]);
      });
      isOK = false;
    }
    return isOK;
  }

  @override
  yaWebsocketDelegateOnClose(
      String code, String reason, String remote, String? tag) {
    setState(() {
      _isConnect = false;
      _data.add([
        false,
        "连接已被关闭( $remote , $code ) $reason ，请输入新的连接地址或按右上角按钮重新连接到上次的服务器。"
      ]);
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
      _data
          .add([false, "连接已建立( $httpStatus ): $httpStatusMessage 。请输入要发送的消息。"]);
    });
  }

  @override
  yaWebsocketDelegateOnConnecting(String? tag) {
    setState(() {
      _data.add([false, "正在连接 $tag ($_webSocketURI) ，请不要进行其他操作。"]);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_data.length > 0 &&
        _scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > _scrollController.offset) {
      // print("================");
      // print(_scrollController.position.maxScrollExtent);
      // print(_scrollController.offset);
      // print(_scrollController.position);
      // print("================");
      Timer(
        Duration(milliseconds: 500),
        () => _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.ease,
        ),
      );
    }
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          actions: [
            IconButton(
              onPressed: () async {
                if (await _websocket.isOpen) {
                  close();
                } else {
                  reconnect();
                }
              },
              icon: Icon(
                _isConnect ? Icons.link_off : Icons.link,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
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
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        nip: _data[i][0]
                            ? BubbleNip.rightBottom
                            : BubbleNip.leftBottom,
                        color: _data[i][0]
                            ? Color.fromRGBO(225, 255, 199, 1.0)
                            : Color.fromRGBO(212, 234, 244, 1.0),
                        child: Text(
                          _data[i][1],
                          textAlign:
                              _data[i][0] ? TextAlign.right : TextAlign.left,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              height: 50,
              color: Colors.deepOrange,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textFController,
                      onSubmitted: (value) {
                        setState(() {
                          _data.add([true, value]);
                        });
                        if (value.length >= 5 &&
                            value.substring(0, 5) == "ws://") {
                          connect(value, _webSocketTAG);
                        } else {
                          send(value);
                        }
                        _textFController.text = "";
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _textFController.text = '';
                    },
                    icon: Icon(Icons.clear, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () {
                      String value = _textFController.text;
                      setState(() {
                        _data.add([true, value]);
                      });
                      if (value.length >= 5 &&
                          value.substring(0, 5) == "ws://") {
                        connect(value, _webSocketTAG);
                      } else {
                        send(value);
                      }
                      _textFController.text = "";
                    },
                    icon: Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
