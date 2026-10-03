import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:world_clock_v2/app.dart';
import 'package:world_clock_v2/services/city_repository.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/services/weather_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Load settings before the first frame so the app never flashes defaults.
  final settings = SettingsProvider();
  await settings.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        Provider(create: (_) => CityRepository()),
        Provider(
          create: (_) => WeatherService(),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: const WorldClockApp(),
    ),
  );
}
