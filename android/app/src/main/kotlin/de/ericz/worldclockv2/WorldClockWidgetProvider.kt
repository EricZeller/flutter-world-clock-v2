package de.ericz.worldclockv2

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import androidx.core.content.res.ResourcesCompat
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import kotlin.math.roundToInt

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
                val weatherIcon = data.getString("weather_icon", "☀️")
                val timeZone = data.getString("timeZone", "Europe/Berlin")

                // Settings
                val widgetOpacity = getFloatPreference(data, "widgetOpacity", 0.8f)
                val widgetLayout = data.getString("widgetLayout", "detailed")

                // Colors
                val bgColorStr = data.getString("bgColor", "#042c4d")
                val primaryColor = data.getString("primaryColor", "#FFFFFF")
                val secondaryColor = data.getString("secondaryColor", "#0aaea6")

                setTextViewText(R.id.widget_weather, weather)
                setTextViewText(R.id.widget_weather_icon, weatherIcon)
                
                // Apply layout logic
                if (widgetLayout == "compact") {
                    setViewVisibility(R.id.widget_detailed_layout, View.GONE)
                    setViewVisibility(R.id.widget_compact_layout, View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_detailed_layout, View.VISIBLE)
                    setViewVisibility(R.id.widget_compact_layout, View.GONE)
                }

                // Apply colors and transparency
                try {
                    val baseColor = Color.parseColor(bgColorStr)
                    val alpha = (widgetOpacity.coerceIn(0f, 1f) * 255).roundToInt()

                    setInt(R.id.widget_background_view, "setColorFilter", baseColor)
                    setInt(R.id.widget_background_view, "setImageAlpha", alpha)
                    setImageViewBitmap(
                        R.id.widget_city,
                        createPacificoText(context, city ?: "Berlin", Color.parseColor(secondaryColor))
                    )
                    setImageViewBitmap(
                        R.id.widget_city_compact,
                        createPacificoText(context, city ?: "Berlin", Color.parseColor(secondaryColor))
                    )
                    setTextColor(R.id.widget_time, Color.parseColor(primaryColor))
                    setTextColor(R.id.widget_time_compact, Color.parseColor(primaryColor))
                    setTextColor(R.id.widget_date, Color.parseColor(primaryColor))
                    setTextColor(R.id.widget_weather, Color.parseColor(primaryColor))
                    setTextColor(R.id.widget_weather_icon, Color.parseColor(primaryColor))
                } catch (e: Exception) {
                    setInt(R.id.widget_background_view, "setColorFilter", Color.parseColor("#042C4D"))
                    setInt(R.id.widget_background_view, "setImageAlpha", 204)
                    setImageViewBitmap(
                        R.id.widget_city,
                        createPacificoText(context, city ?: "Berlin", Color.parseColor("#0AAEA6"))
                    )
                    setImageViewBitmap(
                        R.id.widget_city_compact,
                        createPacificoText(context, city ?: "Berlin", Color.parseColor("#0AAEA6"))
                    )
                }

                // TextClock handling
                if (timeZone != null) {
                    setString(R.id.widget_time, "setTimeZone", timeZone)
                    setString(R.id.widget_time_compact, "setTimeZone", timeZone)
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

    private fun getFloatPreference(
        data: android.content.SharedPreferences,
        key: String,
        defaultValue: Float
    ): Float {
        return when (val value = data.all[key]) {
            is Float -> value
            is Double -> value.toFloat()
            is Long -> value.toFloat()
            is Int -> value.toFloat()
            is String -> value.toFloatOrNull() ?: defaultValue
            else -> defaultValue
        }.coerceIn(0.1f, 1f)
    }

    private fun createPacificoText(context: Context, text: String, color: Int): Bitmap {
        val typeface = ResourcesCompat.getFont(context, R.font.pacifico)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            textSize = 70f
            this.typeface = typeface
        }
        val value = text.ifBlank { "Berlin" }
        val bounds = Rect()
        paint.getTextBounds(value, 0, value.length, bounds)
        val width = (bounds.width() + 24).coerceAtLeast(80)
        val height = 120
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawText(value, 12f - bounds.left, 60f - bounds.exactCenterY(), paint)
        return bitmap
    }
}
