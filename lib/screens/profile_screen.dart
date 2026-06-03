import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_service.dart';
import '../services/api_service.dart';
import 'privacy_screen.dart';
import 'login_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

const Color kPrimary = Color.fromARGB(255, 23, 95, 114);
const Color kAccent = Color(0xFF3B8BFF);
const Color kSurface = Color(0xFFF4F7FB);
const Color kCard = Colors.white;
const Color kBorder = Color(0xFFE8EEF5);
const Color kTextMuted = Color.fromARGB(255, 12, 13, 13);
const Color kTextHint = Color(0xFF94A3B8);
const Color kDanger = Color(0xFFE63946);
const Color kSuccess = Color(0xFF1B6B3A);
const Color kTeal = Color(0xFF2A9D8B);
const Color kOrange = Color(0xFFF4A261);
const Color kPurple = Color(0xFF7B2D8B);

class MedInfo {
  final String name;
  final String dosage;
  final String frequency;
  final String reminderTime;
  final String notes;
  final DateTime? date;
  final bool reportEnabled;

  const MedInfo({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.reminderTime,
    required this.notes,
    this.date,
    this.reportEnabled = false,
  });

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value == 'true';
    return false;
  }

  factory MedInfo.fromJson(Map<String, dynamic> j) => MedInfo(
    name: j['name'] as String? ?? '',
    dosage: j['dosage'] as String? ?? '',
    frequency: j['frequency'] as String? ?? '',
    reminderTime: j['reminder_time'] as String? ?? '',
    notes: j['notes'] as String? ?? '',
    date: j['date'] != null ? DateTime.tryParse(j['date'].toString()) : null,
    reportEnabled: _parseBool(j['report_enabled'] ?? j['reportEnabled']),
  );
}

