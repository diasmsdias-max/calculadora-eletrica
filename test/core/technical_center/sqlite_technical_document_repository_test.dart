import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calculadora_eletrica/core/database/vis_database.dart';
import 'package:calculadora_eletrica/core/technical_center/technical_document.dart';
import 'package:calculadora_eletrica/core/technical_center/sqlite_technical_document_repository.dart';

void main() {
  sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;

  test('technical catalog persists remote and offline state', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await VisDatabase.createSchemaForTesting(db);
    final repo = SqliteTechnicalDocumentRepository(db);
    final now = DateTime.utc(2026, 10, 2);
    await repo.save(TechnicalDocument(id:'weg-cfw', title:'Manual CFW', category:TechnicalDocumentCategory.manufacturerManual,
      manufacturer:'WEG', equipmentType:'Inversor', model:'CFW', remotePath:'manuals/weg/cfw.pdf',
      fileName:'cfw.pdf', checksum:'abc', sizeBytes:2048, availability:TechnicalDocumentAvailability.downloaded,
      localPath:'/technical/weg/cfw.pdf', keepOffline:true, downloadedAt:now, updatedAt:now));
    final saved = await repo.getById('weg-cfw');
    expect(saved, isNotNull); expect(saved!.manufacturer, 'WEG'); expect(saved.keepOffline, isTrue);
    expect(saved.isAvailableOffline, isTrue); expect((await repo.list()), hasLength(1));
    await db.close();
  });

  test('migration 13 to 14 creates technical catalog without touching professional data', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE professional_projects (id TEXT PRIMARY KEY, name TEXT NOT NULL)');
    await db.insert('professional_projects', {'id':'p1','name':'Projeto preservado'});
    await VisDatabase.upgradeSchemaForTesting(db, 13, 14);
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='technical_documents'");
    expect(tables, isNotEmpty);
    final old = await db.query('professional_projects');
    expect(old.single['name'], 'Projeto preservado');
    await db.close();
  });
}
