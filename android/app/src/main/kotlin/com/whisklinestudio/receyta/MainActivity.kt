package com.whisklinestudio.receyta

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    // `FlutterActivity` por padrão usa `intent.dataString` como rota inicial
    // quando o app é aberto por um ACTION_VIEW (nosso intent-filter do
    // `.receyta`, D5) — o GoRouter tentava navegar direto pra uma URI tipo
    // `content://com.whatsapp.provider.media/item/...` como se fosse uma
    // rota, e caía na tela de "Página não encontrada". Fixando sempre em
    // "/", o app sempre abre normal (splash → home); o arquivo compartilhado
    // é lido à parte pelo `receive_sharing_intent` (canal próprio, não a
    // rota inicial).
    override fun getInitialRoute(): String = "/"

    // Modo cozinha: com a captura ligada, os botões de volume viram "passo
    // seguinte / anterior" e o volume do aparelho não muda. O Dart liga ao
    // abrir o modo cozinha e desliga ao sair.
    private var volumeChannel: MethodChannel? = null
    private var volumeKeysEnabled = false

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val code = event.keyCode
        if (volumeKeysEnabled &&
            (code == KeyEvent.KEYCODE_VOLUME_UP || code == KeyEvent.KEYCODE_VOLUME_DOWN)
        ) {
            if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
                volumeChannel?.invokeMethod(
                    "key",
                    if (code == KeyEvent.KEYCODE_VOLUME_UP) "up" else "down"
                )
            }
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        volumeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "receyta/volume_keys")
        volumeChannel?.setMethodCallHandler { call, result ->
            if (call.method == "setEnabled") {
                volumeKeysEnabled = call.arguments as? Boolean ?: false
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "receyta/home_widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "update") {
                    val map = call.arguments as? Map<*, *>
                    if (map != null) {
                        WidgetStore.save(applicationContext, JSONObject(map).toString())
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
