import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora_eletrica/core/technical_center/technical_document.dart';

void main(){
  test('remote document is not available offline',(){
    const d=TechnicalDocument(id:'m1',title:'Manual',category:TechnicalDocumentCategory.manufacturerManual,remotePath:'manuals/x.pdf');
    expect(d.isAvailableOffline,isFalse);
  });
  test('downloaded document with local path is available offline',(){
    const d=TechnicalDocument(id:'m1',title:'Manual',category:TechnicalDocumentCategory.manufacturerManual,
      availability:TechnicalDocumentAvailability.downloaded,localPath:'/docs/x.pdf',keepOffline:true);
    expect(d.isAvailableOffline,isTrue);
    expect(d.keepOffline,isTrue);
  });
  test('portable contract preserves catalog and offline metadata',(){
    final now=DateTime.utc(2026,10,2);
    final d=TechnicalDocument(id:'m1',title:'Manual CFW',category:TechnicalDocumentCategory.manufacturerManual,
      manufacturer:'WEG',equipmentType:'Inversor',model:'CFW',remotePath:'manuals/cfw.pdf',
      fileName:'cfw.pdf',sizeBytes:1200,availability:TechnicalDocumentAvailability.downloaded,
      localPath:'/docs/cfw.pdf',keepOffline:true,downloadedAt:now,updatedAt:now);
    final r=TechnicalDocument.fromPortableJson(d.toPortableJson());
    expect(r.manufacturer,'WEG'); expect(r.model,'CFW'); expect(r.keepOffline,isTrue);
    expect(r.isAvailableOffline,isTrue);
  });
}
