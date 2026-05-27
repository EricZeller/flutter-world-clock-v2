import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:world_clock_v2/data/data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colornames/colornames.dart';
import 'package:world_clock_v2/services/settings_provider.dart';
import 'package:world_clock_v2/l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String dropdownValue = themeList.first;

  Future<void> _saveStringValue(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveIntValue(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> _saveBoolValue(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> saveColor(Color color) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String colorString = color.value.toRadixString(16);
    await prefs.setString('colorString', colorString);
  }

  Future<void> getThemeModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.getString('themeMode') != null) {
        spThemeMode = prefs.getString('themeMode');
      }
    });
  }

  final TextEditingController _urlController = TextEditingController();

  bool _isValidUrl = true;

  void _saveUrl(AppLocalizations l10n) {
    if (checkChangedServer()) {
      final enteredUrl = _urlController.text;
      if (_isValid(enteredUrl)) {
        setState(() {
          wttrServer = enteredUrl;
        });
        _saveStringValue('wttrServer', enteredUrl);
        showAlertDialog(context, l10n.urlSaved,
            l10n.serverSuccessNotice);
      } else {
        setState(() {
          _isValidUrl = false;
        });
      }
    } else {
      showAlertDialog(context, l10n.noChanges, "");
    }
  }

  bool _isValid(String url) {
    final regExp = RegExp(r'^(https?:\/\/)([a-zA-Z0-9\-]+\.)+[a-zA-Z0-9\-]+$');
    return regExp.hasMatch(url) && !url.endsWith('/');
  }

  @override
  void initState() {
    super.initState();
    getThemeModePreference();
    dropdownValue = spThemeMode!;
    _urlController.text = wttrServer;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WidgetStateProperty<Icon?> thumbIconLocal =
        WidgetStateProperty.resolveWith<Icon?>(
      (Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return const Icon(Icons.location_on);
        }
        return const Icon(Icons.location_off);
      },
    );

    final WidgetStateProperty<Icon?> thumbIconGlobal =
        WidgetStateProperty.resolveWith<Icon?>(
      (Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return const Icon(Icons.public);
        }
        return const Icon(Icons.public_off);
      },
    );

    final WidgetStateProperty<Icon?> thumbIcon =
        WidgetStateProperty.resolveWith<Icon?>(
      (Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return const Icon(Icons.check);
        }
        return const Icon(Icons.close);
      },
    );
    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      final l10n = AppLocalizations.of(context)!;
      return DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          ColorScheme lightColorScheme;
          ColorScheme darkColorScheme;

          if (lightDynamic != null && darkDynamic != null && !useCustomColor) {
            lightColorScheme = lightDynamic.harmonized();
            darkColorScheme = darkDynamic.harmonized();
          } else {
            lightColorScheme =
                ColorScheme.fromSeed(seedColor: settings.customColor)
                    .harmonized();
            darkColorScheme = ColorScheme.fromSeed(
                    seedColor: settings.customColor,
                    brightness: Brightness.dark)
                .harmonized();
          }

          ThemeMode? themeModePreference;

          if (spThemeMode == themeList[0]) {
            themeModePreference = ThemeMode.system;
          } else if (spThemeMode == themeList[1]) {
            themeModePreference = ThemeMode.dark;
          } else if (spThemeMode == themeList[2]) {
            themeModePreference = ThemeMode.light;
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'World clock',
            theme: ThemeData(
              fontFamily: 'Red Hat Display',
              colorScheme: lightColorScheme,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
                fontFamily: 'Red Hat Display',
                colorScheme: darkColorScheme,
                useMaterial3: true,
                cardColor: Colors.amber),
            themeMode: themeModePreference,
            home: Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              appBar: AppBar(
                centerTitle: true,
                title: Text(
                  l10n.settings,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontFamily: "Pacifico",
                      fontSize: 24),
                ),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    semanticLabel: l10n.ok,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (!checkChangedServer()) {
                      Navigator.pop(context);
                    } else {
                      showAlertDialog(context, l10n.unsavedChanges,
                          l10n.saveChangesPrompt);
                    }
                  },
                ),
              ),
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Card(
                        elevation: 40,
                        shadowColor: Theme.of(context).colorScheme.primary,
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(l10n.defaultTheme),
                              subtitle: Text(l10n.restartToApply),
                              leading: Icon(Icons.light_mode_outlined, semanticLabel: l10n.defaultTheme),
                              trailing: DropdownButton(
                                value: dropdownValue,
                                onChanged: (String? value) {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    dropdownValue = value!;
                                    spThemeMode = dropdownValue;
                                    _saveStringValue('themeMode', spThemeMode!);
                                  });
                                },
                                items: themeList.map<DropdownMenuItem<String>>(
                                    (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ),
                            ListTile(
                              leading: Icon(Icons.color_lens_outlined, semanticLabel: l10n.customMaterialColor),
                              title: Text(l10n.customMaterialColor),
                              trailing: Switch(
                                thumbIcon: thumbIcon,
                                value: Provider.of<SettingsProvider>(context)
                                    .useCustomColor,
                                onChanged: (bool value) {
                                  HapticFeedback.lightImpact();
                                  Provider.of<SettingsProvider>(context,
                                          listen: false)
                                      .setUseCustomColor(value);
                                  setState(() {
                                    useCustomColor = value;
                                  });
                                  _saveBoolValue(
                                      "useCustomColor", useCustomColor);
                                },
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 750),
                              curve: Curves.easeInOut,
                              height: useCustomColor ? 70 : 0,
                              child: Visibility(
                                visible: useCustomColor,
                                child: ColorPickerTile(
                                  materialColors: materialColors,
                                  selectedColor: materialColors[colorIndex],
                                  onColorSelected: (Color color) {
                                    colorIndex = materialColors.indexOf(color);
                                    _saveIntValue("colorIndex",
                                        materialColors.indexOf(color));
                                    // Hier kannst du die Logik für das Speichern und Weiterverwenden der ausgewählten Farbe einfügen.
                                    spCustomColor = color;
                                    Provider.of<SettingsProvider>(context,
                                            listen: false)
                                        .setCustomColor(color);
                                    // Update der UI
                                    (context as Element).markNeedsBuild();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Card(
                        elevation: 40,
                        shadowColor: Theme.of(context).colorScheme.primary,
                        child: ListTile(
                          leading: const Icon(Icons.widgets_outlined),
                          title: Text(l10n.widgetSettings),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pushNamed(context, '/widget_settings');
                          },
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Card(
                        elevation: 40,
                        shadowColor: Theme.of(context).colorScheme.primary,
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(l10n.showSeconds),
                              leading: Icon(Icons.schedule, semanticLabel: l10n.showSeconds),
                              subtitle: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(l10n.worldClock),
                                  Switch(
                                    thumbIcon: thumbIconGlobal,
                                    value: showSeconds,
                                    onChanged: (bool value) {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        showSeconds = value;
                                      });
                                      _saveBoolValue(
                                          "showSeconds", showSeconds);
                                    },
                                  ),
                                  Text(l10n.local),
                                  Switch(
                                    thumbIcon: thumbIconLocal,
                                    value: showSecondsLocal,
                                    onChanged: (bool value) {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        showSecondsLocal = value;
                                      });
                                      _saveBoolValue(
                                          "showSecondsLocal", showSecondsLocal);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            ListTile(
                              leading: Icon(Icons.travel_explore, semanticLabel: l10n.use24hrFormat),
                              title: Text(l10n.use24hrFormat),
                              trailing: Switch(
                                thumbIcon: thumbIcon,
                                value: sp24hr,
                                onChanged: (bool value) {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    sp24hr = value;
                                  });
                                  _saveBoolValue("use24hr", sp24hr);
                                },
                              ),
                            ),
                            ListTile(
                              leading: Icon(Icons.thermostat, semanticLabel: l10n.useFahrenheit),
                              title: Text(l10n.useFahrenheit),
                              trailing: Switch(
                                thumbIcon: thumbIcon,
                                value: useFahrenheit,
                                onChanged: (bool value) {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    useFahrenheit = value;
                                  });
                                  _saveBoolValue(
                                      "useFahrenheit", useFahrenheit);
                                },
                              ),
                            ),
                            ListTile(
                              leading: Icon(Icons.info_outline, semanticLabel: l10n.displayMoreInfo),
                              title:
                                  Text(l10n.displayMoreInfo),
                              trailing: Switch(
                                thumbIcon: thumbIcon,
                                value: spMoreInfo,
                                onChanged: (bool value) {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    spMoreInfo = value;
                                  });
                                  _saveBoolValue("spMoreInfo", spMoreInfo);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Card(
                        elevation: 40,
                        shadowColor: Theme.of(context).colorScheme.primary,
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Icon(Icons.link, semanticLabel: l10n.setWttrServer),
                                title: TextField(
                                  controller: _urlController,
                                  keyboardType: TextInputType.url,
                                  decoration: InputDecoration(
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        HapticFeedback.mediumImpact();
                                        setState(() {
                                          wttrServer = "https://wttr.in";
                                          _urlController.text =
                                              "https://wttr.in";
                                          _isValidUrl = true;
                                        });
                                        _saveStringValue(
                                            'wttrServer', wttrServer);
                                        showAlertDialog(
                                            context,
                                            l10n.urlRestored,
                                            l10n.apiUpdateNotice);
                                      },
                                      icon:
                                          const Icon(Icons.restart_alt_rounded),
                                    ),
                                    labelText: l10n.setWttrServer,
                                    hintText: wttrServer,
                                    errorText:
                                        _isValidUrl ? null : l10n.invalidUrl,
                                    border: const OutlineInputBorder(),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    if (_isValid(value)) {
                                      setState(() {
                                        _isValidUrl = true;
                                      });
                                    } else {
                                      setState(() {
                                        _isValidUrl = false;
                                      });
                                    }
                                  },
                                  onSubmitted: (value) {
                                    HapticFeedback.lightImpact();
                                    _saveUrl(l10n);
                                  },
                                ),
                                trailing: CircleAvatar(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  child: IconButton(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    icon: Icon(Icons.save_outlined, semanticLabel: l10n.urlSaved),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      _saveUrl(l10n);
                                    },
                                  ),
                                ),
                              ),
              
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (!checkChangedServer()) {
                    Navigator.pop(context);
                  } else {
                    showAlertDialog(context, l10n.unsavedChanges,
                        l10n.saveChangesPrompt);
                  }
                },
                child: Icon(Icons.check, semanticLabel: l10n.ok),
              ),
            ),
          );
        },
      );
    });
  }

  void showAlertDialog(BuildContext context, String title, String content) {
    // set up the button
    Widget okButton = ElevatedButton(
      child: const Text("OK"),
      onPressed: () {
        Navigator.of(context).pop(); // dismiss the dialog
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  bool checkChangedServer() {
    return wttrServer != _urlController.text;
  }
}

final List<Color> materialColors = [
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.yellow,
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
  Colors.brown,
  Colors.grey,
  Colors.blueGrey,
];

class ColorPickerTile extends StatefulWidget {
  final List<Color> materialColors;
  final Color selectedColor;
  final Function(Color) onColorSelected;

  const ColorPickerTile({
    super.key,
    required this.materialColors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  ColorPickerTileState createState() => ColorPickerTileState();
}

class ColorPickerTileState extends State<ColorPickerTile> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text("Select color"),
      leading:
          Icon(Icons.format_color_fill_rounded, color: widget.selectedColor),
      trailing: DropdownButton<Color>(
        value: widget.selectedColor,
        items: widget.materialColors.map((Color color) {
          List<String> guessedColorList = ColorNames.guess(color).split(" ");
          String guessedColor;
          if (guessedColorList.length <= 2) {
            guessedColor = ColorNames.guess(color);
          } else {
            guessedColor = '${guessedColorList[0]} ${guessedColorList[1]}';
          }
          return DropdownMenuItem<Color>(
            value: color,
            child: Row(
              children: [
                CircleAvatar(
                  maxRadius: 10,
                  backgroundColor: color,
                ),
                const SizedBox(width: 5),
                Text(
                  guessedColor,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (Color? newColor) {
          if (newColor != null) {
            widget.onColorSelected(newColor);
          }
        },
      ),
    );
  }
}
