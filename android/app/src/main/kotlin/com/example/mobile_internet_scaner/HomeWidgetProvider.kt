package com.example.mobile_internet_scaner

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class HomeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val color = prefs.getString("circle_color", "green")
            val drawableRes = if (color == "green") R.drawable.green_circle else R.drawable.red_circle
            views.setImageViewResource(R.id.circle_status, drawableRes)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
} 