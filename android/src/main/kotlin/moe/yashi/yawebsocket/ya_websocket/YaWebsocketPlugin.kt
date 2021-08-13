package moe.yashi.yawebsocket.ya_websocket

import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import org.java_websocket.client.WebSocketClient
import org.java_websocket.drafts.Draft_6455
import org.java_websocket.handshake.ServerHandshake
import java.net.URI
import java.util.*
import kotlin.math.log

/** YaWebsocketPlugin */
class YaWebsocketPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var _methodChannel: MethodChannel
    private lateinit var _eventChannel: EventChannel
    private var _webSocket: YWebSocket? = null
    private var _eventChannelSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        _methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "ya_websocket_m")
        _methodChannel.setMethodCallHandler(this)
        _eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "ya_websocket_e")
        _eventChannel.setStreamHandler(this)
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

    private fun toResult(@NonNull result: Result, returnVal: HashMap<String, String>? = null) {
        var rVal = HashMap<String, String>()
        if (returnVal == null) {
            rVal["status"] = "-1"
        } else {
            rVal = returnVal
        }
        Handler(Looper.getMainLooper()).post {
            result.success(rVal)
        }
    }

    private fun connect(@NonNull call: MethodCall, @NonNull result: Result) {
        var returnVal = HashMap<String, String>()
        var uri: URI = URI.create(call.argument("uri"))
        var tag: String? = call.argument("tag")
        var timeout: String? = call.argument("timeout")
        try {
            _webSocket = YWebSocket(uri)
            if (_webSocket == null || _eventChannelSink == null || _webSocket!!.isOpen) {
                this.toResult(result)
                return
            }
            _webSocket!!.eventChannelSink = _eventChannelSink!!
            if (tag != null) {
                _webSocket!!.tag = tag
            }
            if (timeout != null) {
                _webSocket!!.connectionLostTimeout = timeout.toInt()
            } else {
                _webSocket!!.connectionLostTimeout = 10
            }
            _webSocket!!.connecting()
            _webSocket!!.connect()
//            client!!.connectBlocking()
            returnVal["status"] = "0"
            toResult(result, returnVal)
        } catch (e: Exception) {
            returnVal["status"] = "-1"
            returnVal["info"] = e.localizedMessage
            // e.printStackTrace()
            toResult(result, returnVal)
        }
    }

    private fun send(@NonNull call: MethodCall, @NonNull result: Result) {
        var returnVal = HashMap<String, String>()
        var text: String? = call.argument("text");
        if (_webSocket == null || !_webSocket!!.isOpen) {
            toResult(result)
            return
        }
        try {
            _webSocket!!.send(text)
            returnVal["status"] = "0"
            toResult(result, returnVal)
        } catch (e: Exception) {
            returnVal["status"] = "-1"
            returnVal["info"] = e.localizedMessage
            toResult(result, returnVal)
        }
    }

    private fun close(@NonNull call: MethodCall, @NonNull result: Result) {
        var returnVal = HashMap<String, String>()
        if (_webSocket == null || !_webSocket!!.isOpen) {
            toResult(result)
            return
        }
        try {
            _webSocket!!.close()
            _webSocket = null
            returnVal["status"] = "0"
            toResult(result, returnVal)
        } catch (e: Exception) {
            returnVal["status"] = "-1"
            returnVal["info"] = e.localizedMessage
            toResult(result, returnVal)
        }
    }

    private fun isOpen(@NonNull call: MethodCall, @NonNull result: Result) {
        var returnVal = HashMap<String, String>()
        if (_webSocket == null) {
            toResult(result)
            return
        }
        try {
            if (_webSocket!!.isOpen) {
                returnVal["status"] = "1"
            } else {
                returnVal["status"] = "0"
            }
            toResult(result, returnVal)
        } catch (e: Exception) {
            returnVal["status"] = "-1"
            returnVal["info"] = e.localizedMessage
            toResult(result, returnVal)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        _methodChannel.setMethodCallHandler(null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        _eventChannelSink = events
    }

    override fun onCancel(arguments: Any?) {
        _eventChannelSink = null
    }
}
