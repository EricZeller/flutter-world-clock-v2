package de.ericz.worldclockv2

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class WorldClockWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: android.content.SharedPreferences) {
        // Aggressively search for data
        var data = widgetData
        if (data.all.isEmpty()) {
            data = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        }
        if (data.all.isEmpty()) {
            // Try with package prefix as well
            data = context.getSharedPreferences("${context.packageName}.HomeWidgetPreferences", Context.MODE_PRIVATE)
        }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.world_clock_widget).apply {
                val city = data.getString("city", "Berlin")
                val weather = data.getString("weather", "Loading...")
                val timeZone = data.getString("timeZone", "Europe/Berlin")

                // Settings
                val widgetOpacity = data.getFloat("widgetOpacity", 0.8f)
                val widgetLayout = data.getString("widgetLayout", "detailed")

                // Colors
                val bgColorStr = data.getString("bgColor", "#042c4d")
                val primaryColor = data.getString("primaryColor", "#FFFFFF")
                val secondaryColor = data.getString("secondaryColor", "#0aaea6")

                setTextViewText(R.id.widget_city, city)
                setTextViewText(R.id.widget_weather, weather)
                
                // Apply layout logic
                if (widgetLayout == "compact") {
                    setViewVisibility(R.id.widget_weather, View.GONE)
                    setViewVisibility(R.id.widget_date, View.GONE)
                } else {
                    setViewVisibility(R.id.widget_weather, View.VISIBLE)
                    setViewVisibility(R.id.widget_date, View.VISIBLE)
                }

                // Apply colors and transparency
                try {
                    val baseColor = Color.parseColor(bgColorStr)
                    val alpha = (widgetOpacity * 255).toInt()
                    val transparentColor = Color.argb(alpha, Color.red(baseColor), Color.green(baseColor), Color.blue(baseColor))
                    
                    setInt(R.id.widget_background_view, "setColorFilter", transparentColor)
                    setTextColor(R.id.widget_time, Color.parseColor(primaryColor))
                    setTextColor(R.id.widget_date, Color.parseColor(primaryColor))
                    setTextColor(R.id.widget_weather, Color.parseColor(primaryColor))
                    setTextColor(R.id.widget_city, Color.parseColor(secondaryColor))
                } catch (e: Exception) {
                    // Fallback
                }

                // TextClock handling
                if (timeZone != null) {
                    setString(R.id.widget_time, "setTimeZone", timeZone)
                    setString(R.id.widget_date, "setTimeZone", timeZone)
                }

                // Click to open app
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                val pendingIntent = PendingIntent.getActivity(
                    context, 
                    0, 
                    intent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
