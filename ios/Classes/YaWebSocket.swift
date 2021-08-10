//
//  YaWebSocket.swift
//  ya_websocket
//
//  Created by 神楽坂雅詩 on 2021/8/10.
//

import Foundation
import Flutter
import Starscream

class YaWebSocket: WebSocketDelegate {
    
    var eventChannelSink: FlutterEventSink
    var tag: String = ""
    var socket: WebSocket
    var isConnect = false
    var timeoutTimer : Timer?
    var timeout:TimeInterval = 10.0
    
    init(uri:URL, eventSink: @escaping FlutterEventSink) {
        eventChannelSink = eventSink
        var request = URLRequest(url: uri)
        request.timeoutInterval = timeout
        socket = WebSocket(request: request)
        socket.delegate = self
        //websocketDidConnect
    }
    
    func send(text:String) {
        socket.write(string: text)
    }
    
    func connect(sw:Bool = true) {
        if (sw) {
            socket.connect()
            timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout+0.1, repeats: false) { timer in
                if (self.isConnect == false) {
                    self.socket.disconnect()
                    self.onError(ex: URLError(URLError.Code.timedOut))
                    self.onClose(code: -1, reason: "", remote: false)
                }
                timer.invalidate()
            }
        } else {
            socket.disconnect()
        }
    }
    
    func connecting() {
        var returnVal : [String:String] = ["id":"onConnecting"]
        if (!self.tag.isEmpty) {
            returnVal["tag"] = tag
        }
        isConnect = false
        DispatchQueue.main.async {
            self.eventChannelSink(returnVal)
        }
    }
    
    func onOpen(handshakedata:[String: String]) {
        var returnVal : [String:String] = ["id":"onOpen"]
        if (!self.tag.isEmpty) {
            returnVal["tag"] = tag
        }
        returnVal["httpStatus"] = "000"
        returnVal["httpStatusMessage"] = "000"
        isConnect = true
        DispatchQueue.main.async {
            self.eventChannelSink(returnVal)
        }
    }
    
    func onMessage(message:String) {
        var returnVal : [String:String] = [
            "id":"onMessage",
            "message":message
        ]
        if (!self.tag.isEmpty) {
            returnVal["tag"] = tag
        }
        isConnect = true
        DispatchQueue.main.async {
            self.eventChannelSink(returnVal)
        }
    }
    
    func onClose(code:Int, reason:String, remote:Bool)  {
        var returnVal : [String:String] = [
            "id":"onClose",
            "code":String(code),
            "reason":reason,
            "remote":String(remote)
        ]
        if (!self.tag.isEmpty) {
            returnVal["tag"] = tag
        }
        isConnect = false
        DispatchQueue.main.async {
            self.eventChannelSink(returnVal)
        }
    }
    
    func onError(ex:Error?) {
        var returnVal : [String:String] = ["id":"onError"]
        if (!self.tag.isEmpty) {
            returnVal["tag"] = tag
        }
        if (ex != nil) {
            returnVal["message"] = String(describing: ex)
            returnVal["localizedMessage"] = String(describing: ex?.localizedDescription)
        } else {
            returnVal["localizedMessage"] = ""
        }
        isConnect = false
        DispatchQueue.main.async {
            self.eventChannelSink(returnVal)
        }
    }
    
    func onCancelled() {
        var returnVal : [String:String] = ["id":"onCancelled"]
        if (!self.tag.isEmpty) {
            returnVal["tag"] = tag
        }
        isConnect = false
        DispatchQueue.main.async {
            self.eventChannelSink(returnVal)
        }
    }
    
    // MARK: WebSocketDelegate
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            onOpen(handshakedata: headers)
        case .disconnected(let reason, let code):
            onClose(code: Int(code), reason: reason, remote: true)
        case .text(let text):
            onMessage(message: text)
        case .binary(let data):
            print("data \(data.count)")
        case .cancelled:
            onClose(code: 0, reason: "", remote: false)
        case .error(let error):
            onError(ex: error)
        default:
            print("event?")
            print(event)
            break
        }
    }
}
