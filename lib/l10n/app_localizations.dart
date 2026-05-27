import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'World Clock v2'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @changeCity.
  ///
  /// In en, this message translates to:
  /// **'Change city'**
  String get changeCity;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get sourceCode;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get reportBug;

  /// No description provided for @localTime.
  ///
  /// In en, this message translates to:
  /// **'Local time: {time}'**
  String localTime(String time);

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @weatherLoading.
  ///
  /// In en, this message translates to:
  /// **'🛰️ Loading...'**
  String get weatherLoading;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'🛜 Connection error'**
  String get connectionError;

  /// No description provided for @apiError.
  ///
  /// In en, this message translates to:
  /// **'🛜 Couldn\'t connect to API'**
  String get apiError;

  /// No description provided for @searchCity.
  ///
  /// In en, this message translates to:
  /// **'Search for city'**
  String get searchCity;

  /// No description provided for @chooseCity.
  ///
  /// In en, this message translates to:
  /// **'Choose city'**
  String get chooseCity;

  /// No description provided for @aboutThisApp.
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get aboutThisApp;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @currentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current version: v{version}'**
  String currentVersion(String version);

  /// No description provided for @defaultTheme.
  ///
  /// In en, this message translates to:
  /// **'Default theme'**
  String get defaultTheme;

  /// No description provided for @restartToApply.
  ///
  /// In en, this message translates to:
  /// **'Restart app to apply'**
  String get restartToApply;

  /// No description provided for @customMaterialColor.
  ///
  /// In en, this message translates to:
  /// **'Custom Material color'**
  String get customMaterialColor;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select color'**
  String get selectColor;

  /// No description provided for @showSeconds.
  ///
  /// In en, this message translates to:
  /// **'Show seconds'**
  String get showSeconds;

  /// No description provided for @worldClock.
  ///
  /// In en, this message translates to:
  /// **'World clock'**
  String get worldClock;

  /// No description provided for @local.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get local;

  /// No description provided for @use24hrFormat.
  ///
  /// In en, this message translates to:
  /// **'Use 24hr format'**
  String get use24hrFormat;

  /// No description provided for @useFahrenheit.
  ///
  /// In en, this message translates to:
  /// **'Use °F'**
  String get useFahrenheit;

  /// No description provided for @displayMoreInfo.
  ///
  /// In en, this message translates to:
  /// **'Display more info on homescreen'**
  String get displayMoreInfo;

  /// No description provided for @widgetSettings.
  ///
  /// In en, this message translates to:
  /// **'Widget Settings'**
  String get widgetSettings;

  /// No description provided for @widgetPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get widgetPreview;

  /// No description provided for @widgetLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get widgetLayout;

  /// No description provided for @layoutDetailed.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get layoutDetailed;

  /// No description provided for @layoutCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get layoutCompact;

  /// No description provided for @widgetTransparency.
  ///
  /// In en, this message translates to:
  /// **'Widget transparency'**
  String get widgetTransparency;

  /// No description provided for @setWttrServer.
  ///
  /// In en, this message translates to:
  /// **'Set own wttr.in server'**
  String get setWttrServer;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get invalidUrl;

  /// No description provided for @urlSaved.
  ///
  /// In en, this message translates to:
  /// **'URL saved'**
  String get urlSaved;

  /// No description provided for @urlRestored.
  ///
  /// In en, this message translates to:
  /// **'URL restored and saved'**
  String get urlRestored;

  /// No description provided for @noChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes to save'**
  String get noChanges;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @saveChangesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please save the changes you have made to the wttr.in server'**
  String get saveChangesPrompt;

  /// No description provided for @apiUpdateNotice.
  ///
  /// In en, this message translates to:
  /// **'API will update in a maximum of 30 seconds.'**
  String get apiUpdateNotice;

  /// No description provided for @serverSuccessNotice.
  ///
  /// In en, this message translates to:
  /// **'wttr.in server setted. \nPlease check the home screen to ensure that the new server is working properly. \nAPI will update in a maximum of 30 seconds.'**
  String get serverSuccessNotice;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'World Clock is a Flutter app that displays the current time and weather for various cities. The app uses the Material You theme to provide a modern and customizable user experience.\nCheck out the numerous settings for an even more personalized experience.'**
  String get aboutDescription;

  /// No description provided for @licenseDescription.
  ///
  /// In en, this message translates to:
  /// **'This app is licensed under the GNU GPL 3.0. For more details, see the LICENSE file in the repository.'**
  String get licenseDescription;

  /// No description provided for @contactDescription.
  ///
  /// In en, this message translates to:
  /// **'If you have any questions or suggestions, feel free to contact me over GitHub or open an Issue over the repository of this app.'**
  String get contactDescription;

  /// No description provided for @sortByCity.
  ///
  /// In en, this message translates to:
  /// **'Sort by city'**
  String get sortByCity;

  /// No description provided for @sortByCountry.
  ///
  /// In en, this message translates to:
  /// **'Sort by country'**
  String get sortByCountry;

  /// No description provided for @sortByUtc.
  ///
  /// In en, this message translates to:
  /// **'Sort by UTC timezone'**
  String get sortByUtc;

  /// No description provided for @sortByContinent.
  ///
  /// In en, this message translates to:
  /// **'Sort by continent/region'**
  String get sortByContinent;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search city or country ({count} found)'**
  String searchHint(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
