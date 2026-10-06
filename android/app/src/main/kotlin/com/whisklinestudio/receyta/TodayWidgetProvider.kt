package com.whisklinestudio.receyta

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Widget "Hoje": as receitas planejadas pro dia, com a refeição de cada uma e
 * as já feitas marcadas.
 */
class TodayWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, build(context))
    }

    companion object {
        private const val MAX_ROWS = 4

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, TodayWidgetProvider::class.java))
            for (id in ids) manager.updateAppWidget(id, build(context))
        }

        private class Meal(val label: String, val name: String, val done: Boolean)

        private fun build(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_today)
            val locale = Locale("pt", "BR")
            val now = Date()
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(now)
            views.setTextViewText(
                R.id.widget_weekday,
                SimpleDateFormat("EEEE", locale).format(now).uppercase(locale)
            )
            views.setTextViewText(
                R.id.widget_date,
                SimpleDateFormat("d 'de' MMMM", locale).format(now)
            )

            val json = WidgetStore.read(context)
            val meals = ArrayList<Meal>()
            val array = json?.optJSONArray("meals")
            if (array != null) {
                for (i in 0 until array.length()) {
                    val m = array.getJSONObject(i)
                    if (m.optString("date") != today) continue
                    meals.add(Meal(m.optString("meal"), m.optString("name"), m.optBoolean("done")))
                }
            }

            val rows = intArrayOf(R.id.widget_row1, R.id.widget_row2, R.id.widget_row3, R.id.widget_row4)
            val dots = intArrayOf(R.id.widget_dot1, R.id.widget_dot2, R.id.widget_dot3, R.id.widget_dot4)
            val labels = intArrayOf(R.id.widget_label1, R.id.widget_label2, R.id.widget_label3, R.id.widget_label4)
            val names = intArrayOf(R.id.widget_name1, R.id.widget_name2, R.id.widget_name3, R.id.widget_name4)

            if (meals.isEmpty()) {
                views.setViewVisibility(R.id.widget_rows, View.GONE)
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                views.setViewVisibility(R.id.widget_count, View.GONE)
                views.setTextViewText(
                    R.id.widget_empty_title,
                    if (json == null) "Abra o Receyta" else "Dia livre"
                )
                views.setTextViewText(
                    R.id.widget_empty_sub,
                    if (json == null) "para começar a planejar" else "Nada planejado pra hoje"
                )
            } else {
                views.setViewVisibility(R.id.widget_rows, View.VISIBLE)
                views.setViewVisibility(R.id.widget_empty, View.GONE)

                val done = meals.count { it.done }
                views.setViewVisibility(R.id.widget_count, View.VISIBLE)
                views.setTextViewText(R.id.widget_count, "$done/${meals.size}")

                val overflow = meals.size > MAX_ROWS
                for (i in 0 until MAX_ROWS) {
                    val isMore = overflow && i == MAX_ROWS - 1
                    val meal = if (isMore) null else meals.getOrNull(i)
                    if (!isMore && meal == null) {
                        views.setViewVisibility(rows[i], View.GONE)
                        continue
                    }
                    views.setViewVisibility(rows[i], View.VISIBLE)
                    if (isMore) {
                        views.setViewVisibility(dots[i], View.INVISIBLE)
                        views.setTextViewText(labels[i], "")
                        views.setTextViewText(names[i], "+" + (meals.size - (MAX_ROWS - 1)) + " receitas")
                    } else {
                        views.setViewVisibility(dots[i], View.VISIBLE)
                        views.setImageViewResource(
                            dots[i],
                            if (meal!!.done) R.drawable.widget_dot_done else R.drawable.widget_dot_pending
                        )
                        views.setTextViewText(labels[i], meal.label.uppercase(locale))
                        views.setTextViewText(names[i], meal.name)
                    }
                }
            }

            WidgetStore.openAppOnClick(context, views, R.id.widget_root)
            return views
        }
    }
}
