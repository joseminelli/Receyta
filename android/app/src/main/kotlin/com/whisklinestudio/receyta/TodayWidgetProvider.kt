package com.whisklinestudio.receyta

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Widget "Hoje": as receitas planejadas pro dia, com a refeição de cada uma e
 * as já feitas marcadas. A lista rola, então cabe em qualquer tamanho.
 */
class TodayWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, build(context, id))
        manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_list)
    }

    companion object {
        private val locale = Locale("pt", "BR")

        fun refresh(context: Context) =
            WidgetStore.refreshAll(context, TodayWidgetProvider::class.java, ::build)

        class Meal(val label: String, val name: String, val done: Boolean)

        /** As refeições de hoje, na ordem em que o app mandou. */
        fun todayMeals(context: Context): List<Meal> {
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val array = WidgetStore.read(context)?.optJSONArray("meals") ?: return emptyList()
            val meals = ArrayList<Meal>()
            for (i in 0 until array.length()) {
                val m = array.getJSONObject(i)
                if (m.optString("date") != today) continue
                meals.add(Meal(m.optString("meal"), m.optString("name"), m.optBoolean("done")))
            }
            return meals
        }

        private fun build(context: Context, id: Int): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_today)
            val now = Date()
            views.setTextViewText(
                R.id.widget_weekday,
                SimpleDateFormat("EEEE", locale).format(now).uppercase(locale)
            )
            views.setTextViewText(
                R.id.widget_date,
                SimpleDateFormat("d 'de' MMMM", locale).format(now)
            )

            val hasData = WidgetStore.read(context) != null
            val meals = todayMeals(context)
            if (meals.isEmpty()) {
                views.setViewVisibility(R.id.widget_count, View.GONE)
                views.setTextViewText(
                    R.id.widget_empty_title,
                    if (hasData) "Dia livre" else "Abra o Receyta"
                )
                views.setTextViewText(
                    R.id.widget_empty_sub,
                    if (hasData) "Nada planejado pra hoje" else "para começar a planejar"
                )
            } else {
                views.setViewVisibility(R.id.widget_count, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_count,
                    "${meals.count { it.done }}/${meals.size}"
                )
            }

            WidgetStore.attachList(context, views, id, TodayWidgetService::class.java)
            WidgetStore.openAppOnClick(context, views, R.id.widget_root)
            return views
        }
    }
}

class TodayWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = Factory(applicationContext)

    private class Factory(private val context: Context) : RemoteViewsFactory {
        private var meals: List<TodayWidgetProvider.Companion.Meal> = emptyList()

        override fun onCreate() {}
        override fun onDataSetChanged() { meals = TodayWidgetProvider.todayMeals(context) }
        override fun onDestroy() {}
        override fun getCount() = meals.size
        override fun getViewTypeCount() = 1
        override fun getItemId(position: Int) = position.toLong()
        override fun hasStableIds() = false
        override fun getLoadingView(): RemoteViews? = null

        override fun getViewAt(position: Int): RemoteViews {
            val meal = meals[position]
            val views = RemoteViews(context.packageName, R.layout.widget_item_today)
            views.setImageViewResource(
                R.id.item_dot,
                if (meal.done) R.drawable.widget_dot_done else R.drawable.widget_dot_pending
            )
            views.setTextViewText(R.id.item_label, meal.label.uppercase(Locale("pt", "BR")))
            views.setTextViewText(R.id.item_name, meal.name)
            views.setOnClickFillInIntent(R.id.item_root, Intent())
            return views
        }
    }
}
