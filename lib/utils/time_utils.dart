import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

DateFormat clockFormat({required bool use24hr, required bool showSeconds}) {
  if (showSeconds) {
    return use24hr ? DateFormat('Hms') : DateFormat('hh:mm:ss a');
  }
  return use24hr ? DateFormat('Hm') : DateFormat('hh:mm a');
}

String formatTimeInZone(
  String timeZone, {
  required bool use24hr,
  required bool showSeconds,
  DateTime? now,
}) {
  final location = tz.getLocation(timeZone);
  final time = now == null
      ? tz.TZDateTime.now(location)
      : tz.TZDateTime.from(now, location);
  return clockFormat(use24hr: use24hr, showSeconds: showSeconds).format(time);
}

/// Offset of [timeZone] relative to the device's local time zone.
Duration differenceToLocal(String timeZone, {DateTime? now}) {
  final instant = now ?? DateTime.now();
  final cityOffset =
      tz.TZDateTime.from(instant, tz.getLocation(timeZone)).timeZoneOffset;
  return cityOffset - instant.timeZoneOffset;
}

/// Formats an offset like `+02:00` or `-05:30`.
String formatOffset(Duration offset) {
  final totalMinutes = offset.inMinutes;
  final sign = totalMinutes < 0 ? '-' : '+';
  final absoluteMinutes = totalMinutes.abs();
  final hours = (absoluteMinutes ~/ 60).toString().padLeft(2, '0');
  final minutes = (absoluteMinutes % 60).toString().padLeft(2, '0');
  return '$sign$hours:$minutes';
}

/// Parses an offset like `+05:30` into minutes, or `null` if malformed.
int? parseUtcOffset(String utc) {
  final match = RegExp(r'([+-])(\d{2}):(\d{2})').firstMatch(utc);
  if (match == null) return null;
  final minutes = int.parse(match.group(2)!) * 60 + int.parse(match.group(3)!);
  return match.group(1) == '-' ? -minutes : minutes;
}

/// Converts a wttr.in time like `07:11 AM` to the user's clock format.
/// Returns `null` for values such as `No sunrise` (polar day/night).
String? formatWttrTime(String raw, {required bool use24hr}) {
  final DateTime time;
  try {
    time = DateFormat('hh:mm a', 'en_US').parseStrict(raw.trim());
  } on FormatException {
    return null;
  }
  return (use24hr ? DateFormat('HH:mm') : DateFormat('hh:mm a')).format(time);
}
