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
import org.json.JSONException
import org.json.JSONObject

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
            // A widget with its own city has keys like "city_42"; all others
            // show the app's first city from the plain keys.
            val ownCity = data.contains("city_$appWidgetId")
            fun cityValue(key: String, default: String): String =
                (if (ownCity) data.getString("${key}_$appWidgetId", null) else null)
                    ?: data.getString(key, null)
                    ?: default
            val views = RemoteViews(context.packageName, R.layout.world_clock_widget).apply {
                val city = cityValue("city", "Berlin").ifBlank { "Berlin" }
                val weather = cityValue("weather", "")
                val weatherIcon = cityValue("weather_icon", "☀️")
                val temperature = cityValue("weather_temp", "")
                val timeZone = cityValue("timeZone", "Europe/Berlin")

                // Settings
                val widgetOpacity = getFloatPreference(data, "widgetOpacity", 0.8f)
                val widgetLayout = data.getString("widgetLayout", "detailed")
                val use24Hour = getBooleanPreference(data, "use24hr", true)

                // Colors
                val bgColorStr = data.getString("bgColor", "#042c4d")
                val primaryColor = data.getString("primaryColor", "#FFFFFF")
                val secondaryColor = data.getString("secondaryColor", "#0aaea6")

                val weatherShort = if (temperature.isEmpty()) weatherIcon else "$weatherIcon $temperature"
                setTextViewText(R.id.widget_weather_icon, weatherShort)
                // Screen readers read the city image, the full weather text and
                // then the time and date of the TextClocks.
                setContentDescription(R.id.widget_city, city)
                setContentDescription(R.id.widget_city_compact, city)
                setContentDescription(R.id.widget_weather_icon, weather.ifBlank { weatherShort })

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
                // smaller fixed size for the longer 12-hour format. The size is
                // always set, since an update may reuse the existing views.
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                    setTextViewTextSize(
                        R.id.widget_time,
                        TypedValue.COMPLEX_UNIT_SP,
                        if (use24Hour) 32f else 22f
                    )
                }
                // The compact time sits next to the city name, so the longer
                // 12-hour format is drawn smaller on every Android version.
                setTextViewTextSize(
                    R.id.widget_time_compact,
                    TypedValue.COMPLEX_UNIT_SP,
                    if (use24Hour) 25f else 19f
                )

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

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val editor = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit()
        for (appWidgetId in appWidgetIds) {
            for (key in CITY_KEYS) editor.remove("${key}_$appWidgetId")
        }
        editor.apply()
    }

    /**
     * After a backup is restored, e.g. on a new phone, the launcher gives the
     * widgets new IDs. Their own cities are stored by widget ID, so they are
     * moved from [oldWidgetIds] to the [newWidgetIds] at the same position.
     * The two may overlap, so all values are read before any is written.
     */
    override fun onRestored(context: Context, oldWidgetIds: IntArray, newWidgetIds: IntArray) {
        super.onRestored(context, oldWidgetIds, newWidgetIds)
        val count = minOf(oldWidgetIds.size, newWidgetIds.size)
        val oldIds = oldWidgetIds.take(count)
        val newIds = newWidgetIds.take(count)
        val data = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        rekeyWidgetData(data, oldIds, newIds)
        rekeyFlutterWidgetCities(
            context.getSharedPreferences(FLUTTER_PREFERENCES, Context.MODE_PRIVATE),
            oldIds,
            newIds
        )
        onUpdate(context, AppWidgetManager.getInstance(context), newWidgetIds, data)
    }

    /** Moves the `<key>_<id>` values of [CITY_KEYS] to the new IDs. */
    private fun rekeyWidgetData(
        data: android.content.SharedPreferences,
        oldIds: List<Int>,
        newIds: List<Int>
    ) {
        val all = data.all
        val moved = mutableMapOf<String, String>()
        oldIds.zip(newIds).forEach { (oldId, newId) ->
            for (key in CITY_KEYS) {
                val value = all["${key}_$oldId"] as? String ?: continue
                moved["${key}_$newId"] = value
            }
        }
        val editor = data.edit()
        // Within one edit the last change of a key wins, so the moved values
        // replace the removals of IDs that are both old and new.
        for (id in oldIds + newIds) {
            for (key in CITY_KEYS) editor.remove("${key}_$id")
        }
        for ((key, value) in moved) editor.putString(key, value)
        editor.apply()
    }

    /**
     * Moves the entries of the app's widget cities, a JSON object by widget
     * ID that `CityRepository` keeps in the app's shared preferences.
     */
    private fun rekeyFlutterWidgetCities(
        prefs: android.content.SharedPreferences,
        oldIds: List<Int>,
        newIds: List<Int>
    ) {
        val stored = prefs.getString(FLUTTER_WIDGET_CITIES, null) ?: return
        val cities = try {
            JSONObject(stored)
        } catch (e: JSONException) {
            return
        }
        val changed = (oldIds + newIds).map { it.toString() }.toSet()
        val result = JSONObject()
        for (key in cities.keys()) {
            if (key !in changed) result.put(key, cities.get(key))
        }
        oldIds.zip(newIds).forEach { (oldId, newId) ->
            cities.opt(oldId.toString())?.let { result.put(newId.toString(), it) }
        }
        prefs.edit().putString(FLUTTER_WIDGET_CITIES, result.toString()).apply()
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
        // Keep very long names small enough for the widget update.
        val naturalWidth = paint.measureText(value)
        if (naturalWidth > MAX_BITMAP_WIDTH) {
            paint.textSize *= MAX_BITMAP_WIDTH / naturalWidth
        }
        val reference = Rect().also { paint.getTextBounds(REFERENCE_TEXT, 0, REFERENCE_TEXT.length, it) }
        val bounds = Rect().also { paint.getTextBounds(value, 0, value.length, it) }
        // Glyphs beyond the reference (stacked accents, other scripts) extend
        // the bitmap instead of being cut off.
        val top = minOf(reference.top, bounds.top)
        val bottom = maxOf(reference.bottom, bounds.bottom)
        val padding = 6
        val width = (bounds.width() + 2 * padding).coerceAtLeast(1)
        val height = bottom - top + 2 * padding
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        Canvas(bitmap).drawText(
            value,
            (padding - bounds.left).toFloat(),
            (padding - top).toFloat(),
            paint
        )
        return bitmap
    }

    private companion object {
        const val REFERENCE_TEXT = "ÅHlgjy"
        const val PREFERENCES = "HomeWidgetPreferences"
        // Where the shared_preferences plugin stores the app's values, with
        // its "flutter." prefix; see CityRepository.widgetCitiesKey.
        const val FLUTTER_PREFERENCES = "FlutterSharedPreferences"
        const val FLUTTER_WIDGET_CITIES = "flutter.widgetCities"
        // Keep in sync with HomeWidgetService.cityKeys.
        val CITY_KEYS = listOf("city", "weather", "weather_icon", "weather_temp", "timeZone")
        const val MAX_BITMAP_WIDTH = 1200f
    }
}