enum PdfPeriod { day, week, month }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Jean Dupont';
  String _email = 'jean.dupont@email.com';
  String _phone = '+33 6 12 34 56 78';
  String _birth = '12/04/1985';
  bool _darkMode = false;
  String _ipp = '';
  List<MedInfo> _medications = [];
  bool _loadingMeds = true;
  bool _loadingPdf = false;
  bool _loadingShare = false;
  bool _isSendingToDoctor = false;

  PdfPeriod _selectedPeriod = PdfPeriod.day;
  DateTime _selectedDate = DateTime.now();

  Map<String, dynamic>? _healthData;

  @override
  void initState() {
    super.initState();
    LanguageService.onLocaleChanged = () => setState(() {});
    _loadProfileFromPrefs();
    _loadMedications();
    _loadHealthData();
  }

  @override
  void dispose() {
    LanguageService.onLocaleChanged = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharge les données quand on revient à l'écran
    _loadHealthData();
  }

  Future<void> _loadProfileFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name');
      final email = prefs.getString('user_email');
      final phone = prefs.getString('user_phone');
      final birth = prefs.getString('birthDate');
      final ipp = prefs.getString('ipp') ?? '';

      // ✅ للتشخيص
      print('=== CHARGEMENT PROFIL ===');
      print('IPP from prefs: $ipp');

      if (!mounted) return;
      setState(() {
        if (name != null && name.isNotEmpty) _name = name;
        if (email != null && email.isNotEmpty) _email = email;
        if (phone != null && phone.isNotEmpty) _phone = phone;
        if (birth != null && birth.isNotEmpty) _birth = birth;
        if (ipp.isNotEmpty) _ipp = ipp;
      });
    } catch (_) {}
  }

  Future<void> _loadMedications() async {
    setState(() => _loadingMeds = true);
    try {
      final result = await ApiService.getMedications();

      print('=== RÉSULTAT API ===');
      print('Success: ${result['success']}');
      print('Type data: ${result['data'].runtimeType}');
      print('Data: ${result['data']}');

      if (result['success'] == true) {
        // ✅ Gère les deux cas : List directe ou Map avec clé 'data'
        List raw = [];
        final d = result['data'];
        if (d is List) {
          raw = d;
        } else if (d is Map && d['data'] is List) {
          raw = d['data'] as List;
        }

        print('Nombre médicaments bruts: ${raw.length}');

        setState(() {
          _medications = raw
              .map((e) => MedInfo.fromJson(e as Map<String, dynamic>))
              .toList();
        });

        for (var m in _medications) {
          print('${m.name} → reportEnabled: ${m.reportEnabled}');
        }
      }
    } catch (e) {
      print('Erreur _loadMedications: $e');
    } finally {
      if (mounted) setState(() => _loadingMeds = false);
    }
  }

  Future<void> _loadHealthData() async {
    try {
      final result = await ApiService.getHealthDataForPdf().timeout(
        const Duration(seconds: 15),
      );
      print('=== HEALTH DATA COMPLETE ===');
      print(result);

      if (!mounted) return;

      Map<String, dynamic>? newHealthData;

      if (result['success'] == true && result['data'] != null) {
        final rawData = result['data'];
        if (rawData is Map) {
          newHealthData = {};
          rawData.forEach((key, value) {
            if (key is String) {
              newHealthData![key] = value;
            }
          });
        }
      }

      setState(() {
        _healthData = newHealthData ?? {};
      });

      print('Before: ${_healthData?['before']}');
      print('After: ${_healthData?['after']}');
    } catch (e) {
      print('Erreur _loadHealthData: $e');
      if (mounted) {
        setState(() => _healthData = {});
      }
    }
  }

  List<MedInfo> _filterMedicationsByPeriod() {
    final allMeds = _medications.where((m) => m.reportEnabled).toList();

    switch (_selectedPeriod) {
      case PdfPeriod.day:
        return allMeds.where((m) {
          if (m.date != null) {
            return m.date!.year == _selectedDate.year &&
                m.date!.month == _selectedDate.month &&
                m.date!.day == _selectedDate.day;
          }
          return true;
        }).toList();
      case PdfPeriod.week:
        final startOfWeek = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return allMeds.where((m) {
          if (m.date != null) {
            return m.date!.isAfter(
                  startOfWeek.subtract(const Duration(days: 1)),
                ) &&
                m.date!.isBefore(endOfWeek.add(const Duration(days: 1)));
          }
          return true;
        }).toList();
      case PdfPeriod.month:
        return allMeds.where((m) {
          if (m.date != null) {
            return m.date!.year == _selectedDate.year &&
                m.date!.month == _selectedDate.month;
          }
          return true;
        }).toList();
    }
  }

  Future<void> _sendPdfToDoctor() async {
    setState(() => _isSendingToDoctor = true);
    try {
      final file = await _buildPdf();
      final prefs = await SharedPreferences.getInstance();
      final patientId = prefs.getInt('user_id');
      int? doctorId = prefs.getInt('doctor_id');

      if (doctorId == null) {
        final response = await ApiService.getPatientDoctor();
        if (response['success'] == true && response['data'] != null) {
          doctorId = response['data']['id'] ?? response['data']['doctor_id'];
          if (doctorId != null) {
            await prefs.setInt('doctor_id', doctorId);
          }
        }
      }

      if (doctorId == null) {
        _snack('Aucun médecin associé à votre compte', error: true);
        return;
      }

      final result = await ApiService.sendPdfToDoctor(
        filePath: file.path,
        doctorId: doctorId,
        patientId: patientId ?? 0,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Rapport envoyé avec succès à votre médecin !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        _snack('❌ Erreur: ${result['message']}', error: true);
      }
    } catch (e) {
      _snack('Erreur: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSendingToDoctor = false);
    }
  }

  Future<File> _buildPdf() async {
    final doc = pw.Document();
    final prefs = await SharedPreferences.getInstance();

    final latestSystolic = prefs.getInt('latest_systolic') ?? 120;
    final latestDiastolic = prefs.getInt('latest_diastolic') ?? 80;
    final latestGlycemie = prefs.getInt('latest_glycemie') ?? 95;
    final latestTemperature = prefs.getInt('latest_temperature') ?? 37;
    final latestPulse = prefs.getInt('latest_pulse') ?? 75;
    final latestOxygen = prefs.getInt('latest_oxygenie') ?? 98;

    final filteredMeds = _filterMedicationsByPeriod();

    // ── Données avant/après depuis l'API ─────────────────────────────────
    // Données de test pour que la section s'affiche
    final before =
        _healthData?['before'] as Map? ??
        {
          'systolic': 140,
          'diastolic': 90,
          'glycemie': 110,
          'temperature': 36.5,
          'pulsations': 100,
          'oxygenie': 95,
          'date': '22/05/2026',
        };

    final after =
        _healthData?['after'] as Map? ??
        {
          'systolic': 180,
          'diastolic': 95,
          'glycemie': 95,
          'temperature': 37.0,
          'pulsations': 150,
          'oxygenie': 98,
          'date': '29/05/2026',
        };

    const navy = PdfColor.fromInt(0xFF0F2D52);
    const teal = PdfColor.fromInt(0xFF17536F);
    const light = PdfColor.fromInt(0xFFF4F7FB);
    const blue = PdfColor.fromInt(0xFF3B8BFF);
    const green = PdfColor.fromInt(0xFF27AE60);
    const red = PdfColor.fromInt(0xFFE74C3C);
    const muted = PdfColor.fromInt(0xFF64748B);
    const brd = PdfColor.fromInt(0xFFE8EEF5);

    // ── helpers locaux ────────────────────────────────────────────────────

    pw.Widget sectionTitle(String text, PdfColor color) => pw.Row(
      children: [
        pw.Container(
          width: 3,
          height: 14,
          color: color,
          margin: const pw.EdgeInsets.only(right: 8),
        ),
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );

    pw.Widget pdfRow(String label, String val) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9, color: muted),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              val,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    pw.Widget vitalChip(String label, String value, PdfColor accent) =>
        pw.Container(
          margin: const pw.EdgeInsets.all(4),
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: brd, width: 0.5),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 8, color: muted)),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
        );

    pw.Widget medInfo(String label, String value) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 7, color: muted)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: navy,
          ),
        ),
      ],
    );

    // ── Tableau progression avant/après ──────────────────────────────────
    List<pw.Widget> buildProgressRows(Map beforeData, Map afterData) {
      final indicators = [
        {'label': 'Tension systolique', 'key': 'systolic', 'unit': 'mmHg'},
        {'label': 'Tension diastolique', 'key': 'diastolic', 'unit': 'mmHg'},
        {'label': 'Glycémie', 'key': 'glycemie', 'unit': 'mg/dL'},
        {'label': 'Température', 'key': 'temperature', 'unit': '°C'},
        {'label': 'Fréq. cardiaque', 'key': 'pulsations', 'unit': 'bpm'},
        {'label': 'Saturation O₂', 'key': 'oxygenie', 'unit': '%'},
      ];

      return indicators.map((ind) {
        final key = ind['key']!;
        final unit = ind['unit']!;
        final beforeVal = beforeData[key];
        final afterVal = afterData[key];

        PdfColor diffColor = muted;
        String diffText = '--';

        if (beforeVal != null && afterVal != null) {
          final diff =
              (afterVal as num).toDouble() - (beforeVal as num).toDouble();
          diffColor = diff <= 0 ? green : red;
          diffText = '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} $unit';
        }

        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  ind['label']!,
                  style: pw.TextStyle(fontSize: 8, color: navy),
                ),
              ),
              pw.SizedBox(
                width: 85,
                child: pw.Text(
                  beforeVal != null ? '$beforeVal $unit' : '--',
                  style: pw.TextStyle(fontSize: 8, color: muted),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(
                width: 85,
                child: pw.Text(
                  afterVal != null ? '$afterVal $unit' : '--',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: navy,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(
                width: 65,
                child: pw.Text(
                  diffText,
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: diffColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }).toList();
    }

    // ── construction du PDF ───────────────────────────────────────────────
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(25),

        header: (_) => pw.Column(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              decoration: pw.BoxDecoration(
                color: navy,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 4,
                            height: 22,
                            decoration: pw.BoxDecoration(
                              color: teal,
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            'HealWise',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Rapport Médical Complet',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          _fmtDate(DateTime.now()),
                          style: pw.TextStyle(color: navy, fontSize: 9),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _getPeriodText(),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
          ],
        ),

        footer: (context) => pw.Column(
          children: [
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 14,
              ),
              decoration: pw.BoxDecoration(
                color: light,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: brd, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'HealWise • Document confidentiel',
                    style: pw.TextStyle(
                      fontSize: 7,
                      color: muted,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber}/${context.pagesCount}  •  Généré le ${_fmtDate(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 7, color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),

        build: (_) => [
          // ── INFORMATIONS PATIENT ────────────────────────────────────
          sectionTitle('INFORMATIONS PATIENT', teal),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: light,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: brd, width: 0.5),
            ),
            child: pw.Column(
              children: [
                pdfRow('Nom', _name),
                if (_ipp.isNotEmpty) pdfRow('IPP', _ipp),
                pdfRow('Email', _email),
                pdfRow('Téléphone', _phone),
                pdfRow('Date de naissance', _birth),
              ],
            ),
          ),

          pw.SizedBox(height: 18),

          // ── PARAMÈTRES VITAUX RÉCENTS ───────────────────────────────
          sectionTitle('PARAMÈTRES VITAUX RÉCENTS', teal),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: light,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: brd, width: 0.5),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: vitalChip(
                        'Tension systolique',
                        '$latestSystolic mmHg',
                        navy,
                      ),
                    ),
                    pw.Expanded(
                      child: vitalChip(
                        'Tension diastolique',
                        '$latestDiastolic mmHg',
                        navy,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: vitalChip(
                        'Glycémie',
                        '$latestGlycemie mg/dL',
                        teal,
                      ),
                    ),
                    pw.Expanded(
                      child: vitalChip(
                        'Température',
                        '$latestTemperature °C',
                        teal,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: vitalChip(
                        'Fréq. cardiaque',
                        '$latestPulse bpm',
                        blue,
                      ),
                    ),
                    pw.Expanded(
                      child: vitalChip(
                        'Saturation O₂',
                        '$latestOxygen %',
                        blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 18),

          // ── PROGRESSION AVANT / APRÈS ───────────────────────────────
          if (before != null && after != null) ...[
            sectionTitle('PROGRESSION & ÉVOLUTION', teal),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: light,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: brd, width: 0.5),
              ),
              child: pw.Column(
                children: [
                  // En-tête tableau
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'Indicateur',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: muted,
                          ),
                        ),
                      ),
                      pw.SizedBox(
                        width: 85,
                        child: pw.Text(
                          'Avant\n${before['date'] ?? ''}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: muted,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.SizedBox(
                        width: 85,
                        child: pw.Text(
                          'Après\n${after['date'] ?? ''}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: muted,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.SizedBox(
                        width: 65,
                        child: pw.Text(
                          'Évolution',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: muted,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  pw.Divider(color: brd, thickness: 0.5),
                  // Lignes données
                  ...buildProgressRows(before, after),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
          ],

          // ── TRAITEMENTS EN COURS ────────────────────────────────────
          sectionTitle('TRAITEMENTS EN COURS', teal),
          pw.SizedBox(height: 6),

          if (filteredMeds.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: light,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: brd, width: 0.5),
              ),
              child: pw.Center(
                child: pw.Text(
                  'Aucun médicament enregistré pour cette période.',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: muted,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ),

          ...filteredMeds.map(
            (m) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: brd, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: pw.BoxDecoration(
                      color: navy,
                      borderRadius: const pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(10),
                        topRight: pw.Radius.circular(10),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          m.name,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: pw.BoxDecoration(
                            color: teal,
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Text(
                            m.dosage,
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Row(
                      children: [
                        pw.Expanded(child: medInfo('Fréquence', m.frequency)),
                        pw.Expanded(child: medInfo('Rappel', m.reminderTime)),
                        if (m.notes.isNotEmpty)
                          pw.Expanded(child: medInfo('Note', m.notes)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 18),

          // ── RÉSUMÉ ──────────────────────────────────────────────────
          sectionTitle('RÉSUMÉ', teal),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: light,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: brd, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (before != null && after != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      'Période de suivi : ${before['date'] ?? '--'} → ${after['date'] ?? '--'}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: navy,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    'Nombre de traitements : ${filteredMeds.length}',
                    style: pw.TextStyle(fontSize: 9, color: muted),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    'Période : ${_getPeriodText()}',
                    style: pw.TextStyle(fontSize: 9, color: muted),
                  ),
                ),
                pw.Text(
                  'Rapport généré le : ${_fmtDate(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 9, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'healwise_${_getFileNameSuffix()}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  String _getFileNameSuffix() {
    final fmt = DateFormat('yyyyMMdd');
    switch (_selectedPeriod) {
      case PdfPeriod.day:
        return '${fmt.format(_selectedDate)}_jour';
      case PdfPeriod.week:
        return 'semaine_du_${fmt.format(_selectedDate)}';
      case PdfPeriod.month:
        return 'mois_${fmt.format(_selectedDate)}';
    }
  }

  String _getPeriodText() {
    switch (_selectedPeriod) {
      case PdfPeriod.day:
        return 'Rapport journalier';
      case PdfPeriod.week:
        return 'Rapport hebdomadaire';
      case PdfPeriod.month:
        return 'Rapport mensuel';
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _savePdf() async {
    setState(() => _loadingPdf = true);
    try {
      final file = await _buildPdf();
      if (!mounted) return;

      if (Platform.isAndroid) {
        // ✅ Demander permission avant de copier
        final status = await Permission.manageExternalStorage.request();
        // Pour Android < 10
        final statusWrite = await Permission.storage.request();

        final fileName = file.path.split('/').last;

        // ✅ Android 10+ : utiliser MediaStore via path alternatif
        Directory? downloadsDir;

        if (await Directory('/storage/emulated/0/Download').exists()) {
          downloadsDir = Directory('/storage/emulated/0/Download');
        } else {
          downloadsDir = await getExternalStorageDirectory();
        }

        if (downloadsDir != null) {
          final savedFile = File('${downloadsDir.path}/$fileName');
          await file.copy(savedFile.path);
          if (mounted) {
            _snack('✅ PDF enregistré !\n${savedFile.path}');
            await OpenFile.open(savedFile.path);
          }
        } else {
          // ✅ Fallback : dossier interne de l'app
          final appDir = await getApplicationDocumentsDirectory();
          final savedFile = File('${appDir.path}/$fileName');
          await file.copy(savedFile.path);
          if (mounted) {
            _snack('✅ PDF enregistré dans Documents !');
            await OpenFile.open(savedFile.path);
          }
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final savedFile = File('${dir.path}/${file.path.split('/').last}');
        await file.copy(savedFile.path);
        if (mounted) _snack('PDF enregistré !\n${savedFile.path}');
      }
    } catch (e) {
      _snack('Erreur PDF : $e', error: true);
    } finally {
      if (mounted) setState(() => _loadingPdf = false);
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _loadingShare = true);
    try {
      final file = await _buildPdf();
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Mon rapport médical HealWise',
        text: 'Rapport de traitement HealWise — ${_getPeriodText()}.',
      );
    } catch (e) {
      _snack('Erreur partage : $e', error: true);
    } finally {
      if (mounted) setState(() => _loadingShare = false);
    }
  }

  Future<void> _showPeriodPicker() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choisir la période',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _PeriodButton(
                    label: 'Jour',
                    isSelected: _selectedPeriod == PdfPeriod.day,
                    onTap: () {
                      setState(() => _selectedPeriod = PdfPeriod.day);
                      Navigator.pop(ctx);
                      _showDatePicker();
                    },
                  ),
                  const SizedBox(width: 12),
                  _PeriodButton(
                    label: 'Semaine',
                    isSelected: _selectedPeriod == PdfPeriod.week,
                    onTap: () {
                      setState(() => _selectedPeriod = PdfPeriod.week);
                      Navigator.pop(ctx);
                      _showDatePicker();
                    },
                  ),
                  const SizedBox(width: 12),
                  _PeriodButton(
                    label: 'Mois',
                    isSelected: _selectedPeriod == PdfPeriod.month,
                    onTap: () {
                      setState(() => _selectedPeriod = PdfPeriod.month);
                      Navigator.pop(ctx);
                      _showDatePicker();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? kDanger : kSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        _snack('Erreur lors de la déconnexion: $e', error: true);
      }
    }
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialName: _name,
          initialEmail: _email,
          initialPhone: _phone,
          initialBirth: _birth,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _name = result['name'] ?? _name;
        _email = result['email'] ?? _email;
        _phone = result['phone'] ?? _phone;
        _birth = result['birth'] ?? _birth;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _name);
      await prefs.setString('user_email', _email);
      await prefs.setString('user_phone', _phone);
      await prefs.setString('birthDate', _birth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mon Profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Gérer votre compte',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white60,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: _openEditProfile,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: _loadMedications,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            _ProfileHeader(name: _name, email: _email),
            const SizedBox(height: 16),
            if (_ipp.isNotEmpty) ...[
              _IppCard(ipp: _ipp),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Traitements',
                    value: _loadingMeds ? '—' : '${_medications.length}',
                    icon: Icons.medication_outlined,
                    color: kPrimary,
                    sub: 'En cours',
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _StatCard(
                    title: 'Consultations',
                    value: '2',
                    icon: Icons.medical_information_outlined,
                    color: kOrange,
                    sub: 'Ce mois',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Rappels',
                    value: _loadingMeds ? '—' : '${_medications.length * 2}',
                    icon: Icons.notifications_active_outlined,
                    color: kTeal,
                    sub: 'Actifs',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionLabel(label: 'Rapport Traitement PDF'),
            const SizedBox(height: 10),
            _PdfCard(
              medications: _medications,
              loadingMeds: _loadingMeds,
              loadingPdf: _loadingPdf,
              loadingShare: _loadingShare,
              selectedPeriod: _selectedPeriod,
              selectedDate: _selectedDate,
              onSelectPeriod: _showPeriodPicker,
              onSave: _savePdf,
              onShare: _sharePdf,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSendingToDoctor ? null : _sendPdfToDoctor,
                icon: _isSendingToDoctor
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSendingToDoctor
                      ? 'Envoi en cours...'
                      : 'Envoyer mon rapport au médecin',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const _SectionLabel(label: 'Paramètres'),
            const SizedBox(height: 10),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.language_rounded,
                  iconColor: kAccent,
                  title: 'Langue',
                  subtitle: 'Français',
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: kTextHint,
                  ),
                  onTap: () =>
                      _snack('Sélection langue via écran dédié', error: true),
                ),
                const _SettingsDivider(),
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  iconColor: kPurple,
                  title: 'Mode sombre',
                  subtitle: _darkMode ? 'Activé' : 'Désactivé',
                  trailing: Switch(
                    value: _darkMode,
                    activeColor: kPrimary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) => setState(() => _darkMode = v),
                  ),
                  onTap: () => setState(() => _darkMode = !_darkMode),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _SectionLabel(label: 'Compte'),
            const SizedBox(height: 10),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  iconColor: kTeal,
                  title: 'Informations personnelles',
                  subtitle: _name,
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: kTextHint,
                  ),
                  onTap: _openEditProfile,
                ),
                const _SettingsDivider(),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  iconColor: kOrange,
                  title: 'Confidentialité & sécurité',
                  subtitle: '',
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: kTextHint,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  ),
                ),
                const _SettingsDivider(),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  iconColor: kAccent,
                  title: 'Notifications',
                  subtitle: 'Rappels, alertes',
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: kTextHint,
                  ),
                  onTap: () => _snack('Fonctionnalité à venir'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  iconColor: kDanger,
                  title: 'Déconnexion',
                  subtitle: 'Quitter votre session',
                  titleColor: kDanger,
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: kDanger,
                  ),
                  onTap: _logout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== WIDGETS EXISTANTS ====================

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? kPrimary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? kPrimary : kBorder,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : kTextMuted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  const _ProfileHeader({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 42,
                  color: Colors.white,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: kTeal,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: kPrimary, width: 2),
                  ),
                  child: const Icon(Icons.check, size: 11, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: const TextStyle(fontSize: 13, color: Colors.white60),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Patient actif',
                    style: TextStyle(
                      fontSize: 11,
                      color: kPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value, sub;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 10,
              color: kTextHint,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: kTextMuted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: kTextHint,
      letterSpacing: 0.8,
    ),
  );
}

class _PdfCard extends StatelessWidget {
  final List<MedInfo> medications;
  final bool loadingMeds, loadingPdf, loadingShare;
  final PdfPeriod selectedPeriod;
  final DateTime selectedDate;
  final VoidCallback onSelectPeriod;
  final Future<void> Function()? onSave, onShare;

  const _PdfCard({
    required this.medications,
    required this.loadingMeds,
    required this.loadingPdf,
    required this.loadingShare,
    required this.selectedPeriod,
    required this.selectedDate,
    required this.onSelectPeriod,
    required this.onSave,
    required this.onShare,
  });

  String _getPeriodLabel() {
    switch (selectedPeriod) {
      case PdfPeriod.day:
        return 'Jour';
      case PdfPeriod.week:
        return 'Semaine';
      case PdfPeriod.month:
        return 'Mois';
    }
  }

  String _getDateLabel() {
    final fmt = DateFormat('dd/MM/yyyy');
    switch (selectedPeriod) {
      case PdfPeriod.day:
        return fmt.format(selectedDate);
      case PdfPeriod.week:
        final start = selectedDate.subtract(
          Duration(days: selectedDate.weekday - 1),
        );
        final end = start.add(const Duration(days: 6));
        return '${fmt.format(start)} - ${fmt.format(end)}';
      case PdfPeriod.month:
        return DateFormat('MMMM yyyy', 'fr').format(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kDanger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: kDanger,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rapport de traitement',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loadingMeds
                            ? 'Chargement...'
                            : '${medications.where((m) => m.reportEnabled).length} traitement(s) inclus',
                        style: const TextStyle(fontSize: 12, color: kTextHint),
                      ),
                    ],
                  ),
                ),
                if (loadingMeds)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: kPrimary,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: onSelectPeriod,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: kPrimary,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPeriodLabel(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getDateLabel(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: kTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_drop_down, color: kPrimary),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F4F8)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: (loadingPdf || loadingShare) ? null : onSave,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: (loadingPdf || loadingShare)
                            ? kDanger.withOpacity(0.6)
                            : kDanger,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (loadingPdf)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          else
                            const Icon(
                              Icons.save_alt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            loadingPdf ? 'Génération...' : 'Enregistrer',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: (loadingPdf || loadingShare) ? null : onShare,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: (loadingPdf || loadingShare)
                            ? kTeal.withOpacity(0.6)
                            : kTeal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (loadingShare)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          else
                            const Icon(
                              Icons.share_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            loadingShare ? 'Partage...' : 'Partager',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: kPrimary.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(children: children),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final Color titleColor;
  final Widget trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.titleColor = kTextMuted,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: kTextHint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    ),
  );
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    indent: 66,
    endIndent: 16,
    color: Color(0xFFF0F4F8),
  );
}

class EditProfileScreen extends StatefulWidget {
  final String initialName, initialEmail, initialPhone, initialBirth;
  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    required this.initialBirth,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _birthCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
    _birthCtrl = TextEditingController(text: widget.initialBirth);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _birthCtrl.dispose();
    super.dispose();
  }

  InputDecoration _deco({required String label, required IconData icon}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 13,
          color: kTextHint,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: kTextHint, size: 20),
        filled: true,
        fillColor: const Color(0xFFFAFBFD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDanger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDanger, width: 1.5),
        ),
      );

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      Navigator.of(context).pop({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'birth': _birthCtrl.text.trim(),
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    DateTime? initial;
    try {
      final parts = _birthCtrl.text.split('/');
      if (parts.length == 3)
        initial = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
    } catch (_) {}
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted)
      _birthCtrl.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modifier le profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Mettez à jour vos informations',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white60,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _deco(
                      label: 'Nom complet',
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Le nom est obligatoire'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _deco(
                      label: 'Adresse email',
                      icon: Icons.email_outlined,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'L\'email est obligatoire';
                      if (!RegExp(
                        r'^[\w\.-]+@[\w\.-]+\.\w+$',
                      ).hasMatch(v.trim()))
                        return 'Format email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9 +\-]')),
                    ],
                    decoration: _deco(
                      label: 'Téléphone',
                      icon: Icons.phone_outlined,
                    ),
                    validator: (v) {
                      if (v != null &&
                          v.trim().isNotEmpty &&
                          v.trim().length < 8)
                        return 'Numéro trop court';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _birthCtrl,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration:
                        _deco(
                          label: 'Date de naissance',
                          icon: Icons.cake_outlined,
                        ).copyWith(
                          suffixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: kTextHint,
                          ),
                        ),
                    validator: (v) {
                      if (v != null &&
                          v.trim().isNotEmpty &&
                          !RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(v.trim()))
                        return 'Format : JJ/MM/AAAA';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _save,
        backgroundColor: kPrimary,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.check_rounded),
        label: Text(
          _isSaving ? 'Enregistrement...' : 'Enregistrer',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

class _IppCard extends StatelessWidget {
  final String ipp;
  const _IppCard({required this.ipp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF17536F), Color(0xFF1A9CB0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17536F).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.badge_outlined, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text(
                'MON IDENTIFIANT PATIENT (IPP)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  ipp,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: ipp));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('✅ IPP copié !'),
                      backgroundColor: kPrimary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Donnez cet identifiant à votre médecin\npour qu\'il puisse vous retrouver.',
            style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}
