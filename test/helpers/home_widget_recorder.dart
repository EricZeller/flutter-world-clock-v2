import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/services/home_widget_service.dart';
import 'package:world_clock_v2/services/home_widget_sync.dart';

/// Records the data the app writes to the home screen widget.
class HomeWidgetRecorder {
  HomeWidgetRecorder._();

  static const _channel = MethodChannel('home_widget');

  /// IDs reported as placed on the home screen; `null` makes the call fail.
  List<int>? installedWidgetIds = [];

  /// Every method called on the channel, in order.
  final methods = <String>[];

  /// Every `saveWidgetData` call in order, as (key, value).
  final writes = <(String, Object?)>[];

  /// The latest value per key, i.e. what the widget would display.
  Map<String, Object?> get current => {for (final (k, v) in writes) k: v};

  /// Values written for [key], in order.
  List<Object?> valuesOf(String key) =>
      [for (final (k, v) in writes) if (k == key) v];

  static HomeWidgetRecorder install() {
    HomeWidgetService.resetQueue();
    HomeWidgetSync.resetQueue();
    final recorder = HomeWidgetRecorder._();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_channel, (call) async {
      recorder.methods.add(call.method);
      switch (call.method) {
        case 'saveWidgetData':
          final arguments = call.arguments as Map;
          recorder.writes.add((arguments['id'] as String, arguments['data']));
        case 'getInstalledWidgets':
          final ids = recorder.installedWidgetIds;
          if (ids == null) {
            throw PlatformException(code: 'unavailable');
          }
          return [
            for (final id in ids) {'widgetId': id},
          ];
        case 'getWidgetData':
          return null;
      }
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(_channel, null));
    return recorder;
  }
}
