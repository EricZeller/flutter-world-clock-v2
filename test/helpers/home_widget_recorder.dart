import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_clock_v2/services/home_widget_service.dart';

/// Records the data the app writes to the home screen widget.
class HomeWidgetRecorder {
  HomeWidgetRecorder._();

  static const _channel = MethodChannel('home_widget');

  /// Every `saveWidgetData` call in order, as (key, value).
  final writes = <(String, Object?)>[];

  /// The latest value per key, i.e. what the widget would display.
  Map<String, Object?> get current => {for (final (k, v) in writes) k: v};

  /// Values written for [key], in order.
  List<Object?> valuesOf(String key) =>
      [for (final (k, v) in writes) if (k == key) v];

  static HomeWidgetRecorder install() {
    HomeWidgetService.resetQueue();
    final recorder = HomeWidgetRecorder._();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_channel, (call) async {
      if (call.method == 'saveWidgetData') {
        final arguments = call.arguments as Map;
        recorder.writes.add((arguments['id'] as String, arguments['data']));
      }
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(_channel, null));
    return recorder;
  }
}
