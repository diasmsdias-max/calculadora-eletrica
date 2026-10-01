import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:calculadora_eletrica/core/database/local_project.dart';
import 'package:calculadora_eletrica/core/database/project_record.dart';
import 'package:calculadora_eletrica/core/pdf/project_pdf_generator.dart';

void main() {
  test('generates a valid PDF with project and all record types', () async {
    final now = DateTime(2026, 9, 30);
    final project = LocalProject(
      id: 'p1',
      name: 'Instalação Industrial',
      client: 'Cliente Teste',
      address: 'Endereço Teste',
      responsible: 'Responsável Técnico',
      notes: 'Relatório de teste',
      createdAt: now,
      updatedAt: now,
    );

    ProjectRecord record(ProjectRecordType type, Map<String, dynamic> data) =>
        ProjectRecord(
          id: type.name,
          projectId: project.id,
          type: type,
          title: type.name,
          summary: 'Resumo',
          data: data,
          createdAt: now,
        );

    final records = [
      record(ProjectRecordType.motor, {
        'system': 'threePhase',
        'voltageV': 220.0,
        'servicePowerKw': 11.03,
        'apparentPowerKva': 14.42,
        'nominalCurrentA': 37.84,
        'estimatedStartingCurrentA': 227.0,
        'monthlyEnergyKwh': 3000.0,
      }),
      record(ProjectRecordType.transformer, {
        'ratedKva': 30.0,
        'system': 'threePhase',
        'voltageV': 220.0,
        'loadUnit': 'kw',
        'availableActivePowerKw': 25.5,
        'loadKva': 20.0,
        'loadPercent': 66.67,
        'remainingKva': 10.0,
        'meetsLoad': true,
      }),
      record(ProjectRecordType.motorTransformer, {
        'transformerKva': 30.0,
        'motorRatedPower': 15.0,
        'motorUnit': 'cv',
        'system': 'threePhase',
        'voltageV': 220.0,
        'powerFactor': 0.85,
        'efficiency': 0.90,
        'motorApparentPowerKva': 14.42,
        'remainingKva': 15.58,
        'motorNominalCurrentA': 37.84,
        'motorTransformerPercent': 48.0,
        'meetsSteadyState': true,
        'motorStartingCurrentA': 227.0,
        'startingMethod': 'direct',
        'startingMultiplier': 6.0,
        'startingKvaEstimate': 86.5,
        'startingTransformerPercent': 288.0,
      }),
      record(ProjectRecordType.loadSurvey, {
        'installedKw': 6.0,
        'demandKw': 5.8,
        'apparentKva': 7.05,
        'demandCurrentA': 18.5,
        'daysPerMonth': 30,
        'dailyKwh': 25.0,
        'monthlyKwh': 750.0,
        'loads': [
          {
            'description': 'Iluminação',
            'unitPowerKw': 0.1,
            'quantity': 10,
            'powerFactor': 1.0,
            'simultaneity': 0.8,
            'hoursPerDay': 5.0,
          },
        ],
      }),
      record(ProjectRecordType.cableSizing, {
        'voltageV': 220.0,
        'designCurrentA': 50.0,
        'sectionMm2': 10.0,
        'material': 'copper',
        'lengthM': 40.0,
        'referenceAmpacityA': 76.0,
        'ampacitySource': 'copperQuick',
        'reactanceOhmPerKm': 0.10,
        'reactanceSource': 'practical_estimate',
        'requiredReferenceAmpacityA': 62.5,
        'correctedAmpacityA': 64.0,
        'ampacityMeets': true,
        'dropV': 4.2,
        'dropPercent': 1.91,
        'voltageDropMeets': true,
        'minimumSectionByDropMm2': 4.8,
        'commercialSectionByDropMm2': 6.0,
        'meetsBothCriteria': true,
      }),
      record(ProjectRecordType.voltageDrop, {
        'voltageV': 220.0,
        'currentA': 20.0,
        'sectionMm2': 4.0,
        'material': 'copper',
        'lengthM': 30.0,
        'reactanceOhmPerKm': 0.08,
        'reactanceSource': 'custom',
        'dropV': 5.25,
        'dropPercent': 2.39,
        'maxDropPercent': 4.0,
        'withinLimit': true,
        'minimumSectionMm2': 2.39,
        'commercialSectionMm2': 2.5,
      }),
    ];

    final bytes = await ProjectPdfGenerator.generate(
      project: project,
      records: records,
    );

    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
  });

  test('generates PDF when commercial section exceeds quick range', () async {
    final now = DateTime(2026, 9, 30);
    final project = LocalProject(
      id: 'range', name: 'Fora da faixa', client: '', address: '',
      responsible: '', notes: '', createdAt: now, updatedAt: now,
    );
    final record = ProjectRecord(
      id: 'vd-range', projectId: project.id, type: ProjectRecordType.voltageDrop,
      title: 'Queda de tensão', summary: 'Acima da faixa', createdAt: now,
      data: {
        'voltageV': 127.0, 'currentA': 200.0, 'sectionMm2': 300.0,
        'material': 'copper', 'lengthM': 500.0, 'reactanceOhmPerKm': 0.10,
        'reactanceSource': 'practical_estimate', 'dropV': 20.0,
        'dropPercent': 15.75, 'maxDropPercent': 1.0, 'withinLimit': false,
        'minimumSectionMm2': double.infinity, 'commercialSectionMm2': null,
      },
    );
    final bytes = await ProjectPdfGenerator.generate(project: project, records: [record]);
    expect(bytes.length, greaterThan(500));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
  });

  test('generates PDF when new source metadata is absent', () async {
    final now = DateTime(2026, 9, 30);
    final project = LocalProject(
      id: 'legacy',
      name: 'Projeto legado',
      client: '',
      address: '',
      responsible: '',
      notes: '',
      createdAt: now,
      updatedAt: now,
    );
    final record = ProjectRecord(
      id: 'legacy-cable',
      projectId: project.id,
      type: ProjectRecordType.cableSizing,
      title: 'Condutor — 6,00 mm²',
      summary: 'Registro anterior',
      data: {
        'voltageV': 220.0,
        'designCurrentA': 40.0,
        'sectionMm2': 6.0,
        'material': 'copper',
        'lengthM': 30.0,
        'requiredReferenceAmpacityA': 40.0,
        'correctedAmpacityA': 41.0,
        'ampacityMeets': true,
        'dropV': 3.0,
        'dropPercent': 1.36,
        'voltageDropMeets': true,
        'meetsBothCriteria': true,
      },
      createdAt: now,
    );
    final bytes = await ProjectPdfGenerator.generate(project: project, records: [record]);
    expect(bytes.length, greaterThan(500));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
  });

  test('generates PDF for project without technical records', () async {
    final now = DateTime(2026, 9, 30);
    final project = LocalProject(
      id: 'empty',
      name: 'Projeto vazio',
      client: '',
      address: '',
      responsible: '',
      notes: '',
      createdAt: now,
      updatedAt: now,
    );

    final bytes = await ProjectPdfGenerator.generate(
      project: project,
      records: const [],
    );

    expect(bytes.length, greaterThan(500));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
  });
}
