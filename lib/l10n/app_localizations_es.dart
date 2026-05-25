// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'World Clock v2';

  @override
  String get settings => 'Ajustes';

  @override
  String get about => 'Acerca de';

  @override
  String get changeCity => 'Cambiar ciudad';

  @override
  String get sourceCode => 'Código fuente';

  @override
  String get reportBug => 'Reportar un error';

  @override
  String localTime(String time) {
    return 'Hora local: $time';
  }

  @override
  String get loading => 'Cargando...';

  @override
  String get weatherLoading => '🛰️ Cargando...';

  @override
  String get connectionError => '🛜 Error de conexión';

  @override
  String get apiError => '🛜 No se pudo conectar a la API';

  @override
  String get searchCity => 'Buscar ciudad';

  @override
  String get chooseCity => 'Elegir ciudad';

  @override
  String get aboutThisApp => 'Acerca de esta aplicación';

  @override
  String get license => 'Licencia';

  @override
  String get contact => 'Contacto';

  @override
  String currentVersion(String version) {
    return 'Versión actual: v$version';
  }

  @override
  String get defaultTheme => 'Tema predeterminado';

  @override
  String get restartToApply => 'Reiniciar app para aplicar';

  @override
  String get customMaterialColor => 'Color Material personalizado';

  @override
  String get selectColor => 'Seleccionar color';

  @override
  String get showSeconds => 'Mostrar segundos';

  @override
  String get worldClock => 'Reloj mundial';

  @override
  String get local => 'Local';

  @override
  String get use24hrFormat => 'Usar formato 24h';

  @override
  String get useFahrenheit => 'Usar °F';

  @override
  String get displayMoreInfo => 'Más info en pantalla de inicio';

  @override
  String get widgetSettings => 'Ajustes del widget';

  @override
  String get widgetPreview => 'Vista previa';

  @override
  String get widgetLayout => 'Diseño';

  @override
  String get layoutDetailed => 'Detallado';

  @override
  String get layoutCompact => 'Compacto';

  @override
  String get widgetTransparency => 'Transparencia del widget';

  @override
  String get setWttrServer => 'Establecer servidor wttr.in';

  @override
  String get invalidUrl => 'URL no válida';

  @override
  String get urlSaved => 'URL guardada';

  @override
  String get urlRestored => 'URL restaurada y guardada';

  @override
  String get noChanges => 'No hay cambios para guardar';

  @override
  String get unsavedChanges => 'Cambios sin guardar';

  @override
  String get saveChangesPrompt =>
      'Por favor guarda los cambios realizados en el servidor wttr.in';

  @override
  String get apiUpdateNotice =>
      'La API se actualizará en un máximo de 30 segundos.';

  @override
  String get serverSuccessNotice =>
      'Servidor wttr.in configurado. \nPor favor, comprueba la pantalla de inicio para asegurarte de que el servidor funciona correctamente. \nLa API se actualizará en un máximo de 30 segundos.';

  @override
  String get ok => 'Aceptar';

  @override
  String get aboutDescription =>
      'Reloj Mundial es una aplicación Flutter que muestra la hora actual y el clima de varias ciudades. La aplicación utiliza el tema Material You para proporcionar una experiencia de usuario moderna y personalizable.\nEcha un vistazo a los numerosos ajustes para una experiencia aún más personalizada.';

  @override
  String get licenseDescription =>
      'Esta aplicación está bajo la licencia GNU GPL 3.0. Para más detalles, consulta el archivo LICENSE en el repositorio.';

  @override
  String get contactDescription =>
      'Si tienes alguna pregunta o sugerencia, no dudes en contactarme a través de GitHub o abrir un problema (Issue) en el repositorio de esta aplicación.';

  @override
  String get sortByCity => 'Ordenar por ciudad';

  @override
  String get sortByCountry => 'Ordenar por país';

  @override
  String get sortByUtc => 'Ordenar por zona horaria UTC';

  @override
  String get sortByContinent => 'Ordenar por continente/región';

  @override
  String searchHint(int count) {
    return 'Buscar ciudad o país ($count encontrados)';
  }
}
