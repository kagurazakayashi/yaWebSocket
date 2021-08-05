package moe.yashi.yawebsocket.ya_websocket

import android.util.Log
import io.flutter.plugin.common.MethodChannel
import org.java_websocket.client.WebSocketClient
import org.java_websocket.drafts.Draft_6455
import org.java_websocket.handshake.ServerHandshake

import java.net.URI
import java.util.HashMap


class YWebSocket(socketURI: URI?) : WebSocketClient(socketURI, Draft_6455()) {

    public lateinit var channel: MethodChannel
    public var tag: String = ""

    override fun onOpen(handshakedata: ServerHandshake) {
        var returnVal = HashMap<String, String>()
        if (tag.isNotEmpty()) {
            returnVal["tag"] = tag
        }
        returnVal["httpStatus"] = handshakedata.httpStatus.toString()
        returnVal["httpStatusMessage"] = handshakedata.httpStatusMessage
        channel.invokeMethod("onOpen", returnVal);
    }

        override fun onMessage(message: String) {
        var returnVal = HashMap<String, String>()
        if (tag.isNotEmpty()) {
            returnVal["tag"] = tag
        }
        returnVal["message"] = message
        channel.invokeMethod("onMessage", returnVal);
    }

    override fun onClose(code: Int, reason: String, remote: Boolean) {
        var returnVal = HashMap<String, String>()
        if (tag.isNotEmpty()) {
            returnVal["tag"] = tag
        }
        returnVal["code"] = code.toString()
        returnVal["reason"] = reason
        returnVal["remote"] = remote.toString()
        channel.invokeMethod("onClose", returnVal);
    }

    override fun onError(ex: Exception) {
        var returnVal = HashMap<String, String>()
        if (tag.isNotEmpty()) {
            returnVal["tag"] = tag
        }
        if (ex.message != null) {
            returnVal["message"] = ex.message!!
        }
        returnVal["localizedMessage"] = ex.localizedMessage
        channel.invokeMethod("onError", returnVal);
    }
}