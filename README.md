# ya_websocket

一个使用 iOS 和 Android 上原生库进行 WebSocket 通信的 Flutter 插件。

|  平 台  | Flutter 插件语言 | 原生端使用的库 | 库版本 | 库使用的语言 |
| ------- | ---------------- | -------------- | ------ | ------------ |
| iOS     |      Kotlin      |[Java-WebSocket](https://github.com/TooTallNate/Java-WebSocket)| 1.5.2  |    Java      |
| Android |      Swift       |   [Starscream](https://github.com/daltoniam/Starscream)   | 4.0.4  |    Swift     |

## 系统版本要求

|  平 台  | 可运行最低版本 | 推荐最低版本 |
| ------- | -------------- | ------------ |
| Flutter |       2        |     2.2.3    |
| iOS     |       10       |      14      |
| Android |       4.1      |      11      |

## 使用

1. 导入包： `import 'package:ya_websocket/main.dart';`
2. 在需要的类中实现接口 `class ... implements YaWebsocketDelegate`，实现以下接口：
  - 已连接时
    - `yaWebsocketDelegateOnOpen(String httpStatus, String httpStatusMessage, String? tag);`
    - 参数说明：HTTP 状态码，状态描述文本，自定义标记
  - 开始尝试连接时
    - `yaWebsocketDelegateOnConnecting(String? tag);`
    - 参数说明：自定义标记
  - 收到信息时
    - `yaWebsocketDelegateOnMessage(String message, String? tag);`
    - 参数说明：信息内容，自定义标记
  - 连接关闭时 (Android 和 iOS 返回信息可能有区别)
    - `yaWebsocketDelegateOnClose(String code, String reason, String remote, String? tag);`
    - 参数说明：代码，描述文本，是否由远程关闭，自定义标记
  - 连接发生错误时 (Android 和 iOS 返回信息可能有区别)
    - `yaWebsocketDelegateOnError(String localizedMessage, String? message, String? tag);`
    - 参数说明：本地化描述文本，描述文本，自定义标记
3. 创建对象： `YaWebsocket websocket = YaWebsocket();`
4. 指定接口实现类： 

TODO
