package com.whisklinestudio.receyta

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Widget "Hoje": refeições do dia e resumo das compras. Os dados vêm do Dart
 * (canal `receyta/home_widget`) e ficam em SharedPreferences; o filtro de
 * "hoje" é feito aqui, pra virar o dia sem o app aberto.
 */
class TodayWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, build(context))
    }

    companion object {
        private const val PREFS = "receyta_widget"
        private const val KEY = "payload"

        fun save(context: Context, json: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putString(KEY, json).apply()
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, TodayWidgetProvider::class.java))
            for (id in ids) manager.updateAppWidget(id, build(context))
        }

        private fun build(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_today)
            val now = Date()
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(now)
            views.setTextViewText(
                R.id.widget_date,
                SimpleDateFormat("EEE, d MMM", Locale("pt", "BR")).format(now)
            )

            val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
            val json = try { raw?.let { JSONObject(it) } } catch (e: Exception) { null }

            val lines = ArrayList<String>()
            val meals = json?.optJSONArray("meals")
            if (meals != null) {
                for (i in 0 until meals.length()) {
                    val m = meals.getJSONObject(i)
                    if (m.optString("date") != today) continue
                    val mark = if (m.optBoolean("done")) "✓ " else ""
                    lines.add(mark + m.optString("meal") + " · " + m.optString("name"))
                }
            }

            val slots = intArrayOf(R.id.widget_meal1, R.id.widget_meal2, R.id.widget_meal3)
            if (lines.isEmpty()) {
                val empty = if (json == null) "Abra o Receyta pra começar" else "Nada planejado pra hoje"
                views.setTextViewText(slots[0], empty)
                views.setTextViewText(slots[1], "")
                views.setTextViewText(slots[2], "")
            } else {
                for (i in slots.indices) {
                    val text = if (i == 2 && lines.size > 3) {
                        "+" + (lines.size - 2) + " refeições"
                    } else {
                        lines.getOrNull(i) ?: ""
                    }
                    views.setTextViewText(slots[i], text)
                }
            }

            val pending = json?.optInt("shoppingPending", 0) ?: 0
            val shop = if (json == null) {
                "Compras"
            } else if (pending == 0) {
                "Compras: nada pendente"
            } else {
                val name = json.optString("shoppingList")
                val lists = json.optInt("shoppingLists", 1)
                val items = if (pending == 1) "1 item" else "$pending itens"
                if (lists > 1) "Compras: $items em $lists listas" else "Compras: $items · $name"
            }
            views.setTextViewText(R.id.widget_shopping, shop)

            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launch != null) {
                val pi = PendingIntent.getActivity(
                    context, 0, launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pi)
            }
            return views
        }
    }
}
