package de.ericz.worldclockv2

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
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

                // Colors
                val bgColor = data.getString("bgColor", "#042c4d")
                val primaryColor = data.getString("primaryColor", "#FFFFFF")
                val secondaryColor = data.getString("secondaryColor", "#0aaea6")
                val opacity = data.getFloat("opacity", 0.9f)

                setTextViewText(R.id.widget_city, city)
                setTextViewText(R.id.widget_weather, weather)
                
                // Apply colors and opacity
                try {
                    setInt(R.id.widget_background_view, "setColorFilter", Color.parseColor(bgColor))
                    // setAlpha expects a value between 0 and 255 for RemoteViews on some versions, 
                    // but for ImageView in XML it's 0.0 to 1.0. 
                    // Using setInt with "setAlpha" usually expects 0-255.
                    setInt(R.id.widget_background_view, "setAlpha", (opacity * 255).toInt())
                    
                    setTextColor(R.id.widget_time, Color.parseColor(primaryColor))
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
