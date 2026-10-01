package com.whisklinestudio.timer_card

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Notificação do timer com layout próprio: bloco com a cor e a textura da
 * receita (imagem desenhada pelo Flutter) + painel claro com o relógio
 * regressivo de verdade (Chronometer) e os botões.
 *
 * É um plugin (e não código solto no app) porque os botões da notificação
 * rodam num isolate de segundo plano, cujo motor só registra plugins — ali
 * o Dart precisa conseguir chamar `show` pra redesenhar depois de pausar.
 *
 * Os botões reaproveitam o `ActionBroadcastReceiver` do
 * flutter_local_notifications: o Dart recebe o mesmo `actionId`/`payload` de
 * sempre, sem caminho novo.
 */
class TimerCardPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var context: Context? = null
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "receyta/timer_card").also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context
        if (ctx == null) {
            result.error("no_context", "plugin desanexado", null)
            return
        }
        try {
            when (call.method) {
                "show" -> {
                    show(ctx, call)
                    result.success(null)
                }
                "cancel" -> {
                    NotificationManagerCompat.from(ctx).cancel(call.argument<Int>("id")!!)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("failed", e.message, null)
        }
    }

    private fun show(ctx: Context, call: MethodCall) {
        val id = call.argument<Int>("id")!!
        val channelId = call.argument<String>("channelId")!!
        val payload = call.argument<String>("payload") ?: ""
        val title = call.argument<String>("title") ?: ""
        val label = call.argument<String>("label") ?: ""
        val running = call.argument<Boolean>("running") ?: false
        val remainingMs = (call.argument<Number>("remainingMs") ?: 0).toLong()
        val timeoutMs = (call.argument<Number>("timeoutMs") ?: 0).toLong()
        val accent = (call.argument<Number>("accent") ?: 0).toInt()
        val iconName = call.argument<String>("smallIcon") ?: ""
        val collapsedImage = call.argument<String>("collapsedImage")
        val expandedImage = call.argument<String>("expandedImage")
        val actions = call.argument<List<Map<String, Any?>>>("actions") ?: emptyList()

        val small = ctx.resources.getIdentifier(iconName, "drawable", ctx.packageName)
        val base = SystemClock.elapsedRealtime() + remainingMs

        fun bind(rv: RemoteViews, image: String?, withButtons: Boolean) {
            rv.setTextViewText(R.id.timer_label, label.uppercase())
            if (running) {
                rv.setViewVisibility(R.id.timer_clock, View.VISIBLE)
                rv.setViewVisibility(R.id.timer_static, View.GONE)
                rv.setChronometerCountDown(R.id.timer_clock, true)
                rv.setChronometer(R.id.timer_clock, base, null, true)
            } else {
                rv.setViewVisibility(R.id.timer_clock, View.GONE)
                rv.setViewVisibility(R.id.timer_static, View.VISIBLE)
                rv.setTextViewText(R.id.timer_static, clockText(remainingMs))
            }
            val bitmap = image?.let { BitmapFactory.decodeFile(it) }
            if (bitmap != null) {
                rv.setImageViewBitmap(R.id.timer_block, bitmap)
            } else {
                rv.setViewVisibility(R.id.timer_block, View.GONE)
            }
            rv.setViewVisibility(R.id.timer_badge, if (running) View.GONE else View.VISIBLE)
            if (withButtons) {
                val slots = arrayOf(
                    intArrayOf(R.id.timer_btn1, R.id.timer_btn1_icon, R.id.timer_btn1_text),
                    intArrayOf(R.id.timer_btn2, R.id.timer_btn2_icon, R.id.timer_btn2_text),
                    intArrayOf(R.id.timer_btn3, R.id.timer_btn3_icon, R.id.timer_btn3_text),
                )
                for ((i, slot) in slots.withIndex()) {
                    val action = actions.getOrNull(i)
                    if (action == null) {
                        rv.setViewVisibility(slot[0], View.GONE)
                        continue
                    }
                    val actionId = action["id"] as String
                    val icon = when {
                        actionId.endsWith("pause") -> R.drawable.ic_timer_pause
                        actionId.endsWith("resume") -> R.drawable.ic_timer_play
                        actionId.endsWith("stop") -> R.drawable.ic_timer_stop
                        else -> 0
                    }
                    rv.setViewVisibility(slot[0], View.VISIBLE)
                    if (icon != 0) {
                        rv.setImageViewResource(slot[1], icon)
                        rv.setViewVisibility(slot[1], View.VISIBLE)
                        rv.setViewVisibility(slot[2], View.GONE)
                    } else {
                        rv.setViewVisibility(slot[1], View.GONE)
                        rv.setViewVisibility(slot[2], View.VISIBLE)
                        rv.setTextViewText(slot[2], "+1")
                    }
                    rv.setContentDescription(slot[0], action["title"] as String)
                    rv.setOnClickPendingIntent(
                        slot[0],
                        actionIntent(
                            ctx,
                            id,
                            i,
                            payload,
                            actionId,
                            action["cancel"] as? Boolean ?: false,
                        ),
                    )
                }
            }
        }

        val collapsed = RemoteViews(ctx.packageName, R.layout.timer_card_collapsed)
        bind(collapsed, collapsedImage, false)
        val expanded = RemoteViews(ctx.packageName, R.layout.timer_card_expanded)
        bind(expanded, expandedImage, true)

        val builder = NotificationCompat.Builder(ctx, channelId)
            .setSmallIcon(if (small != 0) small else android.R.drawable.ic_lock_idle_alarm)
            .setColor(accent)
            .setContentTitle(title)
            .setContentText(label)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(collapsed)
            .setCustomBigContentView(expanded)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(openIntent(ctx, id, payload))
        if (running && timeoutMs > 0) builder.setTimeoutAfter(timeoutMs)

        try {
            NotificationManagerCompat.from(ctx).notify(id, builder.build())
        } catch (_: SecurityException) {
            // sem permissão de notificação: nada a mostrar
        }
    }

    private fun clockText(ms: Long): String {
        val total = (ms / 1000).coerceAtLeast(0)
        val h = total / 3600
        val m = (total % 3600) / 60
        val s = total % 60
        return if (h > 0) "%d:%02d:%02d".format(h, m, s) else "%02d:%02d".format(m, s)
    }

    private fun flags(): Int =
        PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)

    private fun actionIntent(
        ctx: Context,
        id: Int,
        index: Int,
        payload: String,
        actionId: String,
        cancel: Boolean,
    ): PendingIntent {
        val intent = Intent().apply {
            setClassName(
                ctx.packageName,
                "com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver",
            )
            action = "com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver.ACTION_TAPPED"
            putExtra("notificationId", id)
            putExtra("actionId", actionId)
            putExtra("cancelNotification", cancel)
            putExtra("payload", payload)
        }
        return PendingIntent.getBroadcast(ctx, id * 10 + index, intent, flags())
    }

    private fun openIntent(ctx: Context, id: Int, payload: String): PendingIntent {
        val intent = (ctx.packageManager.getLaunchIntentForPackage(ctx.packageName) ?: Intent()).apply {
            action = "SELECT_NOTIFICATION"
            putExtra("notificationId", id)
            putExtra("payload", payload)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        return PendingIntent.getActivity(ctx, id * 10 + 9, intent, flags())
    }
}
