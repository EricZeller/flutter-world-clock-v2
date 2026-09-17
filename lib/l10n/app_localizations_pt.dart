// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'World Clock v2';

  @override
  String get settings => 'Configurações';

  @override
  String get about => 'Sobre';

  @override
  String get changeCity => 'Alterar cidade';

  @override
  String get sourceCode => 'Código-fonte';

  @override
  String get reportBug => 'Relatar um erro';

  @override
  String localTime(String time) {
    return 'Hora local: $time';
  }

  @override
  String get timeDifferenceTooltip => 'Diferença em relação à hora local';

  @override
  String get loading => 'Carregando...';

  @override
  String get weatherLoading => '🛰️ Carregando...';

  @override
  String get connectionError => '🛜 Erro de conexão';

  @override
  String get apiError => '🛜 Não foi possível conectar à API';

  @override
  String get searchCity => 'Pesquisar cidade';

  @override
  String get chooseCity => 'Escolher cidade';

  @override
  String get aboutThisApp => 'Sobre este aplicativo';

  @override
  String get license => 'Licença';

  @override
  String get contact => 'Contato';

  @override
  String currentVersion(String version) {
    return 'Versão atual: v$version';
  }

  @override
  String get defaultTheme => 'Tema padrão';

  @override
  String get restartToApply => 'Reinicie o aplicativo para aplicar';

  @override
  String get customMaterialColor => 'Cor Material personalizada';

  @override
  String get selectColor => 'Selecionar cor';

  @override
  String get showSeconds => 'Mostrar segundos';

  @override
  String get worldClock => 'Relógio mundial';

  @override
  String get local => 'Local';

  @override
  String get use24hrFormat => 'Usar formato de 24 horas';

  @override
  String get useFahrenheit => 'Usar °F';

  @override
  String get displayMoreInfo => 'Mostrar mais informações na tela inicial';

  @override
  String get widgetSettings => 'Configurações do widget';

  @override
  String get widgetPreview => 'Pré-visualização';

  @override
  String get widgetLayout => 'Layout';

  @override
  String get layoutDetailed => 'Detalhado';

  @override
  String get layoutCompact => 'Compacto';

  @override
  String get widgetTransparency => 'Transparência do widget';

  @override
  String get setWttrServer => 'Definir servidor wttr.in';

  @override
  String get invalidUrl => 'URL inválida';

  @override
  String get urlSaved => 'URL salva';

  @override
  String get urlRestored => 'URL restaurada e salva';

  @override
  String get noChanges => 'Nenhuma alteração para salvar';

  @override
  String get unsavedChanges => 'Alterações não salvas';

  @override
  String get saveChangesPrompt =>
      'Salve as alterações feitas no servidor wttr.in';

  @override
  String get apiUpdateNotice =>
      'A API será atualizada em no máximo 30 segundos.';

  @override
  String get serverSuccessNotice =>
      'Servidor wttr.in configurado. \nVerifique a tela inicial para confirmar que o servidor está funcionando corretamente. \nA API será atualizada em no máximo 30 segundos.';

  @override
  String get ok => 'OK';

  @override
  String get aboutDescription =>
      'O World Clock é um aplicativo Flutter que mostra a hora atual e o clima de várias cidades. O aplicativo usa o tema Material You para oferecer uma experiência moderna e personalizável.\nConfira as diversas configurações para uma experiência ainda mais personalizada.';

  @override
  String get licenseDescription =>
      'Este aplicativo está licenciado sob a GNU GPL 3.0. Para mais detalhes, consulte o arquivo LICENSE no repositório.';

  @override
  String get contactDescription =>
      'Se tiver alguma dúvida ou sugestão, entre em contato pelo GitHub ou abra uma issue no repositório deste aplicativo.';

  @override
  String get sortByCity => 'Ordenar por cidade';

  @override
  String get sortByCountry => 'Ordenar por país';

  @override
  String get sortByUtc => 'Ordenar por fuso horário UTC';

  @override
  String get sortByContinent => 'Ordenar por continente/região';

  @override
  String searchHint(int count) {
    return 'Pesquisar cidade ou país ($count encontrados)';
  }

  @override
  String get addCustomCity => 'Adicionar cidade personalizada';

  @override
  String get cityName => 'Nome da cidade';

  @override
  String get countryOptional => 'País (opcional)';

  @override
  String get flagOptional => 'Bandeira (opcional)';

  @override
  String get ianaTimeZone => 'Fuso horário IANA';

  @override
  String get customCityOfflineHint =>
      'O horário funciona offline. O clima pode não estar disponível se o wttr.in não reconhecer esta cidade.';

  @override
  String get add => 'Adicionar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get editCustomCity => 'Editar cidade personalizada';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Excluir';

  @override
  String citySelected(Object city) {
    return '$city selecionada';
  }
}
