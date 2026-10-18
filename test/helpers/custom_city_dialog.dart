import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The picker labeled [label] in the custom city dialog.
Finder dropdownMenu(String label) =>
    find.widgetWithText(DropdownMenu<String>, label);

Finder get countryField => find.descendant(
      of: dropdownMenu('Country'),
      matching: find.byType(TextField),
    );

Finder get timeZoneField => find.descendant(
      of: dropdownMenu('IANA time zone'),
      matching: find.byType(TextField),
    );

/// Labels of the entries the open dropdown menu currently offers.
List<String> menuEntries() => find
    .descendant(
      of: find.byType(MenuItemButton).hitTestable(),
      matching: find.byType(Text),
    )
    .evaluate()
    .map((element) => (element.widget as Text).data!)
    .toList();

/// Searches the countries for [query] and picks the entry [label].
Future<void> pickCountry(
  WidgetTester tester,
  String query, [
  String? label,
]) async {
  await tester.enterText(countryField, query);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label ?? query).last);
  await tester.pumpAndSettle();
}

/// Searches the time zones for [query] and picks the entry [label].
Future<void> pickTimeZone(
  WidgetTester tester,
  String query, [
  String? label,
]) async {
  await tester.enterText(timeZoneField, query);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label ?? query).last);
  await tester.pumpAndSettle();
}
