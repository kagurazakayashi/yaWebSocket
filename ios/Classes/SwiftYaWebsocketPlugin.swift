import Flutter
import UIKit
import Starscream

public class SwiftYaWebsocketPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    var eventChannelSink : FlutterEventSink?
    var webSocket : YaWebSocket?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftYaWebsocketPlugin()
        let methodChannel = FlutterMethodChannel(name: "ya_websocket_m", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        let eventChannel = FlutterEventChannel(name: "ya_websocket_e", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            break
        case "connect":
            connect(call: call, result: result)
            break
        case "send":
            send(call: call, result: result)
        case "close":
            close(call: call, result: result)
        case "isOpen":
            isOpen(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
    
    func toResult(result: @escaping FlutterResult, returnVal:[String:String] = ["status":"-1"]) {
        DispatchQueue.main.async {
            result(returnVal)
        }
    }
    
    func connect(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args:[String:String] = call.arguments! as! [String : String]
        guard let uri:String = args["uri"] else {
            toResult(result: result)
            return
        }
        guard let url:URL = URL(string: uri) else {
            toResult(result: result)
            return
        }
        if (eventChannelSink == nil) {
            toResult(result: result)
            return
        }
        webSocket = YaWebSocket(uri: url, eventSink: eventChannelSink!)
        if (args.keys.contains("timeout")) {
            let timeStr:String = args["timeout"]!
            webSocket!.timeout = TimeInterval(timeStr)!
        }
        if (args.keys.contains("tag")) {
            let tag:String = args["tag"]!
            webSocket!.tag = tag
        }
        webSocket!.connecting()
        webSocket!.connect()
        toResult(result: result, returnVal: ["status":"0"])
    }
    
    func send(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args:[String:String] = call.arguments! as! [String : String]
        guard let text:String = args["text"] else {
            toResult(result: result)
            return
        }
        webSocket!.socket.write(string: text);
        toResult(result: result, returnVal: ["status":"0"])
    }
    
    func close(call: FlutterMethodCall, result: @escaping FlutterResult) {
        webSocket!.connect(sw: false)
        toResult(result: result, returnVal: ["status":"0"])
    }
    
    func isOpen(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (webSocket!.isConnect == true) {
            toResult(result: result, returnVal: ["status":"1"])
        } else {
            toResult(result: result, returnVal: ["status":"0"])
        }
    }
    
    // MARK: - FlutterStreamHandler
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventChannelSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventChannelSink = nil
        return nil
    }
}
