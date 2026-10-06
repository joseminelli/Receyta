package com.whisklinestudio.receyta

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService

/**
 * Widget "Compras": a lista em aberto com os itens que faltam e uma faixa de
 * progresso do que já foi marcado. A lista rola, então cabe em qualquer tamanho.
 */
class ShoppingWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, build(context, id))
        manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_list)
    }

    companion object {
        fun refresh(context: Context) =
            WidgetStore.refreshAll(context, ShoppingWidgetProvider::class.java, ::build)

        /** Os itens que faltam da lista em aberto. */
        fun pendingItems(context: Context): List<String> {
            val array = WidgetStore.read(context)?.optJSONArray("shoppingItems") ?: return emptyList()
            return List(array.length()) { array.getString(it) }
        }

        private fun build(context: Context, id: Int): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_shopping)
            val json = WidgetStore.read(context)

            val pending = json?.optInt("shoppingPending", 0) ?: 0
            val lists = json?.optInt("shoppingLists", 0) ?: 0
            val total = json?.optInt("shoppingTotal", 0) ?: 0
            val checked = json?.optInt("shoppingChecked", 0) ?: 0
            val listName = json?.optString("shoppingList") ?: ""

            if (json == null || pending == 0) {
                views.setTextViewText(R.id.widget_kicker, "COMPRAS")
                views.setTextViewText(
                    R.id.widget_list_name,
                    if (json == null) "Sua lista" else "Tudo certo"
                )
                views.setViewVisibility(R.id.widget_count, View.GONE)
                views.setViewVisibility(R.id.widget_progress, View.GONE)
                views.setTextViewText(
                    R.id.widget_empty_title,
                    if (json == null) "Abra o Receyta" else "Nada pra comprar"
                )
                views.setTextViewText(
                    R.id.widget_empty_sub,
                    if (json == null) "para ver suas listas" else "Nenhum item pendente"
                )
            } else {
                val items = if (pending == 1) "1 item" else "$pending itens"
                views.setTextViewText(
                    R.id.widget_kicker,
                    if (lists > 1) "COMPRAS · $lists LISTAS" else "COMPRAS · FALTAM $items".uppercase()
                )
                views.setTextViewText(R.id.widget_list_name, listName.ifEmpty { "Compras" })
                views.setViewVisibility(R.id.widget_count, View.VISIBLE)
                views.setTextViewText(R.id.widget_count, "$checked/$total")
                views.setViewVisibility(R.id.widget_progress, View.VISIBLE)
                views.setProgressBar(
                    R.id.widget_progress, 100,
                    if (total == 0) 0 else checked * 100 / total, false
                )
            }

            WidgetStore.attachList(context, views, id, ShoppingWidgetService::class.java)
            WidgetStore.openAppOnClick(context, views, R.id.widget_root)
            return views
        }
    }
}

class ShoppingWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = Factory(applicationContext)

    private class Factory(private val context: Context) : RemoteViewsFactory {
        private var items: List<String> = emptyList()

        override fun onCreate() {}
        override fun onDataSetChanged() { items = ShoppingWidgetProvider.pendingItems(context) }
        override fun onDestroy() {}
        override fun getCount() = items.size
        override fun getViewTypeCount() = 1
        override fun getItemId(position: Int) = position.toLong()
        override fun hasStableIds() = false
        override fun getLoadingView(): RemoteViews? = null

        override fun getViewAt(position: Int): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_item_shopping)
            views.setTextViewText(R.id.item_name, items[position])
            views.setOnClickFillInIntent(R.id.item_root, Intent())
            return views
        }
    }
}
