// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Horloge Mondiale v2';

  @override
  String get settings => 'Paramètres';

  @override
  String get about => 'À propos';

  @override
  String get sourceCode => 'Code source';

  @override
  String get reportBug => 'Signaler un bug';

  @override
  String localTime(String time) {
    return 'Heure locale : $time';
  }

  @override
  String get timeDifferenceTooltip => 'Décalage par rapport à l’heure locale';

  @override
  String get loading => 'Chargement...';

  @override
  String get weatherLoading => '🛰️ Chargement...';

  @override
  String get connectionError => '🛜 Erreur de connexion';

  @override
  String get apiError => '🛜 Impossible de se connecter à l\'API';

  @override
  String get searchCity => 'Rechercher une ville';

  @override
  String get aboutThisApp => 'À propos de cette application';

  @override
  String get license => 'Licence';

  @override
  String get contact => 'Contact';

  @override
  String currentVersion(String version) {
    return 'Version actuelle : v$version';
  }

  @override
  String get defaultTheme => 'Thème par défaut';

  @override
  String get customMaterialColor => 'Couleur Material personnalisée';

  @override
  String get selectColor => 'Sélectionner la couleur';

  @override
  String get showSeconds => 'Afficher les secondes';

  @override
  String get worldClock => 'Horloge mondiale';

  @override
  String get local => 'Locale';

  @override
  String get use24hrFormat => 'Utiliser le format 24h';

  @override
  String get useFahrenheit => 'Utiliser °F';

  @override
  String get displayMoreInfo => 'Plus d\'infos sur l\'écran d\'accueil';

  @override
  String get widgetSettings => 'Paramètres du Widget';

  @override
  String get widgetPreview => 'Aperçu';

  @override
  String get widgetLayout => 'Disposition';

  @override
  String get layoutDetailed => 'Détaillé';

  @override
  String get layoutCompact => 'Compact';

  @override
  String get widgetTransparency => 'Transparence du widget';

  @override
  String get setWttrServer => 'Définir son propre serveur wttr.in';

  @override
  String get invalidUrl => 'URL invalide';

  @override
  String get urlSaved => 'URL enregistrée';

  @override
  String get urlRestored => 'URL restaurée et enregistrée';

  @override
  String get noChanges => 'Aucun changement à enregistrer';

  @override
  String get unsavedChanges => 'Changements non enregistrés';

  @override
  String get saveChangesPrompt =>
      'Veuillez enregistrer les modifications apportées au serveur wttr.in';

  @override
  String get apiUpdateNotice =>
      'L\'API se mettra à jour dans un maximum de 30 secondes.';

  @override
  String get serverSuccessNotice =>
      'Serveur wttr.in configuré. \nVeuillez vérifier l\'écran d\'accueil pour vous assurer que le nouveau serveur fonctionne correctement. \nL\'API se mettra à jour dans un maximum de 30 secondes.';

  @override
  String get ok => 'OK';

  @override
  String get aboutDescription =>
      'Horloge Mondiale est une application Flutter qui affiche l\'heure et la météo actuelles pour diverses villes. L\'application utilise le thème Material You pour offrir une expérience utilisateur moderne et personnalisable.\nConsultez les nombreux paramètres pour une expérience encore plus personnalisée.';

  @override
  String get licenseDescription =>
      'Cette application est sous licence GNU GPL 3.0. Pour plus de détails, consultez le fichier LICENSE dans le dépôt.';

  @override
  String get contactDescription =>
      'Si vous avez des questions ou des suggestions, n\'hésitez pas à me contacter via GitHub ou à ouvrir un ticket sur le dépôt de cette application.';

  @override
  String get dataSources => 'Sources des données';

  @override
  String get dataSourcesDescription =>
      'Touchez une source pour ouvrir son site web.';

  @override
  String get geoNamesCredit =>
      'Villes avec leurs coordonnées, populations et noms dans d’autres langues. CC BY 4.0';

  @override
  String get cldrCredit =>
      'Noms des pays et des villes dans d’autres langues. Unicode License v3';

  @override
  String get timeZonesCredit => 'Fuseaux horaires des pays. Domaine public';

  @override
  String get flagsCredit => 'Drapeaux';

  @override
  String get weatherCredit => 'Météo, du serveur choisi dans les réglages';

  @override
  String get fontsCredit =>
      'Polices Red Hat Display et Pacifico. SIL Open Font License';

  @override
  String get openWebsite => 'Ouvrir le site web';

  @override
  String get sortByCity => 'Trier par ville';

  @override
  String get sortByCountry => 'Trier par pays';

  @override
  String get sortByUtc => 'Trier par fuseau horaire UTC';

  @override
  String get sortByContinent => 'Trier par continent/région';

  @override
  String searchHint(int count) {
    return 'Rechercher une ville ou un pays ($count trouvés)';
  }

  @override
  String get addCustomCity => 'Ajouter une ville personnalisée';

  @override
  String get cityName => 'Nom de la ville';

  @override
  String get country => 'Pays';

  @override
  String get pickCountryFromList => 'Choisissez un pays dans la liste';

  @override
  String get ianaTimeZone => 'Fuseau horaire IANA';

  @override
  String get pickCountryFirst => 'Choisissez d’abord un pays';

  @override
  String get timeZoneNotInCountry => 'Pas un fuseau horaire de ce pays';

  @override
  String get customCityOfflineHint =>
      'L’heure fonctionne hors ligne. La météo peut être indisponible si wttr.in ne connaît pas cette ville.';

  @override
  String get add => 'Ajouter';

  @override
  String get cancel => 'Annuler';

  @override
  String get editCustomCity => 'Modifier la ville personnalisée';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeLight => 'Clair';

  @override
  String get sortList => 'Trier la liste';

  @override
  String get showList => 'Afficher la liste';

  @override
  String get showMap => 'Afficher la carte';

  @override
  String lastUpdated(String time) {
    return 'Dernière mise à jour $time';
  }

  @override
  String get sunrise => 'Lever du soleil';

  @override
  String get sunset => 'Coucher du soleil';

  @override
  String get forecast => 'Prévisions sur 3 jours';

  @override
  String get nextHours => 'Prochaines heures';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get tomorrow => 'Demain';

  @override
  String feelsLike(String temperature) {
    return 'Ressenti $temperature';
  }

  @override
  String get humidity => 'Humidité';

  @override
  String get wind => 'Vent';

  @override
  String get chanceOfRain => 'Risque de pluie';

  @override
  String get uvIndex => 'Indice UV';

  @override
  String uvIndexValue(String index, String risk) {
    return 'UV $index · $risk';
  }

  @override
  String get uvRiskLow => 'faible';

  @override
  String get uvRiskModerate => 'modéré';

  @override
  String get uvRiskHigh => 'élevé';

  @override
  String get uvRiskVeryHigh => 'très élevé';

  @override
  String get uvRiskExtreme => 'extrême';

  @override
  String get moonPhase => 'Phase de la lune';

  @override
  String get moonNew => 'Nouvelle lune';

  @override
  String get moonWaxingCrescent => 'Premier croissant';

  @override
  String get moonFirstQuarter => 'Premier quartier';

  @override
  String get moonWaxingGibbous => 'Gibbeuse croissante';

  @override
  String get moonFull => 'Pleine lune';

  @override
  String get moonWaningGibbous => 'Gibbeuse décroissante';

  @override
  String get moonLastQuarter => 'Dernier quartier';

  @override
  String get moonWaningCrescent => 'Dernier croissant';

  @override
  String get showForecast => 'Afficher les prévisions';

  @override
  String get manageCities => 'Gérer les villes';

  @override
  String get favorites => 'Vos villes';

  @override
  String get allCities => 'Toutes les villes';

  @override
  String get keepOneCity => 'Au moins une ville doit rester';

  @override
  String get removeFromFavorites => 'Retirer';

  @override
  String get reorderCity => 'Faites glisser pour trier';

  @override
  String cityAddedAt(String city, String time) {
    return '$city ajoutée · $time';
  }

  @override
  String cityRemovedAt(String city, String time) {
    return '$city retirée · $time';
  }

  @override
  String cityPosition(int index, int count) {
    return 'Ville $index sur $count';
  }

  @override
  String get widgetCity => 'Ville du widget';

  @override
  String offsetChangeToday(String change) {
    return 'Changement d\'heure aujourd\'hui : $change';
  }

  @override
  String offsetChangeTomorrow(String change) {
    return 'Changement d\'heure demain : $change';
  }

  @override
  String offsetChangeInDays(int days, String change) {
    return 'Changement d\'heure dans $days jours : $change';
  }

  @override
  String get offsetChangeTooltip => 'Changement d\'heure dans cette ville';
}
