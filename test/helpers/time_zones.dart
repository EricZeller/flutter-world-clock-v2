import 'dart:io';

import 'package:timezone/timezone.dart' as tz;
import 'package:world_clock_v2/utils/time_utils.dart';

/// Loads the time zone database the app ships with.
void initializeAppTimeZones() =>
    tz.initializeDatabase(File(timeZoneAsset).readAsBytesSync());
