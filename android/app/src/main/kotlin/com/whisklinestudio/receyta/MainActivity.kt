package com.whisklinestudio.receyta

import io.flutter.embedding.android.FlutterActivity

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
}
