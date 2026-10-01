import 'package:calculadora_eletrica/core/settings/module_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to all modules visible', () async {
    final visible = await ModulePreferences.loadVisibleModules();

    expect(visible, ModulePreferences.allModuleIds);
  });

  test('persists hidden modules across loads', () async {
    final visible = Set<String>.from(ModulePreferences.allModuleIds)
      ..remove('transformer');

    await ModulePreferences.saveVisibleModules(visible);
    final loaded = await ModulePreferences.loadVisibleModules();

    expect(loaded.contains('transformer'), isFalse);
    expect(loaded, visible);
  });

  test('allows hiding every optional module', () async {
    await ModulePreferences.saveVisibleModules(<String>{});

    expect(await ModulePreferences.loadVisibleModules(), isEmpty);
  });

  test('ignores unknown module identifiers when saving', () async {
    await ModulePreferences.saveVisibleModules({
      'motor',
      'futureUnknownModule',
    });

    expect(await ModulePreferences.loadVisibleModules(), {'motor'});
  });

  test('preserves legacy visibility before module version tracking exists', () async {
    SharedPreferences.setMockInitialValues({
      'visible_home_modules': <String>['motor'],
    });

    final visible = await ModulePreferences.loadVisibleModules();

    expect(visible, {'motor'});
  });

  test('shows newly added modules without restoring modules hidden by the user', () async {
    SharedPreferences.setMockInitialValues({
      'visible_home_modules': <String>['motor'],
      'known_home_modules': <String>[
        'motor',
        'transformer',
        'motorTransformer',
        'loadSurvey',
        'cableSizing',
      ],
    });

    final visible = await ModulePreferences.loadVisibleModules();

    expect(visible.contains('motor'), isTrue);
    expect(visible.contains('voltageDrop'), isTrue);
    expect(visible.contains('transformer'), isFalse);
  });

  test('ignores obsolete identifiers already stored', () async {
    SharedPreferences.setMockInitialValues({
      'visible_home_modules': <String>['motor', 'obsoleteModule'],
    });

    expect(await ModulePreferences.loadVisibleModules(), {'motor'});
  });
}
