package com.whisklinestudio.receyta

import android.app.PendingIntent
import android.content.Context
import android.widget.RemoteViews
import org.json.JSONObject

/**
 * Dados compartilhados pelos widgets da tela inicial. Vêm do Dart (canal
 * `receyta/home_widget`) e ficam em SharedPreferences; cada widget filtra o
 * que precisa na hora de desenhar, pra o dia virar sem o app aberto.
 */
object WidgetStore {
    private const val PREFS = "receyta_widget"
    private const val KEY = "payload"

    fun save(context: Context, json: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY, json).apply()
        TodayWidgetProvider.refresh(context)
        ShoppingWidgetProvider.refresh(context)
    }

    fun read(context: Context): JSONObject? {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY, null) ?: return null
        return try { JSONObject(raw) } catch (e: Exception) { null }
    }

    /** Toque em qualquer ponto do widget abre o app. */
    fun openAppOnClick(context: Context, views: RemoteViews, rootId: Int) {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return
        val pi = PendingIntent.getActivity(
            context, 0, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(rootId, pi)
    }
}
