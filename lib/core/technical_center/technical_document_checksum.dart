import 'package:crypto/crypto.dart';

String technicalDocumentSha256(List<int> bytes) => sha256.convert(bytes).toString();
