package moe.yashi.yawebsocket.ya_websocket

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.java_websocket.client.WebSocketClient
import org.java_websocket.drafts.Draft_6455
import org.java_websocket.handshake.ServerHandshake

import java.net.URI
import java.util.HashMap


class YWebSocket(socketURI: URI?) : WebSocketClient(socketURI, Draft_6455()) {

    public lateinit var eventChannelSink: EventChannel.EventSink
    public var tag: String = ""

    fun eventSuccess(returnVal: HashMap<String, String>) {
        if (tag.isNotEmpty()) {
            returnVal["tag"] = tag
        }
        Handler(Looper.getMainLooper()).post {
            eventChannelSink.success(returnVal)
        }
    }

    fun connecting() {
        var returnVal = HashMap<String, String>()
        returnVal["id"] = "onConnecting"
        eventSuccess(returnVal)
    }

    override fun onOpen(handshakedata: ServerHandshake) {
        var returnVal = HashMap<String, String>()
        returnVal["id"] = "onOpen"
        returnVal["httpStatus"] = handshakedata.httpStatus.toString()
        returnVal["httpStatusMessage"] = handshakedata.httpStatusMessage
        eventSuccess(returnVal)
    }

    override fun onMessage(message: String) {
        var returnVal = HashMap<String, String>()
        returnVal["id"] = "onMessage"
        returnVal["message"] = message
        eventSuccess(returnVal)
    }

    override fun onClose(code: Int, reason: String, remote: Boolean) {
        var returnVal = HashMap<String, String>()
        returnVal["id"] = "onClose"
        returnVal["code"] = code.toString()
        returnVal["reason"] = reason
        returnVal["remote"] = remote.toString()
        eventSuccess(returnVal)
    }

    override fun onError(ex: Exception) {
        var returnVal = HashMap<String, String>()
        returnVal["id"] = "onError"
        if (ex.message != null) {
            returnVal["message"] = ex.message!!
        }
        returnVal["localizedMessage"] = ex.localizedMessage
        eventSuccess(returnVal)
    }
}