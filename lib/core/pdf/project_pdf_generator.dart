import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../formatters/technical_format.dart';

import '../database/local_project.dart';
import '../database/project_record.dart';

class ProjectPdfGenerator {
  static Future<Uint8List> generate({
    required LocalProject project,
    required List<ProjectRecord> records,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => _header(project),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          pw.Text('RELATÓRIO TÉCNICO', style: const pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(project.name, style: const pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 18),
          _projectData(project),
          pw.SizedBox(height: 18),
          pw.Text('Registros técnicos', style: const pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (records.isEmpty)
            pw.Text('Nenhum registro técnico salvo neste projeto.')
          else
            ...records.expand((record) => [_record(record), pw.SizedBox(height: 12)]),
          pw.SizedBox(height: 8),
          _generalNote(),
        ],
      ),
    );
    return pdf.save();
  }

  static pw.Widget _header(LocalProject project) => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 8),
    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400))),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('BOECKER', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
            pw.Text('VIS ELECTRICA', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.amber800)),
            pw.Text('Ferramentas Elétricas Profissionais', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
          ],
        ),
        pw.Text(project.name, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ],
    ),
  );

  static pw.Widget _projectData(LocalProject p) {
    final rows = <List<String>>[
      ['Projeto', p.name],
      if (p.client.isNotEmpty) ['Cliente', p.client],
      if (p.address.isNotEmpty) ['Endereço', p.address],
      if (p.responsible.isNotEmpty) ['Responsável', p.responsible],
      ['Atualizado em', _date(p.updatedAt)],
      if (p.notes.isNotEmpty) ['Observações', p.notes],
    ];
    return pw.TableHelper.fromTextArray(
      headers: const ['Identificação', 'Informação'],
      data: rows,
      headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.all(5),
    );
  }

  static pw.Widget _record(ProjectRecord r) => pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    padding: const pw.EdgeInsets.all(10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(_typeLabel(r.type), style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 3),
        pw.Text(_pdfSafeText(r.title), style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        if (r.summary.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Text(_pdfSafeText(r.summary), style: const pw.TextStyle(fontSize: 9)),
        ],
        pw.SizedBox(height: 7),
        ..._recordDetails(r),
        pw.SizedBox(height: 5),
        pw.Text('Registrado em ${_date(r.createdAt)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ],
    ),
  );

  static List<pw.Widget> _recordDetails(ProjectRecord r) {
    final d = r.data;
    switch (r.type) {
      case ProjectRecordType.motor:
        return _lines([
          ['Sistema', _system(d['system'])],
          ['Tensão', _unit(d['voltageV'], 'V')],
          ['Potência aparente', _unit(d['apparentPowerKva'], 'kVA')],
          ['Corrente nominal', _unit(d['nominalCurrentA'], 'A')],
          ['Corrente de partida estimada', _unit(d['estimatedStartingCurrentA'], 'A')],
          ['Consumo mensal estimado', _unit(d['monthlyEnergyKwh'], 'kWh')],
          ['Observação', 'Corrente de partida e consumo são estimativas conforme os dados informados.'],
        ]);
      case ProjectRecordType.transformer:
        return _lines([
          ['Transformador', _unit(d['ratedKva'], 'kVA')],
          ['Sistema', _system(d['system'])],
          ['Tensão secundária', _unit(d['voltageV'], 'V')],
          ['Carga equivalente', _unit(d['loadKva'], 'kVA')],
          ['Carregamento', _unit(d['loadPercent'], '%')],
          ['Capacidade restante', _unit(d['remainingKva'], 'kVA')],
          ['Regime permanente', d['meetsLoad'] == true ? 'ATENDE' : 'NÃO ATENDE'],
          ['Observação', 'A indicação considera capacidade nominal em regime permanente; partidas e quedas de tensão exigem análise específica.'],
        ]);
      case ProjectRecordType.motorTransformer:
        return _lines([
          ['Transformador', _unit(d['transformerKva'], 'kVA')],
          ['Motor', '${_num(d['motorRatedPower'])} ${(d['motorUnit'] ?? '').toString().toUpperCase()}'],
          ['Tensão', _unit(d['voltageV'], 'V')],
          ['Corrente nominal do motor', _unit(d['motorNominalCurrentA'], 'A')],
          ['Transformador ocupado', _unit(d['motorTransformerPercent'], '%')],
          ['Regime permanente', d['meetsSteadyState'] == true ? 'ATENDE' : 'NÃO ATENDE'],
          ['Corrente de partida estimada', _unit(d['motorStartingCurrentA'], 'A')],
          ['Demanda aparente na partida', _unit(d['startingKvaEstimate'], 'kVA')],
          ['Relação na partida', _unit(d['startingTransformerPercent'], '%')],
          ['Observação', 'A estimativa de partida não confirma isoladamente a capacidade de partida do transformador.'],
        ]);
      case ProjectRecordType.loadSurvey:
        final loads = (d['loads'] as List?) ?? const [];
        return [
          ..._lines([
            ['Potência instalada', _unit(d['installedKw'], 'kW')],
            ['Demanda estimada', _unit(d['demandKw'], 'kW')],
            ['Potência aparente', _unit(d['apparentKva'], 'kVA')],
            ['Corrente de demanda', _unit(d['demandCurrentA'], 'A')],
            ['Consumo mensal estimado', _unit(d['monthlyKwh'], 'kWh')],
          ]),
          if (loads.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text('Cargas', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            pw.SizedBox(height: 3),
            pw.TableHelper.fromTextArray(
              headers: const ['Descrição', 'Pot. unit.', 'Qtd.', 'FP', 'Simult.', 'h/dia'],
              data: loads.map((raw) {
                final m = Map<String, dynamic>.from(raw as Map);
                return [
                  (m['description'] ?? '').toString(),
                  _unit(m['unitPowerKw'], 'kW'),
                  (m['quantity'] ?? '').toString(),
                  _num(m['powerFactor']),
                  '${_numPercentFraction(m['simultaneity'])}%',
                  _num(m['hoursPerDay']),
                ];
              }).toList(),
              headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellPadding: const pw.EdgeInsets.all(3),
            ),
          ],
        ];
      case ProjectRecordType.cableSizing:
        return _lines([
          ['Circuito', '${_unit(d['voltageV'], 'V')} | ${_unit(d['designCurrentA'], 'A')}'],
          ['Condutor', '${_unit(d['sectionMm2'], 'mm²')} | ${_material(d['material'])}'],
          ['Comprimento', _unit(d['lengthM'], 'm')],
          ['Ampacidade informada', '${_unit(d['referenceAmpacityA'], 'A')} | ${_ampacitySource(d['ampacitySource'])}'],
          ['Reatância X', '${_unit(d['reactanceOhmPerKm'], 'Ω/km')} | ${_reactanceSource(d['reactanceSource'])}'],
          ['Iz mínima de referência', _unit(d['requiredReferenceAmpacityA'], 'A')],
          ['Iz corrigida', _unit(d['correctedAmpacityA'], 'A')],
          ['Capacidade de corrente', d['ampacityMeets'] == true ? 'ATENDE' : 'NÃO ATENDE'],
          ['Queda de tensão', '${_unit(d['dropV'], 'V')} (${_unit(d['dropPercent'], '%')})'],
          ['Critério de queda', d['voltageDropMeets'] == true ? 'ATENDE' : 'NÃO ATENDE'],
          ['Resultado parcial', d['meetsBothCriteria'] == true ? 'ATENDE AOS DOIS CRITÉRIOS' : 'NÃO ATENDE AOS DOIS CRITÉRIOS'],
          ['Observação', 'Resultado parcial: capacidade de corrente corrigida e queda de tensão. Verificar também proteção, curto-circuito, seção mínima e demais requisitos aplicáveis.'],
        ]);
      case ProjectRecordType.voltageDrop:
        return _lines([
          ['Circuito', '${_unit(d['voltageV'], 'V')} | ${_unit(d['currentA'], 'A')}'],
          ['Condutor', '${_unit(d['sectionMm2'], 'mm²')} | ${_material(d['material'])}'],
          ['Comprimento', _unit(d['lengthM'], 'm')],
          ['Reatância X', '${_unit(d['reactanceOhmPerKm'], 'Ω/km')} | ${_reactanceSource(d['reactanceSource'])}'],
          ['Queda', '${_unit(d['dropV'], 'V')} (${_unit(d['dropPercent'], '%')})'],
          ['Limite informado', _unit(d['maxDropPercent'], '%')],
          ['Resultado', d['withinLimit'] == true ? 'DENTRO DO LIMITE' : 'ACIMA DO LIMITE'],
          ['Seção mínima pelo critério de queda', _unit(d['minimumSectionMm2'], 'mm²')],
          ['Observação', 'A seção indicada considera somente o critério matemático de queda de tensão.'],
        ]);
    }
  }

  static List<pw.Widget> _lines(List<List<String>> rows) => rows.map((row) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.RichText(text: pw.TextSpan(
      style: const pw.TextStyle(fontSize: 8.5),
      children: [
        pw.TextSpan(text: '${row[0]}: ', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.TextSpan(text: row[1]),
      ],
    )),
  )).toList();

  static pw.Widget _generalNote() => pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
    child: pw.Text(
      'Nota: este relatório registra os dados e resultados calculados pelo aplicativo. '
      'Critérios parciais não substituem verificações normativas, dados de fabricantes, '
      'condições reais da instalação nem responsabilidade técnica quando aplicável.',
      style: const pw.TextStyle(fontSize: 8),
    ),
  );

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _num(dynamic value) {
    if (value == null) return '-';
    if (value is num) {
      if (!value.toDouble().isFinite) return 'não determinado';
      return TechnicalFormat.number(value, decimals: 2);
    }
    return value.toString();
  }

  static String _unit(dynamic value, String unit) => value == null ? '-' : '${_num(value)} $unit';

  static String _numPercentFraction(dynamic value) {
    if (value is num) return TechnicalFormat.number(value.toDouble() * 100, decimals: 0);
    return '-';
  }

  static String _system(dynamic value) => switch (value?.toString()) {
    'singlePhase' => 'Monofásico',
    'twoPhase' => 'Bifásico',
    'threePhase' => 'Trifásico',
    _ => value?.toString() ?? '-',
  };

  static String _ampacitySource(dynamic value) => switch (value?.toString()) {
    'copperQuick' => 'referência rápida Cu',
    'aluminumQuick' => 'referência rápida Al',
    'custom' => 'personalizado',
    _ => 'não registrado',
  };

  static String _reactanceSource(dynamic value) => switch (value?.toString()) {
    'practical_estimate' => 'estimativa rápida',
    'custom' => 'personalizado',
    _ => 'não registrado',
  };

  static String _material(dynamic value) => switch (value?.toString()) {
    'copper' => 'Cobre',
    'aluminum' => 'Alumínio',
    _ => value?.toString() ?? '-',
  };

  static String _pdfSafeText(String value) => value
      .replaceAll('×', '-')
      .replaceAll(' x ', ' - ')
      .replaceAll('•', '|')
      .replaceAll('—', '-');

  static String _typeLabel(ProjectRecordType type) => switch (type) {
    ProjectRecordType.motor => 'MOTOR ELÉTRICO',
    ProjectRecordType.transformer => 'TRANSFORMADOR',
    ProjectRecordType.motorTransformer => 'MOTOR - TRANSFORMADOR',
    ProjectRecordType.loadSurvey => 'LEVANTAMENTO DE CARGAS',
    ProjectRecordType.cableSizing => 'DIMENSIONAMENTO DE CABOS',
    ProjectRecordType.voltageDrop => 'QUEDA DE TENSÃO',
  };
}
