package moe.yashi.yawebsocket.ya_websocket

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import org.java_websocket.client.WebSocketClient
import org.java_websocket.drafts.Draft_6455
import org.java_websocket.handshake.ServerHandshake
import java.net.URI
import java.util.*

/** YaWebsocketPlugin */
class YaWebsocketPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private var client: YWebSocket? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ya_websocket")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "connect" -> connect(call, result)
            "send" -> send(call, result)
            "close" -> close(call, result)
            "isOpen" -> isOpen(call, result)
            else -> result.notImplemented()
        }
    }

    private fun connect(@NonNull call: MethodCall, @NonNull result: Result) {
        var returnVal = HashMap<String, String>()
        var uri: URI = URI.create(call.argument("text"))
        var tag: String? = call.argument("tag")
        try {
            client = YWebSocket(uri)
            if (client == null) {
                returnVal["status"] = "-1"
                result.success(returnVal)
                return
            }
            client!!.channel = channel
            if (tag != null) {
                client!!.tag = tag
            }
            client!!.connectBlocking()
            returnVal["status"] = "0"
            result.success(returnVal)
        } catch (e: Exception) {
            returnVal["status"] = "-1"
            returnVal["info"] = e.localizedMessage
            // e.printStackTrace()
            result.success(returnVal)
        }
    }

    private fun send(@NonNull call: MethodCall, @NonNull result: Result) {
        var returnVal = HashMap<String, String>()
        var text: String? = call.argument("text");
        if (client == null) {
            returnVal["status"] = "-1"
            result.success(returnVal)
            return
        }
        try {
            client!!.send(text)
            returnVal["status"] = "0"
            result.success(returnVal)
        } catch (e: Exception) {
            returnVal["status"] = "-1"
            returnVal["info"] = e.localizedMessage
            result.success(returnVal)
        }
    }

    private fun close(@NonNull call: MethodCall, @NonNull result: Result) {
        var returnVal = HashMap<String, String>()
        if (client == null) {
            returnVal["status"] = "-1"
            result.success(returnVal)
            return
        }
        try {
            client!!.close()
            returnVal["status"] = "0"
            result.success(returnVal)
        } catch (e: Exception) {
            returnVal["status"] = "-1"
            returnVal["info"] = e.localizedMessage
            result.success(returnVal)
        }
    }

    private fun isOpen(@NonNull call: MethodCall, @NonNull result: Result) {
        var returnVal = HashMap<String, String>()
        if (client == null) {
            returnVal["status"] = "-1"
            result.success(returnVal)
            return
        }
        try {
            if (client!!.isOpen) {
                returnVal["status"] = "1"
            } else {
                returnVal["status"] = "0"
            }
            result.success(returnVal)
        } catch (e: Exception) {
            returnVal["status"] = "-1"
            returnVal["info"] = e.localizedMessage
            result.success(returnVal)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
