import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds [builder] at the start of every second, so clocks change in sync
/// with the device clock without rebuilding the rest of the page.
class SecondTicker extends StatefulWidget {
  const SecondTicker({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<SecondTicker> createState() => _SecondTickerState();
}

class _SecondTickerState extends State<SecondTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleTick();
  }

  void _scheduleTick() {
    final untilNextSecond =
        Duration(milliseconds: 1000 - DateTime.now().millisecond);
    _timer = Timer(untilNextSecond, () {
      if (!mounted) return;
      setState(() {});
      _scheduleTick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
