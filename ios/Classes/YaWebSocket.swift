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
    var socket: WebSocket?
    var isConnect = false
    var timeoutTimer : Timer?
    var timeout:TimeInterval = 10.0
    var notified = false
    var isclose = false
    
    init(eventSink: @escaping FlutterEventSink) {
        eventChannelSink = eventSink
    }
    
    func send(text:String) {
        socket!.write(string: text)
    }
    
    func connect(uri:URL) {
        if (socket == nil) {
            var request = URLRequest(url: uri)
            request.timeoutInterval = timeout + 1
            socket = WebSocket(request: request)
            socket!.delegate = self
        }
        notified = false
        socket!.connect()
        stopTimer()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { timer in
            if (self.isConnect == false) {
                self.disconnect()
                self.unload()
                self.onError(ex:    URLError(URLError.Code.timedOut))
                self.onClose(code: -1, reason: "timedOut", remote: false)
            }
            self.stopTimer()
        }
    }
    
    func disconnect() {
        isConnect = false
        if (socket != nil) {
            socket!.disconnect()
            stopTimer()
            timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { timer in
                self.socket!.forceDisconnect()
                self.isConnect = false
                self.unload()
                self.onClose(code: -2, reason: "forceDisconnect", remote: false)
                self.stopTimer()
            }
        }
    }
    
    func unload() {
        if (socket != nil) {
            socket!.delegate = nil
            socket = nil
        }
    }
    
    func sent(text:String) -> Bool {
        if (socket == nil || !isConnect) {
            return false
        }
        socket!.write(string: text);
        return true
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
        isclose = false
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
        if (!isclose) {
            if (code == 0) {
                isclose = true
            }
            let returnVal : [String:String] = [
                "id":"onClose",
                "code":String(code),
                "reason":reason,
                "remote":String(remote)
            ]
            isConnect = false
            self.eventSuccess(returnVal: returnVal)
        }
    }
    
    func onError(ex:Error?) {
        var returnVal : [String:String] = ["id":"onError"]
        if (ex != nil) {
            returnVal["message"] = String(describing: ex)
            returnVal["localizedMessage"] = String(describing: ex!.localizedDescription)
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
    
    func stopTimer() {
        if (timeoutTimer != nil) {
            timeoutTimer?.invalidate()
            timeoutTimer = nil
        }
    }
    
    // MARK: WebSocketDelegate
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        stopTimer()
        switch event {
        case .connected(let headers):
            onOpen(handshakedata: headers)
        case .disconnected(let reason, let code):
            if (notified == true) {
                break
            }
            notified = true
            onClose(code: Int(code), reason: reason, remote: true)
            unload()
        case .text(let text):
            onMessage(message: text)
        case .binary(let data):
            print("data \(data.count)")
        case .cancelled:
            if (notified == true) {
                break
            }
            notified = true
            onClose(code: 0, reason: "", remote: false)
            unload()
        case .error(let error):
            if (notified == true) {
                break
            }
            notified = true
            onError(ex: error)
            unload()
        case .viabilityChanged(_): // let isChanged
            break
        case .reconnectSuggested(_): // let isSuggested
            if (notified == true) {
                break
            }
            notified = true
            onClose(code: 1006, reason: "reconnectSuggested", remote: false)
            unload()
        default:
            print("event?",event)
            break
        }
    }
}
