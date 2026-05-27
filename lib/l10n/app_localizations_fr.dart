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
  String get changeCity => 'Changer de ville';

  @override
  String get sourceCode => 'Code source';

  @override
  String get reportBug => 'Signaler un bug';

  @override
  String localTime(String time) {
    return 'Heure locale : $time';
  }

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
  String get chooseCity => 'Choisir une ville';

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
  String get restartToApply => 'Redémarrer l\'application pour appliquer';

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
}
