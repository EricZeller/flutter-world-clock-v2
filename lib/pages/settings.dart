import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:world_clock_v2/data/data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.title});

  final String title;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String dropdownValue = themeList.first;

  Future<void> _saveStringValue(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveBoolValue(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
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
  bool _cameFromFAB = false;

  void _saveUrl() {
    final enteredUrl = _urlController.text;
    if (_isValid(enteredUrl)) {
      setState(() {
        wttrServer = enteredUrl;
      });
      _saveStringValue('wttrServer', enteredUrl);
      showAlertDialog(context);
      if (_cameFromFAB) Navigator.popAndPushNamed(context, '/home');
      _cameFromFAB = false;
    } else {
      setState(() {
        _isValidUrl = false;
      });
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

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          lightColorScheme =
              ColorScheme.fromSeed(seedColor: Colors.indigo).harmonized();
          darkColorScheme = ColorScheme.fromSeed(
                  seedColor: Colors.indigo, brightness: Brightness.dark)
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
            colorScheme: lightColorScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
          ),
          themeMode: themeModePreference,
          home: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Text(
                widget.title,
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
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Column(
              children: [
                ListTile(
                  title: const Text("Default theme"),
                  subtitle: const Text("Restart app to apply"),
                  leading: const Icon(Icons.color_lens),
                  trailing: DropdownButton(
                    value: dropdownValue,
                    onChanged: (String? value) {
                      setState(() {
                        dropdownValue = value!;
                        spThemeMode = dropdownValue;
                        _saveStringValue('themeMode', spThemeMode!);
                      });
                    },
                    items:
                        themeList.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                ListTile(
                  title: const Text("Show seconds"),
                  leading: const Icon(Icons.schedule),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("World clock"),
                      Switch(
                        thumbIcon: thumbIconGlobal,
                        value: showSeconds,
                        onChanged: (bool value) {
                          setState(() {
                            showSeconds = value;
                          });
                          _saveBoolValue("showSeconds", showSeconds);
                        },
                      ),
                      const Text("Local"),
                      Switch(
                        thumbIcon: thumbIconLocal,
                        value: showSecondsLocal,
                        onChanged: (bool value) {
                          setState(() {
                            showSecondsLocal = value;
                          });
                          _saveBoolValue("showSecondsLocal", showSecondsLocal);
                        },
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.travel_explore),
                  title: const Text("Use 24hr format"),
                  trailing: Switch(
                    thumbIcon: thumbIcon,
                    value: sp24hr,
                    onChanged: (bool value) {
                      setState(() {
                        sp24hr = value;
                      });
                      _saveBoolValue("use24hr", sp24hr);
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            wttrServer = "https://wttr.in";
                            _urlController.text = "https://wttr.in";
                            _isValidUrl = true;
                          });
                        },
                        icon: const Icon(Icons.restart_alt_rounded),
                      ),
                      labelText: "Set own wttr.in server",
                      hintText: wttrServer,
                      errorText: _isValidUrl ? null : 'Invalid URL',
                      border: const OutlineInputBorder(),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error),
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
                      _saveUrl();
                    },
                  ),
                  trailing: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      color: Theme.of(context).colorScheme.onPrimary,
                      icon: const Icon(Icons.save_outlined),
                      onPressed: _saveUrl,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text("Language"),
                  subtitle: const Text("In progress"),
                  leading: const Icon(Icons.language),
                  trailing: Text(spLanguage),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              onPressed: () {
                _cameFromFAB = true;
                _saveUrl();
              },
              child: const Icon(Icons.check),
            ),
          ),
        );
      },
    );
  }

  void showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = ElevatedButton(
      child: const Text("OK"),
      onPressed: () {
        Navigator.of(context).pop(); // dismiss the dialog
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("URL saved"),
      content: const Text("wttr.in server setted"),
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
}
