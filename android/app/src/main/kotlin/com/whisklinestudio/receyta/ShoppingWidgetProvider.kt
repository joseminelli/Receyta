package com.whisklinestudio.receyta

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.view.View
import android.widget.RemoteViews

/**
 * Widget "Compras": a lista em aberto com os itens que faltam e uma barra de
 * progresso do que já foi marcado.
 */
class ShoppingWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, build(context))
    }

    companion object {
        private const val MAX_ROWS = 6

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, ShoppingWidgetProvider::class.java))
            for (id in ids) manager.updateAppWidget(id, build(context))
        }

        private fun build(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_shopping)
            val json = WidgetStore.read(context)

            val pending = json?.optInt("shoppingPending", 0) ?: 0
            val lists = json?.optInt("shoppingLists", 0) ?: 0
            val total = json?.optInt("shoppingTotal", 0) ?: 0
            val checked = json?.optInt("shoppingChecked", 0) ?: 0
            val listName = json?.optString("shoppingList") ?: ""
            val items = ArrayList<String>()
            val array = json?.optJSONArray("shoppingItems")
            if (array != null) {
                for (i in 0 until array.length()) items.add(array.getString(i))
            }

            val rows = intArrayOf(
                R.id.widget_row1, R.id.widget_row2, R.id.widget_row3,
                R.id.widget_row4, R.id.widget_row5, R.id.widget_row6
            )
            val names = intArrayOf(
                R.id.widget_name1, R.id.widget_name2, R.id.widget_name3,
                R.id.widget_name4, R.id.widget_name5, R.id.widget_name6
            )
            val dots = intArrayOf(
                R.id.widget_dot1, R.id.widget_dot2, R.id.widget_dot3,
                R.id.widget_dot4, R.id.widget_dot5, R.id.widget_dot6
            )

            views.setTextViewText(R.id.widget_kicker, "COMPRAS")

            if (json == null || pending == 0) {
                views.setTextViewText(
                    R.id.widget_list_name,
                    if (json == null) "Sua lista" else "Tudo certo"
                )
                views.setViewVisibility(R.id.widget_count, View.GONE)
                views.setViewVisibility(R.id.widget_rows, View.GONE)
                views.setViewVisibility(R.id.widget_footer, View.GONE)
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_empty_title,
                    if (json == null) "Abra o Receyta" else "Nada pra comprar"
                )
                views.setTextViewText(
                    R.id.widget_empty_sub,
                    if (json == null) "para ver suas listas" else "Nenhum item pendente"
                )
            } else {
                views.setViewVisibility(R.id.widget_empty, View.GONE)
                views.setViewVisibility(R.id.widget_rows, View.VISIBLE)
                views.setViewVisibility(R.id.widget_footer, View.VISIBLE)
                views.setViewVisibility(R.id.widget_count, View.VISIBLE)

                views.setTextViewText(R.id.widget_list_name, listName.ifEmpty { "Compras" })
                views.setTextViewText(R.id.widget_count, "$checked/$total")

                val overflow = items.size > MAX_ROWS
                for (i in 0 until MAX_ROWS) {
                    val isMore = overflow && i == MAX_ROWS - 1
                    val text = if (isMore) null else items.getOrNull(i)
                    if (!isMore && text == null) {
                        views.setViewVisibility(rows[i], View.GONE)
                        continue
                    }
                    views.setViewVisibility(rows[i], View.VISIBLE)
                    if (isMore) {
                        views.setViewVisibility(dots[i], View.INVISIBLE)
                        views.setTextViewText(names[i], "+" + (items.size - (MAX_ROWS - 1)) + " itens")
                    } else {
                        views.setViewVisibility(dots[i], View.VISIBLE)
                        views.setTextViewText(names[i], text)
                    }
                }

                views.setProgressBar(
                    R.id.widget_progress, 100,
                    if (total == 0) 0 else checked * 100 / total, false
                )
                val itemsText = if (pending == 1) "1 item" else "$pending itens"
                views.setTextViewText(
                    R.id.widget_footer_text,
                    if (lists > 1) "$itemsText · $lists listas" else "faltam $itemsText"
                )
            }

            WidgetStore.openAppOnClick(context, views, R.id.widget_root)
            return views
        }
    }
}
