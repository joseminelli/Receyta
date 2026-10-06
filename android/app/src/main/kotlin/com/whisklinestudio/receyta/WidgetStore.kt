package com.whisklinestudio.receyta

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
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

    /**
     * Redesenha todas as instâncias de um widget e avisa a lista (que rola) pra
     * reler os dados.
     */
    fun refreshAll(context: Context, provider: Class<*>, build: (Context, Int) -> RemoteViews) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, provider))
        for (id in ids) manager.updateAppWidget(id, build(context, id))
        manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_list)
    }

    /** Liga a lista que rola ao serviço que entrega as linhas. */
    fun attachList(context: Context, views: RemoteViews, id: Int, service: Class<*>) {
        val intent = Intent(context, service).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
        }
        views.setRemoteAdapter(R.id.widget_list, intent)
        views.setEmptyView(R.id.widget_list, R.id.widget_empty)
    }

    /** Toque no widget (cabeçalho, vazio ou uma linha da lista) abre o app. */
    fun openAppOnClick(context: Context, views: RemoteViews, rootId: Int) {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return
        val pi = PendingIntent.getActivity(
            context, 0, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(rootId, pi)
        views.setPendingIntentTemplate(R.id.widget_list, pi)
    }
}
