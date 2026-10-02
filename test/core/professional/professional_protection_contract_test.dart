import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora_eletrica/core/professional/professional_protection.dart';

void main() {
  final now=DateTime.utc(2026,10,2);

  test('professional protection v2 preserves typed role',(){
    final original=ProfessionalProtection(
      id:'pr',projectId:'p',circuitId:'c',revision:1,name:'QF1',
      deviceType:'Disjuntor',role:ProfessionalProtectionRole.overcurrent,
      ratedCurrentA:20,createdAt:now,updatedAt:now,
    );
    final decoded=ProfessionalProtection.fromPortableJson(original.toPortableJson());
    expect(decoded.role,ProfessionalProtectionRole.overcurrent);
    expect(decoded.ratedCurrentA,20);
  });

  test('professional protection v1 remains readable without inferred role',(){
    final json=ProfessionalProtection(
      id:'pr',projectId:'p',circuitId:'c',revision:1,name:'Proteção',
      deviceType:'Disjuntor',ratedCurrentA:20,createdAt:now,updatedAt:now,
    ).toPortableJson()
      ..['contractVersion']=1
      ..remove('role');
    final decoded=ProfessionalProtection.fromPortableJson(json);
    expect(decoded.role,isNull);
    expect(decoded.deviceType,'Disjuntor');
    expect(decoded.ratedCurrentA,20);
  });
}
