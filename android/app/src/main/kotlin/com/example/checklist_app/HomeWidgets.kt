package com.example.checklist_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.OffsetDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale

private const val FLUTTER_PREFS = "FlutterSharedPreferences"
private const val TASKS_KEY = "flutter.m3_tasks_storage"
private const val PRESETS_KEY = "flutter.m3_reminder_presets_storage"

object HomeWidgetUpdater {
    fun updateAll(context: Context) {
        updateTodayTasksWidget(context)
        updateNextReminderWidget(context)
    }

    private fun updateTodayTasksWidget(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val component = ComponentName(context, TodayTasksWidgetProvider::class.java)
        val ids = manager.getAppWidgetIds(component)
        if (ids.isEmpty()) return

        val tasks = readTasks(context)
        val today = LocalDate.now()
        val todayCount = tasks.count { task ->
            val dueDate = parseDate(task.optString("dueDate", "")) ?: return@count false
            val isCompleted = task.optBoolean("isCompleted", false)
            !isCompleted && dueDate.toLocalDate() == today
        }

        ids.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.today_tasks_widget)
            views.setTextViewText(R.id.widget_title, "Today Tasks")
            views.setTextViewText(
                R.id.widget_value,
                "$todayCount task${if (todayCount == 1) "" else "s"} due today",
            )
            views.setOnClickPendingIntent(
                R.id.widget_root,
                launchPendingIntent(context, widgetId + 1000),
            )
            manager.updateAppWidget(widgetId, views)
        }
    }

    private fun updateNextReminderWidget(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val component = ComponentName(context, NextReminderWidgetProvider::class.java)
        val ids = manager.getAppWidgetIds(component)
        if (ids.isEmpty()) return

        val tasks = readTasks(context)
        val presets = readPresets(context)
        val now = LocalDateTime.now()

        var nextReminder: LocalDateTime? = null
        var nextTitle: String? = null
        for (task in tasks) {
            val isCompleted = task.optBoolean("isCompleted", false)
            val enabled = task.optBoolean("notificationEnabled", true)
            if (isCompleted || !enabled) continue

            val dueDate = parseDate(task.optString("dueDate", "")) ?: continue
            val priorityIdx = task.optInt("priority", 1)
            val offsets = offsetsForPriority(priorityIdx, presets)
            for (offset in offsets) {
                val candidate = dueDate.plusMinutes(offset.toLong())
                if (candidate.isBefore(now)) continue
                if (nextReminder == null || candidate.isBefore(nextReminder)) {
                    nextReminder = candidate
                    nextTitle = task.optString("title", "Task")
                }
            }
        }

        val timeFormatter = DateTimeFormatter.ofPattern("MMM d, hh:mm a", Locale.getDefault())
        val subtitle = if (nextReminder == null) {
            "No upcoming reminders"
        } else {
            "${nextTitle ?: "Task"} - ${nextReminder.format(timeFormatter)}"
        }

        ids.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.next_reminder_widget)
            views.setTextViewText(R.id.widget_title, "Next Reminder")
            views.setTextViewText(R.id.widget_value, subtitle)
            views.setOnClickPendingIntent(
                R.id.widget_root,
                launchPendingIntent(context, widgetId + 2000),
            )
            manager.updateAppWidget(widgetId, views)
        }
    }

    private fun readTasks(context: Context): List<JSONObject> {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        val raw = prefs.getString(TASKS_KEY, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            List(arr.length()) { idx -> arr.getJSONObject(idx) }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun readPresets(context: Context): JSONObject? {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        val raw = prefs.getString(PRESETS_KEY, null) ?: return null
        return try {
            JSONObject(raw)
        } catch (_: Exception) {
            null
        }
    }

    private fun offsetsForPriority(priorityIdx: Int, presets: JSONObject?): List<Int> {
        val key = when (priorityIdx) {
            2 -> "high"
            1 -> "medium"
            else -> "low"
        }
        val fallback = when (priorityIdx) {
            2 -> listOf(-1440, -60, 0, 15)
            1 -> listOf(-60, 0)
            else -> listOf(0)
        }
        val presetArray = presets?.optJSONArray(key) ?: return fallback
        val values = mutableListOf<Int>()
        for (i in 0 until presetArray.length()) {
            val value = presetArray.optInt(i, Int.MIN_VALUE)
            if (value != Int.MIN_VALUE) values.add(value)
        }
        return if (values.isEmpty()) fallback else values
    }

    private fun parseDate(raw: String): LocalDateTime? {
        return try {
            LocalDateTime.parse(raw, DateTimeFormatter.ISO_DATE_TIME)
        } catch (_: Exception) {
            try {
                OffsetDateTime.parse(raw, DateTimeFormatter.ISO_DATE_TIME).toLocalDateTime()
            } catch (_: Exception) {
                null
            }
        }
    }

    private fun launchPendingIntent(context: Context, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }
}

class TodayTasksWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        HomeWidgetUpdater.updateAll(context)
    }
}

class NextReminderWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        HomeWidgetUpdater.updateAll(context)
    }
}
