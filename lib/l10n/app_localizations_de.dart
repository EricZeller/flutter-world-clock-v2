// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'World Clock v2';

  @override
  String get settings => 'Einstellungen';

  @override
  String get about => 'Über';

  @override
  String get sourceCode => 'Quellcode';

  @override
  String get reportBug => 'Fehler melden';

  @override
  String localTime(String time) {
    return 'Lokale Zeit: $time';
  }

  @override
  String get timeDifferenceTooltip => 'Zeitunterschied zur lokalen Zeit';

  @override
  String get loading => 'Laden...';

  @override
  String get weatherLoading => '🛰️ Lädt...';

  @override
  String get connectionError => '🛜 Verbindungsfehler';

  @override
  String get apiError => '🛜 Keine Verbindung zur API';

  @override
  String get searchCity => 'Stadt suchen';

  @override
  String get aboutThisApp => 'Über diese App';

  @override
  String get license => 'Lizenz';

  @override
  String get contact => 'Kontakt';

  @override
  String currentVersion(String version) {
    return 'Aktuelle Version: v$version';
  }

  @override
  String get defaultTheme => 'Standard-Design';

  @override
  String get customMaterialColor => 'Eigene Material Farbe';

  @override
  String get selectColor => 'Farbe wählen';

  @override
  String get showSeconds => 'Sekunden anzeigen';

  @override
  String get worldClock => 'Weltuhr';

  @override
  String get local => 'Lokal';

  @override
  String get use24hrFormat => '24h-Format nutzen';

  @override
  String get useFahrenheit => '°F nutzen';

  @override
  String get displayMoreInfo => 'Mehr Infos auf Startbildschirm';

  @override
  String get widgetSettings => 'Widget-Einstellungen';

  @override
  String get widgetPreview => 'Vorschau';

  @override
  String get widgetLayout => 'Layout';

  @override
  String get layoutDetailed => 'Detailliert';

  @override
  String get layoutCompact => 'Kompakt';

  @override
  String get widgetTransparency => 'Widget Transparenz';

  @override
  String get setWttrServer => 'Eigener wttr.in Server';

  @override
  String get invalidUrl => 'Ungültige URL';

  @override
  String get urlSaved => 'URL gespeichert';

  @override
  String get urlRestored => 'URL wiederhergestellt und gespeichert';

  @override
  String get noChanges => 'Keine Änderungen zum Speichern';

  @override
  String get unsavedChanges => 'Ungespeicherte Änderungen';

  @override
  String get saveChangesPrompt =>
      'Bitte speichere die Änderungen am wttr.in Server';

  @override
  String get apiUpdateNotice => 'API wird in maximal 30 Sekunden aktualisiert.';

  @override
  String get serverSuccessNotice =>
      'wttr.in Server gesetzt. \nBitte prüfe den Startbildschirm um sicherzugehen, dass der Server korrekt arbeitet. \nAPI wird in maximal 30 Sekunden aktualisiert.';

  @override
  String get ok => 'OK';

  @override
  String get aboutDescription =>
      'Weltuhr ist eine Flutter-App, die die aktuelle Zeit und das Wetter für verschiedene Städte anzeigt. Die App nutzt das Material You Theme, um eine moderne und anpassbare Benutzererfahrung zu bieten.\nSchau dir die zahlreichen Einstellungen für eine noch persönlichere Erfahrung an.';

  @override
  String get licenseDescription =>
      'Diese App ist unter der GNU GPL 3.0 lizenziert. Weitere Details findest du in der LICENSE-Datei im Repository.';

  @override
  String get contactDescription =>
      'Wenn du Fragen oder Vorschläge hast, kontaktiere mich gerne über GitHub oder öffne ein Issue im Repository dieser App.';

  @override
  String get sortByCity => 'Nach Stadt sortieren';

  @override
  String get sortByCountry => 'Nach Land sortieren';

  @override
  String get sortByUtc => 'Nach UTC-Zeitzone sortieren';

  @override
  String get sortByContinent => 'Nach Kontinent/Region sortieren';

  @override
  String searchHint(int count) {
    return 'Stadt oder Land suchen ($count gefunden)';
  }

  @override
  String get addCustomCity => 'Eigene Stadt hinzufügen';

  @override
  String get cityName => 'Stadtname';

  @override
  String get country => 'Land';

  @override
  String get pickCountryFromList => 'Wähle ein Land aus der Liste';

  @override
  String get ianaTimeZone => 'IANA-Zeitzone';

  @override
  String get pickCountryFirst => 'Wähle zuerst ein Land';

  @override
  String timeZoneNotInCountry(String country) {
    return 'Keine Zeitzone von $country';
  }

  @override
  String get customCityOfflineHint =>
      'Die Uhrzeit funktioniert offline. Das Wetter ist möglicherweise nicht verfügbar, wenn wttr.in diese Stadt nicht kennt.';

  @override
  String get add => 'Hinzufügen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get editCustomCity => 'Eigene Stadt bearbeiten';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get themeSystem => 'System';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeLight => 'Hell';

  @override
  String get sortList => 'Liste sortieren';

  @override
  String get showList => 'Liste anzeigen';

  @override
  String get showMap => 'Karte anzeigen';

  @override
  String lastUpdated(String time) {
    return 'Zuletzt aktualisiert $time';
  }

  @override
  String get sunrise => 'Sonnenaufgang';

  @override
  String get sunset => 'Sonnenuntergang';

  @override
  String get forecast => '3-Tage-Vorhersage';

  @override
  String get nextHours => 'Nächste Stunden';

  @override
  String get today => 'Heute';

  @override
  String get tomorrow => 'Morgen';

  @override
  String feelsLike(String temperature) {
    return 'Gefühlt $temperature';
  }

  @override
  String get humidity => 'Luftfeuchtigkeit';

  @override
  String get wind => 'Wind';

  @override
  String get chanceOfRain => 'Regenwahrscheinlichkeit';

  @override
  String get showForecast => 'Vorhersage anzeigen';

  @override
  String get manageCities => 'Städte verwalten';

  @override
  String get favorites => 'Deine Städte';

  @override
  String get allCities => 'Alle Städte';

  @override
  String get keepOneCity => 'Mindestens eine Stadt muss bleiben';

  @override
  String get removeFromFavorites => 'Entfernen';

  @override
  String get reorderCity => 'Zum Sortieren ziehen';

  @override
  String cityAddedAt(String city, String time) {
    return '$city hinzugefügt · $time';
  }

  @override
  String cityRemovedAt(String city, String time) {
    return '$city entfernt · $time';
  }

  @override
  String cityPosition(int index, int count) {
    return 'Stadt $index von $count';
  }

  @override
  String get widgetCity => 'Stadt für dieses Widget';

  @override
  String offsetChangeToday(String change) {
    return 'Zeitumstellung heute: $change';
  }

  @override
  String offsetChangeTomorrow(String change) {
    return 'Zeitumstellung morgen: $change';
  }

  @override
  String offsetChangeInDays(int days, String change) {
    return 'Zeitumstellung in $days Tagen: $change';
  }

  @override
  String get offsetChangeTooltip => 'Zeitumstellung in dieser Stadt';
}
