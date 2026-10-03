package de.ericz.worldclockv2

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.os.Build
import android.util.TypedValue
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
                val city = data.getString("city", null)?.ifBlank { null } ?: "Berlin"
                val weather = data.getString("weather", "") ?: ""
                val weatherIcon = data.getString("weather_icon", "☀️") ?: "☀️"
                val temperature = data.getString("weather_temp", "") ?: ""
                val timeZone = data.getString("timeZone", "Europe/Berlin")

                // Settings
                val widgetOpacity = getFloatPreference(data, "widgetOpacity", 0.8f)
                val widgetLayout = data.getString("widgetLayout", "detailed")
                val use24Hour = getBooleanPreference(data, "use24hr", true)

                // Colors
                val bgColorStr = data.getString("bgColor", "#042c4d")
                val primaryColor = data.getString("primaryColor", "#FFFFFF")
                val secondaryColor = data.getString("secondaryColor", "#0aaea6")

                setTextViewText(
                    R.id.widget_weather_icon,
                    if (temperature.isEmpty()) weatherIcon else "$weatherIcon $temperature"
                )
                // Read out by screen readers instead of the individual parts.
                setContentDescription(
                    android.R.id.background,
                    listOf(city, weather).filter { it.isNotBlank() }.joinToString(", ")
                )

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
                    // Both layouts share one bitmap to keep the update small.
                    val cityBitmap = createPacificoText(context, city, Color.parseColor(secondaryColor))
                    setImageViewBitmap(R.id.widget_city, cityBitmap)
                    setImageViewBitmap(R.id.widget_city_compact, cityBitmap)
                    setTextColor(R.id.widget_time, Color.parseColor(primaryColor))
                    setTextColor(R.id.widget_time_compact, Color.parseColor(primaryColor))
                    setTextColor(R.id.widget_date, Color.parseColor(primaryColor))
                    setTextColor(R.id.widget_weather_icon, Color.parseColor(primaryColor))
                } catch (e: Exception) {
                    setInt(R.id.widget_background_view, "setColorFilter", Color.parseColor("#042C4D"))
                    setInt(R.id.widget_background_view, "setImageAlpha", 204)
                    val cityBitmap = createPacificoText(context, city, Color.parseColor("#0AAEA6"))
                    setImageViewBitmap(R.id.widget_city, cityBitmap)
                    setImageViewBitmap(R.id.widget_city_compact, cityBitmap)
                }

                // TextClock handling
                if (timeZone != null) {
                    setString(R.id.widget_time, "setTimeZone", timeZone)
                    setString(R.id.widget_time_compact, "setTimeZone", timeZone)
                    setString(R.id.widget_date, "setTimeZone", timeZone)
                }

                // TextClock otherwise follows the device's 12/24-hour setting.
                // Set both formats so the app's setting is authoritative.
                val timeFormat = if (use24Hour) "HH:mm" else "hh:mm a"
                setCharSequence(R.id.widget_time, "setFormat12Hour", timeFormat)
                setCharSequence(R.id.widget_time, "setFormat24Hour", timeFormat)
                setCharSequence(R.id.widget_time_compact, "setFormat12Hour", timeFormat)
                setCharSequence(R.id.widget_time_compact, "setFormat24Hour", timeFormat)
                // Android 8+ shrinks the time to fit; older versions get a
                // smaller fixed size for the longer 12-hour format.
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O && !use24Hour) {
                    setTextViewTextSize(R.id.widget_time, TypedValue.COMPLEX_UNIT_SP, 22f)
                }

                // Click to open app
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                val pendingIntent = PendingIntent.getActivity(
                    context, 
                    0, 
                    intent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(android.R.id.background, pendingIntent)
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

    private fun getBooleanPreference(
        data: android.content.SharedPreferences,
        key: String,
        defaultValue: Boolean
    ): Boolean {
        return when (val value = data.all[key]) {
            is Boolean -> value
            is String -> value.toBooleanStrictOrNull() ?: defaultValue
            else -> defaultValue
        }
    }

    /**
     * Renders [text] in Pacifico, which RemoteViews cannot use directly on all
     * Android versions. The bitmap is cropped to the height of a reference text
     * with tall accents and deep descenders, so every name is drawn at the same
     * scale and fills its row without empty space above or below.
     */
    private fun createPacificoText(context: Context, text: String, color: Int): Bitmap {
        val typeface = ResourcesCompat.getFont(context, R.font.pacifico)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            textSize = 96f
            this.typeface = typeface
        }
        val value = text.ifBlank { "Berlin" }
        val reference = Rect().also { paint.getTextBounds(REFERENCE_TEXT, 0, REFERENCE_TEXT.length, it) }
        val bounds = Rect().also { paint.getTextBounds(value, 0, value.length, it) }
        val padding = 6
        val width = (bounds.width() + 2 * padding).coerceAtLeast(1)
        val height = reference.height() + 2 * padding
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        Canvas(bitmap).drawText(
            value,
            (padding - bounds.left).toFloat(),
            (padding - reference.top).toFloat(),
            paint
        )
        return bitmap
    }

    private companion object {
        const val REFERENCE_TEXT = "ÅHlgjy"
    }
}
