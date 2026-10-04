import 'technical_document.dart';

abstract class TechnicalDocumentRepository {
  Future<List<TechnicalDocument>> list();
  Future<TechnicalDocument?> getById(String id);
  Future<void> save(TechnicalDocument document);
  Future<void> delete(String id);
}
