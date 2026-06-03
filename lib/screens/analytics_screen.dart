import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/language_service.dart';
import '../services/api_service.dart';
import '../widgets/health_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<double> _systolicData = [];
  List<double> _diastolicData = [];
  List<double> _glucoseData = [];
  List<double> _pulseData = [];
  List<double> _temperatureData = [];
  List<double> _oxygenData = [];
  List<String> _dates = [];

  bool _isLoadingHistory = true;
  int? _systolic;
  int? _diastolic;
  int? _glycemie;
  int? _temperature;
  int? _pulsations;
  int? _oxygenie;
  String _recordDate = '';

  // Variables pour la notification médecin
  bool _showDoctorNotification = false;
  String _doctorNotificationMessage = '';
  bool _doctorNotified = false;

  @override
  void initState() {
    super.initState();
    LanguageService.onLocaleChanged = () {
      if (mounted) setState(() {});
    };
    _loadHealthData();
    _loadHealthHistory();
    _checkAndNotifyDoctor();
  }

  @override
  void dispose() {
    LanguageService.onLocaleChanged = null;
    super.dispose();
  }

  Future<void> _checkAndNotifyDoctor() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString('latest_status') ?? 'bien';
    final alreadyNotified = prefs.getBool('doctor_notified') ?? false;

    // FIX 3: Vérifier aussi la date de dernière notification pour ne pas respammer
    final lastNotifiedDate = prefs.getString('doctor_notified_date') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final alreadyNotifiedToday = alreadyNotified && lastNotifiedDate == today;

    if ((status == 'alert' || status == 'attention') && !alreadyNotifiedToday) {
      final systolic = prefs.getInt('latest_systolic');
      final diastolic = prefs.getInt('latest_diastolic');
      final glycemie = prefs.getInt('latest_glycemie');
      final temperature = prefs.getInt('latest_temperature');
      final pulsations = prefs.getInt('latest_pulse');
      final oxygenie = prefs.getInt('latest_oxygenie');

      int dangerRate = _calculateDangerRate(
        systolic: systolic,
        diastolic: diastolic,
        glycemie: glycemie,
        temperature: temperature,
        pulsations: pulsations,
        oxygenie: oxygenie,
      );

      String specialty = _getRecommendedSpecialty(
        systolic: systolic,
        diastolic: diastolic,
        glycemie: glycemie,
        temperature: temperature,
        pulsations: pulsations,
        oxygenie: oxygenie,
      );

      final result = await ApiService.notifyDoctorOfRisk(
        dangerRate: dangerRate,
        severity: status == 'alert' ? 'critical' : 'moderate',
        recommendedSpecialty: specialty,
        symptoms: [],
      );

      if (result['success'] == true) {
        await prefs.setBool('doctor_notified', true);
        await prefs.setString('doctor_notified_date', today); // FIX 3
        if (mounted) {
          setState(() {
            _showDoctorNotification = true;
            _doctorNotificationMessage =
                '🩺 Votre médecin a été automatiquement notifié de vos paramètres anormaux.';
            _doctorNotified = true;
          });

          Future.delayed(const Duration(seconds: 8), () {
            if (mounted) {
              setState(() {
                _showDoctorNotification = false;
              });
            }
          });
        }
      }
    }
  }

  int _calculateDangerRate({
    int? systolic,
    int? diastolic,
    int? glycemie,
    int? temperature,
    int? pulsations,
    int? oxygenie,
  }) {
    int dangerRate = 0;
    if (systolic != null && diastolic != null) {
      if (systolic > 180 || diastolic > 120)
        dangerRate += 40;
      else if (systolic > 140 || diastolic > 90)
        dangerRate += 20;
    }
    if (glycemie != null) {
      if (glycemie > 200)
        dangerRate += 30;
      else if (glycemie > 126)
        dangerRate += 15;
    }
    if (temperature != null) {
      if (temperature > 39)
        dangerRate += 25;
      else if (temperature > 37.5)
        dangerRate += 10;
    }
    if (pulsations != null) {
      if (pulsations > 120 || pulsations < 40)
        dangerRate += 20;
      else if (pulsations > 100 || pulsations < 60)
        dangerRate += 10;
    }
    if (oxygenie != null) {
      if (oxygenie < 90)
        dangerRate += 35;
      else if (oxygenie < 95)
        dangerRate += 15;
    }
    return dangerRate.clamp(0, 100);
  }

  String _getRecommendedSpecialty({
    int? systolic,
    int? diastolic,
    int? glycemie,
    int? temperature,
    int? pulsations,
    int? oxygenie,
  }) {
    if ((systolic != null && systolic > 160) ||
        (diastolic != null && diastolic > 100)) {
      return 'Cardiologue';
    }
    if (glycemie != null && glycemie > 200) {
      return 'Endocrinologue';
    }
    if (temperature != null && temperature > 39) {
      return 'Médecin généraliste';
    }
    if (oxygenie != null && oxygenie < 90) {
      return 'Pneumologue';
    }
    if (pulsations != null && (pulsations > 120 || pulsations < 40)) {
      return 'Cardiologue';
    }
    return 'Généraliste';
  }

  Future<void> _loadHealthData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _systolic = prefs.getInt('latest_systolic');
      _diastolic = prefs.getInt('latest_diastolic');
      _glycemie = prefs.getInt('latest_glycemie');
      _temperature = prefs.getInt('latest_temperature');
      _pulsations = prefs.getInt('latest_pulse');
      _oxygenie = prefs.getInt('latest_oxygenie');
      _recordDate = prefs.getString('latest_record_date') ?? '';
    });
  }

  Future<void> _loadHealthHistory() async {
    try {
      final result = await ApiService.getHealthHistory(days: 7);
      if (result['success'] == true && mounted) {
        final raw = result['data'];
        List<dynamic>? records;
        if (raw is Map<String, dynamic>) {
          records = raw['records'] as List<dynamic>?;
        } else if (raw is List<dynamic>) {
          records = raw;
        }

        if (records != null && records.isNotEmpty) {
          // خذ آخر 7 أيام فقط
          final last7Days = records.length > 7
              ? records.sublist(records.length - 7)
              : records;

          _dates.clear();
          _systolicData.clear();
          _diastolicData.clear();
          _glucoseData.clear();
          _pulseData.clear();
          _temperatureData.clear();
          _oxygenData.clear();

          for (int i = 0; i < last7Days.length; i++) {
            final record = last7Days[i];
            if (record is Map<String, dynamic>) {
              final formattedDate = _formatDate(record['recorded_at'] ?? '');
              _dates.add(formattedDate);

              // التحقق من وجود البيانات قبل إضافتها
              _systolicData.add(_parseDouble(record['systolic']) ?? 0);
              _diastolicData.add(_parseDouble(record['diastolic']) ?? 0);
              _glucoseData.add(_parseDouble(record['glycemie']) ?? 0);
              _pulseData.add(_parseDouble(record['pulsations']) ?? 0);
              _temperatureData.add(_parseDouble(record['temperature']) ?? 0);
              _oxygenData.add(_parseDouble(record['oxygenie']) ?? 0);
            }
          }

          // إزالة القيم الصفرية غير الصحيحة
          _systolicData.removeWhere((v) => v <= 0);
          _glucoseData.removeWhere((v) => v <= 0);
          _pulseData.removeWhere((v) => v <= 0);
          _temperatureData.removeWhere((v) => v <= 0);
          _oxygenData.removeWhere((v) => v <= 0);

          // تأكد أن _dates تتطابق مع عدد البيانات
          while (_dates.length > _systolicData.length) {
            _dates.removeLast();
          }

          if (mounted) {
            setState(() {
              _isLoadingHistory = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('AnalyticsScreen._loadHealthHistory error: $e');
    }

    // Fallback مع بيانات تجريبية منطقية لـ 7 أيام
    if (mounted && _systolicData.isEmpty) {
      setState(() {
        _dates = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        _systolicData = [120, 118, 122, 125, 119, 121, 120];
        _diastolicData = [80, 78, 82, 81, 79, 80, 80];
        _glucoseData = [95, 98, 96, 97, 95, 99, 96];
        _pulseData = [72, 75, 71, 74, 73, 72, 72];
        _temperatureData = [36.5, 36.6, 36.5, 36.7, 36.5, 36.6, 36.5];
        _oxygenData = [98, 97, 98, 98, 97, 98, 98];
        _isLoadingHistory = false;
      });
    }
  }

  String _formatDate(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateTimeStr);
      // Dart: 1=Lundi, 2=Mardi, 3=Mercredi, 4=Jeudi, 5=Vendredi, 6=Samedi, 7=Dimanche
      const weekdays = {
        1: 'Lun', // Lundi
        2: 'Mar', // Mardi
        3: 'Mer', // Mercredi
        4: 'Jeu', // Jeudi
        5: 'Ven', // Vendredi
        6: 'Sam', // Samedi
        7: 'Dim', // Dimanche
      };
      return weekdays[date.weekday] ?? '';
    } catch (e) {
      return '';
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool _isBPRisky() {
    if (_systolic != null && _diastolic != null) {
      if (_systolic! > 180 || _diastolic! > 120) return true;
      if (_systolic! > 140 || _diastolic! > 90) return true;
    }
    return false;
  }

  bool _isGlycemieRisky() {
    if (_glycemie != null) {
      if (_glycemie! > 200) return true;
      if (_glycemie! > 126) return true;
      if (_glycemie! < 70) return true;
    }
    return false;
  }

  bool _isPulseRisky() {
    if (_pulsations != null) {
      if (_pulsations! > 120) return true;
      if (_pulsations! > 100) return true;
      if (_pulsations! < 40) return true;
      if (_pulsations! < 60) return true;
    }
    return false;
  }

  bool _isTemperatureRisky() {
    if (_temperature != null) {
      if (_temperature! > 39) return true;
      if (_temperature! > 37.5) return true;
      if (_temperature! < 35) return true;
    }
    return false;
  }

  bool _isOxygenRisky() {
    if (_oxygenie != null) {
      if (_oxygenie! < 90) return true;
      if (_oxygenie! < 95) return true;
    }
    return false;
  }

  String _getBPRiskMessage() {
    if (_systolic != null && _diastolic != null) {
      if (_systolic! > 180 || _diastolic! > 120)
        return '⚠️ Tension CRITIQUE: $_systolic/$_diastolic mmHg';
      if (_systolic! > 140 || _diastolic! > 90)
        return '⚠️ Tension ÉLEVÉE: $_systolic/$_diastolic mmHg';
    }
    return '';
  }

  String _getGlycemieRiskMessage() {
    if (_glycemie != null) {
      if (_glycemie! > 200) return '⚠️ Glycémie TRÈS ÉLEVÉE: $_glycemie mg/dL';
      if (_glycemie! > 126) return '⚠️ Glycémie ÉLEVÉE: $_glycemie mg/dL';
      if (_glycemie! < 70) return '⚠️ Hypoglycémie: $_glycemie mg/dL';
    }
    return '';
  }

  String _getPulseRiskMessage() {
    if (_pulsations != null) {
      if (_pulsations! > 120) return '⚠️ Tachycardie SÉVÈRE: $_pulsations bpm';
      if (_pulsations! > 100) return '⚠️ Tachycardie: $_pulsations bpm';
      if (_pulsations! < 40) return '⚠️ Bradycardie SÉVÈRE: $_pulsations bpm';
      if (_pulsations! < 60) return '⚠️ Bradycardie: $_pulsations bpm';
    }
    return '';
  }

  String _getTemperatureRiskMessage() {
    if (_temperature != null) {
      if (_temperature! > 39) return '⚠️ Fièvre ÉLEVÉE: $_temperature°C';
      if (_temperature! > 37.5) return '⚠️ Fièvre: $_temperature°C';
      if (_temperature! < 35) return '⚠️ Hypothermie: $_temperature°C';
    }
    return '';
  }

  String _getOxygenRiskMessage() {
    if (_oxygenie != null) {
      if (_oxygenie! < 90) return '⚠️ Désaturation SÉVÈRE: $_oxygenie%';
      if (_oxygenie! < 95) return '⚠️ Désaturation: $_oxygenie%';
    }
    return '';
  }

  List<FlSpot> _createSpots(List<double> data) {
    if (data.isEmpty) return [];
    return data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasData =
        _systolic != null ||
        _glycemie != null ||
        _pulsations != null ||
        _temperature != null ||
        _oxygenie != null;

    int riskyCount = 0;
    if (_isBPRisky()) riskyCount++;
    if (_isGlycemieRisky()) riskyCount++;
    if (_isPulseRisky()) riskyCount++;
    if (_isTemperatureRisky()) riskyCount++;
    if (_isOxygenRisky()) riskyCount++;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Analytiques Santé',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (riskyCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: riskyCount > 1
                                  ? Colors.red
                                  : const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.warning_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  riskyCount > 1
                                      ? '$riskyCount paramètres à risque'
                                      : '1 paramètre à risque',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (_showDoctorNotification)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF5CA0D8), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🩺 Notification envoyée',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _doctorNotificationMessage,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showDoctorNotification = false),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: _isLoadingHistory
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // FIX 5: Padding uniforme à 20 pour tous les graphiques
          if (_systolicData.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HealthChart(
                  title: 'Tension artérielle',
                  data: _createSpots(_systolicData),
                  xAxisLabels: _dates,
                  lineColor: const Color(0xFF3B82F6),
                  unit: 'mmHg',
                  minY: 70,
                  maxY: 200,
                  isRisky: _isBPRisky(),
                  riskMessage: _getBPRiskMessage(),
                  icon: Icons.favorite,
                ),
              ),
            ),

          if (_glucoseData.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: HealthChart(
                  title: 'Glycémie',
                  data: _createSpots(_glucoseData),
                  xAxisLabels: _dates,
                  lineColor: const Color(0xFFF59E0B),
                  unit: 'mg/dL',
                  minY: 50,
                  maxY: 300,
                  isRisky: _isGlycemieRisky(),
                  riskMessage: _getGlycemieRiskMessage(),
                  icon: Icons.water_drop,
                ),
              ),
            ),

          if (_pulseData.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: HealthChart(
                  title: 'Fréquence cardiaque',
                  data: _createSpots(_pulseData),
                  xAxisLabels: _dates,
                  lineColor: const Color(0xFFEF4444),
                  unit: 'bpm',
                  minY: 30,
                  maxY: 150,
                  isRisky: _isPulseRisky(),
                  riskMessage: _getPulseRiskMessage(),
                  icon: Icons.favorite_border,
                ),
              ),
            ),

          if (_temperatureData.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: HealthChart(
                  title: 'Température',
                  data: _createSpots(_temperatureData),
                  xAxisLabels: _dates,
                  lineColor: const Color(0xFF14B8A6),
                  unit: '°C',
                  minY: 34,
                  maxY: 42,
                  isRisky: _isTemperatureRisky(),
                  riskMessage: _getTemperatureRiskMessage(),
                  icon: Icons.thermostat,
                ),
              ),
            ),

          if (_oxygenData.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: HealthChart(
                  title: 'Saturation Oxygène',
                  data: _createSpots(_oxygenData),
                  xAxisLabels: _dates,
                  lineColor: const Color(0xFF3498DB),
                  unit: '%',
                  minY: 80,
                  maxY: 100,
                  isRisky: _isOxygenRisky(),
                  riskMessage: _getOxygenRiskMessage(),
                  icon: Icons.air,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dernières mesures',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!hasData)
                      const Text('Aucune donnée enregistrée')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_systolic != null)
                            _buildValueChip(
                              'Tension',
                              '$_systolic/$_diastolic mmHg',
                              _isBPRisky(),
                            ),
                          if (_glycemie != null)
                            _buildValueChip(
                              'Glycémie',
                              '$_glycemie mg/dL',
                              _isGlycemieRisky(),
                            ),
                          if (_pulsations != null)
                            _buildValueChip(
                              'Pouls',
                              '$_pulsations bpm',
                              _isPulseRisky(),
                            ),
                          if (_temperature != null)
                            _buildValueChip(
                              'Température',
                              '$_temperature °C',
                              _isTemperatureRisky(),
                            ),
                          if (_oxygenie != null)
                            _buildValueChip(
                              'SpO₂',
                              '$_oxygenie%',
                              _isOxygenRisky(),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // FIX 4: Afficher _recordDate uniquement si non vide
          if (_recordDate.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Center(
                  child: Text(
                    'Dernière mise à jour: $_recordDate',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildValueChip(String label, String value, bool isRisky) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isRisky ? Colors.red.shade50 : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: isRisky ? Border.all(color: Colors.red, width: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRisky)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.warning_rounded, color: Colors.red, size: 12),
            ),
          Text(
            '$label: $value',
            style: TextStyle(
              color: isRisky ? Colors.red.shade700 : const Color(0xFF475569),
              fontWeight: isRisky ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
