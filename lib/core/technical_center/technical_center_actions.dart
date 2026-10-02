import 'technical_document.dart';

abstract class TechnicalCenterActions {
  Future<void> syncCatalog();

  Future<TechnicalDocument> download(
    TechnicalDocument document, {
    bool keepOffline = false,
  });

  Future<TechnicalDocument> removeLocalCopy(TechnicalDocument document);

  Future<bool> validateLocalCopy(TechnicalDocument document);
}
