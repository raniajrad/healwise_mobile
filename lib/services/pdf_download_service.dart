import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfDownloadService {
  static Future<bool> generateAndDownloadPDF({
    required String patientName,
    required String doctorName,
    required String status,
    required String date,
    required Map<String, dynamic> beforeData,
    required Map<String, dynamic> afterData,
  }) async {
    try {
      // Demander permission
      if (!await _requestStoragePermission()) {
        return false;
      }

      // Générer le PDF
      final pdf = await _generatePDF(
        patientName: patientName,
        doctorName: doctorName,
        status: status,
        date: date,
        beforeData: beforeData,
        afterData: afterData,
      );

      // Sauvegarder
      final fileName =
          'rapport_medical_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = await _savePDF(pdf, fileName);

      if (file != null) {
        await OpenFile.open(file.path);
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur génération PDF: $e');
      return false;
    }
  }

  static Future<pw.Document> _generatePDF({
    required String patientName,
    required String doctorName,
    required String status,
    required String date,
    required Map<String, dynamic> beforeData,
    required Map<String, dynamic> afterData,
  }) async {
    final pdf = pw.Document();

    final statusColor = status == 'alert'
        ? PdfColors.red
        : (status == 'attention' ? PdfColors.orange : PdfColors.green);

    final statusText = status == 'alert'
        ? 'URGENT - Consultez un médecin'
        : (status == 'attention' ? 'À SURVEILLER' : 'État stable');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // En-tête
            pw.Container(
              padding: pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue700,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'HEALWISE',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Rapport Médical Complet',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 14),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Infos patient
            pw.Container(
              padding: pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                children: [
                  _infoRow('Patient:', patientName),
                  _infoRow('Médecin:', doctorName),
                  _infoRow('Date:', date),
                  pw.Divider(),
                  _infoRow('Statut:', statusText, color: statusColor),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Tableau des mesures
            pw.Text(
              '📈 Évolution des paramètres',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                // En-tête
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _headerCell('Paramètre'),
                    _headerCell('Avant'),
                    _headerCell('Après'),
                    _headerCell('Norme'),
                    _headerCell('Status'),
                  ],
                ),
                // Lignes
                _tableRow(
                  'Pression systolique',
                  beforeData['systolic']?.toDouble() ?? 0,
                  afterData['systolic']?.toDouble() ?? 0,
                  'mmHg',
                  '90-140',
                ),
                _tableRow(
                  'Pression diastolique',
                  beforeData['diastolic']?.toDouble() ?? 0,
                  afterData['diastolic']?.toDouble() ?? 0,
                  'mmHg',
                  '60-90',
                ),
                _tableRow(
                  'Glycémie',
                  beforeData['glycemia']?.toDouble() ?? 0,
                  afterData['glycemia']?.toDouble() ?? 0,
                  'mg/dL',
                  '70-126',
                ),
                _tableRow(
                  'Poids',
                  beforeData['weight']?.toDouble() ?? 0,
                  afterData['weight']?.toDouble() ?? 0,
                  'kg',
                  'Selon IMC',
                ),
                _tableRow(
                  'Fréquence cardiaque',
                  beforeData['heart_rate']?.toDouble() ?? 0,
                  afterData['heart_rate']?.toDouble() ?? 0,
                  'bpm',
                  '60-100',
                ),
                _tableRow(
                  'Température',
                  beforeData['temperature']?.toDouble() ?? 0,
                  afterData['temperature']?.toDouble() ?? 0,
                  '°C',
                  '36-37.5',
                ),
                _tableRow(
                  'Saturation O₂',
                  beforeData['oxygen']?.toDouble() ?? 0,
                  afterData['oxygen']?.toDouble() ?? 0,
                  '%',
                  '95-100',
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Recommandations
            pw.Container(
              padding: pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '📋 Recommandations',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('• Consultez votre médecin régulièrement'),
                  pw.Text('• Suivez votre traitement prescrit'),
                  pw.Text('• Maintenez une alimentation équilibrée'),
                  pw.Text('• Pratiquez une activité physique régulière'),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Pied de page
            pw.Align(
              alignment: pw.Alignment.bottomCenter,
              child: pw.Text(
                'HealWise - Application de suivi médical\nGénéré le ${DateTime.now().toString().substring(0, 19)}',
                style: pw.TextStyle(color: PdfColors.grey500, fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _headerCell(String text) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      alignment: pw.Alignment.center,
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.TableRow _tableRow(
    String label,
    double before,
    double after,
    String unit,
    String normal,
  ) {
    final isNormal = _isValueNormal(label, after);
    final statusIcon = isNormal ? '✓' : '⚠️';
    final color = isNormal ? PdfColors.green : PdfColors.red;

    return pw.TableRow(
      children: [
        _dataCell(label),
        _dataCell(
          '${before.toStringAsFixed(1)} $unit',
          textAlign: pw.TextAlign.center,
        ),
        _dataCell(
          '${after.toStringAsFixed(1)} $unit',
          textAlign: pw.TextAlign.center,
          color: color,
        ),
        _dataCell(normal, textAlign: pw.TextAlign.center),
        _dataCell(statusIcon, textAlign: pw.TextAlign.center, color: color),
      ],
    );
  }

  static pw.Widget _dataCell(
    String text, {
    pw.TextAlign textAlign = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(6),
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(color: color),
        textAlign: textAlign,
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value, {PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(value, style: pw.TextStyle(color: color)),
      ],
    );
  }

  static bool _isValueNormal(String label, double value) {
    switch (label) {
      case 'Pression systolique':
        return value >= 90 && value <= 140;
      case 'Pression diastolique':
        return value >= 60 && value <= 90;
      case 'Glycémie':
        return value >= 70 && value <= 126;
      case 'Fréquence cardiaque':
        return value >= 60 && value <= 100;
      case 'Température':
        return value >= 36 && value <= 37.5;
      case 'Saturation O₂':
        return value >= 95 && value <= 100;
      default:
        return true;
    }
  }

  static Future<File?> _savePDF(pw.Document pdf, String fileName) async {
    try {
      Directory? downloadDir;

      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory();
        }
      } else {
        downloadDir = await getDownloadsDirectory();
      }

      if (downloadDir == null) {
        final tempDir = await getTemporaryDirectory();
        downloadDir = tempDir;
      }

      final file = File('${downloadDir.path}/$fileName');
      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);

      print('PDF sauvegardé: ${file.path}');
      return file;
    } catch (e) {
      print('Erreur sauvegarde: $e');
      return null;
    }
  }

  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isDenied) {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
      return true;
    }
    return true;
  }
}
