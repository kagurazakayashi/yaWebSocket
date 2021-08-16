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
    
    func connect() {
        socket.connect()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout+0.1, repeats: false) { timer in
            if (self.isConnect == false) {
                self.socket.disconnect()
                self.onError(ex: URLError(URLError.Code.timedOut))
                self.onClose(code: -1, reason: "", remote: false)
            }
            timer.invalidate()
        }
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    func eventSuccess(returnVal : [String:String]) {
        var rVal : [String:String] = returnVal
        if (!self.tag.isEmpty) {
            rVal["tag"] = tag
        }
        DispatchQueue.main.async {
            self.eventChannelSink(rVal)
        }
    }
    
    func connecting() {
        let returnVal : [String:String] = ["id":"onConnecting"]
        isConnect = false
        self.eventSuccess(returnVal: returnVal)
    }
    
    func onOpen(handshakedata:[String: String]) {
        let returnVal : [String:String] = [
            "id":"onOpen",
            "httpStatus":"101",
            "httpStatusMessage":"Switching Protocols"
        ]
        isConnect = true
        self.eventSuccess(returnVal: returnVal)
    }
    
    func onMessage(message:String) {
        let returnVal : [String:String] = [
            "id":"onMessage",
            "message":message
        ]
        isConnect = true
        self.eventSuccess(returnVal: returnVal)
    }
    
    func onClose(code:Int, reason:String, remote:Bool)  {
        let returnVal : [String:String] = [
            "id":"onClose",
            "code":String(code),
            "reason":reason,
            "remote":String(remote)
        ]
        isConnect = false
        self.eventSuccess(returnVal: returnVal)
    }
    
    func onError(ex:Error?) {
        var returnVal : [String:String] = ["id":"onError"]
        if (ex != nil) {
            returnVal["message"] = String(describing: ex)
            returnVal["localizedMessage"] = String(describing: ex?.localizedDescription)
        } else {
            returnVal["localizedMessage"] = ""
        }
        isConnect = false
        self.eventSuccess(returnVal: returnVal)
    }
    
    func onCancelled() {
        let returnVal : [String:String] = ["id":"onCancelled"]
        isConnect = false
        self.eventSuccess(returnVal: returnVal)
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
        // case .viabilityChanged(_): // let isChanged
        // onClose(code: -1, reason: "viabilityChanged", remote: false)
        case .reconnectSuggested(_): // let isSuggested
            onClose(code: 1006, reason: "reconnectSuggested", remote: false)
        default:
            print("event?")
            print(event)
            break
        }
    }
}
