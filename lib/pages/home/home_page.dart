import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';
import 'package:world_clock_v2/models/city.dart';
import 'package:world_clock_v2/pages/home/city_page.dart';
import 'package:world_clock_v2/pages/home/home_menu.dart';
import 'package:world_clock_v2/services/city_repository.dart';
import 'package:world_clock_v2/services/home_widget_sync.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/services/weather_service.dart';

/// The favorite cities, one page each; swipe to switch between them.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Until the favorites are known, nothing is pushed to the home widget.
  List<City>? _favorites;
  int _index = 0;
  PageController? _controller;
  int _refreshGeneration = 0;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    // A widget may have got its own city while the app was in the
    // background, e.g. one whose weather is not cached yet; the city pages
    // only sync once their own weather is due again.
    _lifecycle = AppLifecycleListener(onResume: _syncHomeWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Theme changes alter the widget colors.
    _syncHomeWidget();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final repository = context.read<CityRepository>();
    final favorites = await repository.loadFavorites();
    final savedIndex = await repository.loadCurrentIndex();
    if (!mounted) return;
    // Stay on the shown city if it is still a favorite.
    final shown = _favorites == null ? null : _favorites![_index];
    final shownIndex = shown == null ? -1 : favorites.indexOf(shown);
    final index = (shownIndex >= 0 ? shownIndex : savedIndex)
        .clamp(0, favorites.length - 1);
    final controller = _controller;
    setState(() {
      _favorites = favorites;
      _index = index;
      _controller = controller ?? PageController(initialPage: index);
    });
    if (controller != null && controller.hasClients) {
      controller.jumpToPage(index);
    }
    // The jump happens before the pages are rebuilt and does not always
    // report a page change, e.g. to a page the old list did not have.
    if (index != savedIndex) repository.saveCurrentIndex(index);
    _syncHomeWidget();
  }

  void _syncHomeWidget() {
    if (_favorites == null) return;
    HomeWidgetSync(
      cities: context.read<CityRepository>(),
      weather: context.read<WeatherService>(),
    ).sync(context, context.read<SettingsProvider>());
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    context.read<CityRepository>().saveCurrentIndex(index);
  }

  Future<void> _openSettings() async {
    await Navigator.pushNamed(context, '/settings');
    // The server may have changed.
    if (mounted) setState(() => _refreshGeneration++);
  }

  Future<void> _manageCities() async {
    await Navigator.pushNamed(context, '/location');
    if (mounted) _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final favorites = _favorites;
    final controller = _controller;
    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      appBar: AppBar(
        actions: [
          HomeMenu(onOpenSettings: _openSettings, onChangeCity: _manageCities),
        ],
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        title: Text(l10n.appTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: favorites == null || controller == null
            ? const SizedBox.shrink()
            : Stack(
                children: [
                  PageView.builder(
                    controller: controller,
                    itemCount: favorites.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) => CityPage(
                      key: ValueKey(favorites[index]),
                      city: favorites[index],
                      isActive: index == _index,
                      refreshGeneration: _refreshGeneration,
                      onWeatherUpdated: _syncHomeWidget,
                      onManageCities: _manageCities,
                    ),
                  ),
                  if (favorites.length > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 28,
                      child: _PageDots(count: favorites.length, index: _index),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        onPressed: () {
          HapticFeedback.lightImpact();
          _openSettings();
        },
        child: Icon(Icons.settings, semanticLabel: l10n.settings),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: AppLocalizations.of(context)!.cityPosition(index + 1, count),
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == index ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? color : color.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
