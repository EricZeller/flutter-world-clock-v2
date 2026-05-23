// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'World Clock v2';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get changeCity => 'Change city';

  @override
  String get sourceCode => 'Source Code';

  @override
  String get reportBug => 'Report a bug';

  @override
  String localTime(String time) {
    return 'Local time: $time';
  }

  @override
  String get loading => 'Loading...';

  @override
  String get weatherLoading => '🛰️ Loading...';

  @override
  String get connectionError => '🛜 Connection error';

  @override
  String get apiError => '🛜 Couldn\'t connect to API';

  @override
  String get searchCity => 'Search for city';

  @override
  String get chooseCity => 'Choose city';

  @override
  String get aboutThisApp => 'About this app';

  @override
  String get license => 'License';

  @override
  String get contact => 'Contact';

  @override
  String currentVersion(String version) {
    return 'Current version: v$version';
  }

  @override
  String get defaultTheme => 'Default theme';

  @override
  String get restartToApply => 'Restart app to apply';

  @override
  String get customMaterialColor => 'Custom Material color';

  @override
  String get selectColor => 'Select color';

  @override
  String get showSeconds => 'Show seconds';

  @override
  String get worldClock => 'World clock';

  @override
  String get local => 'Local';

  @override
  String get use24hrFormat => 'Use 24hr format';

  @override
  String get useFahrenheit => 'Use °F';

  @override
  String get displayMoreInfo => 'Display more info on homescreen';

  @override
  String get widgetTransparency => 'Widget transparency';

  @override
  String get setWttrServer => 'Set own wttr.in server';

  @override
  String get invalidUrl => 'Invalid URL';

  @override
  String get urlSaved => 'URL saved';

  @override
  String get urlRestored => 'URL restored and saved';

  @override
  String get noChanges => 'No changes to save';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get saveChangesPrompt =>
      'Please save the changes you have made to the wttr.in server';

  @override
  String get apiUpdateNotice => 'API will update in a maximum of 30 seconds.';

  @override
  String get serverSuccessNotice =>
      'wttr.in server setted. \nPlease check the home screen to ensure that the new server is working properly. \nAPI will update in a maximum of 30 seconds.';

  @override
  String get ok => 'OK';

  @override
  String get aboutDescription =>
      'World Clock is a Flutter app that displays the current time and weather for various cities. The app uses the Material You theme to provide a modern and customizable user experience.\nCheck out the numerous settings for an even more personalized experience.';

  @override
  String get licenseDescription =>
      'This app is licensed under the GNU GPL 3.0. For more details, see the LICENSE file in the repository.';

  @override
  String get contactDescription =>
      'If you have any questions or suggestions, feel free to contact me over GitHub or open an Issue over the repository of this app.';

  @override
  String get sortByCity => 'Sort by city';

  @override
  String get sortByCountry => 'Sort by country';

  @override
  String get sortByUtc => 'Sort by UTC timezone';

  @override
  String get sortByContinent => 'Sort by continent/region';

  @override
  String searchHint(int count) {
    return 'Search city or country ($count found)';
  }
}
