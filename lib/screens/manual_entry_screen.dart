import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/symptom_icon.dart';
import '../services/translation_service.dart';
import '../services/language_service.dart';
import '../services/api_service.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _glycemieController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _pulsationsController = TextEditingController();
  final TextEditingController _oxygenieController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  final Set<String> _selectedSymptoms = {};
  bool _hasbirthDate = false;
  bool _showDobField = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    LanguageService.onLocaleChanged = () {
      if (mounted) setState(() {});
    };
    _checkbirthDate();
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _glycemieController.dispose();
    _temperatureController.dispose();
    _pulsationsController.dispose();
    _oxygenieController.dispose();
    _dobController.dispose();
    LanguageService.onLocaleChanged = null;
    super.dispose();
  }

  Future<void> _checkbirthDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dob = prefs.getString('birthDate');
    setState(() {
      _hasbirthDate = dob != null && dob.isNotEmpty;
      _showDobField = true;
      if (dob != null && dob.isNotEmpty) {
        _dobController.text = dob;
      }
    });
  }

  void _toggleSymptom(String symptomId) {
    setState(() {
      if (_selectedSymptoms.contains(symptomId)) {
        _selectedSymptoms.remove(symptomId);
      } else {
        _selectedSymptoms.add(symptomId);
      }
    });
  }

  Future<void> _selectbirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 10, 96, 142),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color.fromARGB(255, 10, 96, 142),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  String _getRecommendedSpecialty(
    int? systolic,
    int? diastolic,
    int? glycemie,
    int? temperature,
    int? pulsations,
    int? oxygenie,
  ) {
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

  Future<void> _submitData() async {
    // Validation des champs individuels
    Map<String, String> validationErrors = {};

    // Valider la tension artérielle si présente
    if (_systolicController.text.isNotEmpty ||
        _diastolicController.text.isNotEmpty) {
      if (_systolicController.text.isEmpty) {
        validationErrors['systolic'] =
            'La tension systolique est requise si la diastolique est remplie';
      }
      if (_diastolicController.text.isEmpty) {
        validationErrors['diastolic'] =
            'La tension diastolique est requise si la systolique est remplie';
      }

      final systolic = int.tryParse(_systolicController.text);
      final diastolic = int.tryParse(_diastolicController.text);

      if (systolic != null && (systolic < 50 || systolic > 250)) {
        validationErrors['systolic'] =
            'La tension systolique doit être entre 50 et 250 mmHg';
      }
      if (diastolic != null && (diastolic < 30 || diastolic > 200)) {
        validationErrors['diastolic'] =
            'La tension diastolique doit être entre 30 et 200 mmHg';
      }
      if (systolic != null && diastolic != null && systolic <= diastolic) {
        validationErrors['systolic'] =
            'La tension systolique doit être supérieure à la diastolique';
      }
    }

    // Valider la glycémie
    if (_glycemieController.text.isNotEmpty) {
      final glycemie = int.tryParse(_glycemieController.text);
      if (glycemie == null) {
        validationErrors['glycemie'] =
            'Veuillez entrer une valeur valide pour la glycémie';
      } else if (glycemie < 30 || glycemie > 600) {
        validationErrors['glycemie'] =
            'La glycémie doit être entre 30 et 600 mg/dL';
      }
    }

    // Valider la température
    if (_temperatureController.text.isNotEmpty) {
      final temperature = int.tryParse(_temperatureController.text);
      if (temperature == null) {
        validationErrors['temperature'] =
            'Veuillez entrer une valeur valide pour la température';
      } else if (temperature < 32 || temperature > 43) {
        validationErrors['temperature'] =
            'La température doit être entre 32°C et 43°C';
      }
    }

    // Valider les pulsations
    if (_pulsationsController.text.isNotEmpty) {
      final pulsations = int.tryParse(_pulsationsController.text);
      if (pulsations == null) {
        validationErrors['pulsations'] =
            'Veuillez entrer une valeur valide pour les pulsations';
      } else if (pulsations < 30 || pulsations > 250) {
        validationErrors['pulsations'] =
            'Les pulsations doivent être entre 30 et 250 bpm';
      }
    }

    // Valider l'oxygénation
    if (_oxygenieController.text.isNotEmpty) {
      final oxygenie = int.tryParse(_oxygenieController.text);
      if (oxygenie == null) {
        validationErrors['oxygenie'] =
            'Veuillez entrer une valeur valide pour la saturation';
      } else if (oxygenie < 50 || oxygenie > 100) {
        validationErrors['oxygenie'] =
            'La saturation doit être entre 50% et 100%';
      }
    }

    // Valider la date de naissance
    if (_dobController.text.isNotEmpty) {
      try {
        final dobParts = _dobController.text.split('-');
        if (dobParts.length == 3) {
          final year = int.parse(dobParts[0]);
          final currentYear = DateTime.now().year;
          if (year < 1900 || year > currentYear) {
            validationErrors['dob'] =
                'L\'année de naissance doit être entre 1900 et $currentYear';
          }
        }
      } catch (e) {
        validationErrors['dob'] = 'Date de naissance invalide';
      }
    }

    // Afficher les erreurs de validation
    if (validationErrors.isNotEmpty) {
      String errorMessage = validationErrors.values.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Check if at least one field has data
    final hasAnyData =
        _systolicController.text.isNotEmpty ||
        _diastolicController.text.isNotEmpty ||
        _glycemieController.text.isNotEmpty ||
        _temperatureController.text.isNotEmpty ||
        _pulsationsController.text.isNotEmpty ||
        _oxygenieController.text.isNotEmpty;

    if (!hasAnyData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir au moins une donnée'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    if (_dobController.text.isNotEmpty && !_hasbirthDate) {
      await prefs.setString('birthDate', _dobController.text);
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));

    final systolic = int.tryParse(_systolicController.text);
    final diastolic = int.tryParse(_diastolicController.text);
    final glycemie = int.tryParse(_glycemieController.text);
    final temperature = int.tryParse(_temperatureController.text);
    final pulsations = int.tryParse(_pulsationsController.text);
    final oxygenie = int.tryParse(_oxygenieController.text);
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Save only if values are provided
    if (systolic != null) await prefs.setInt('latest_systolic', systolic);
    if (diastolic != null) await prefs.setInt('latest_diastolic', diastolic);
    if (glycemie != null) await prefs.setInt('latest_glycemie', glycemie);
    if (temperature != null)
      await prefs.setInt('latest_temperature', temperature);
    if (pulsations != null) await prefs.setInt('latest_pulse', pulsations);
    if (oxygenie != null) await prefs.setInt('latest_oxygenie', oxygenie);
    await prefs.setString('latest_record_date', dateStr);
    setState(() {});
    String status = 'normal';
    if (systolic != null && diastolic != null) {
      if (systolic > 180 || diastolic > 120) {
        status = 'alert';
      } else if (systolic > 140 || diastolic > 90) {
        status = 'attention';
      }
    }
    if (glycemie != null && glycemie > 200) {
      status = 'alert';
    } else if (glycemie != null && glycemie > 126) {
      status = 'attention';
    }
    if (temperature != null && temperature > 39) {
      status = 'alert';
    } else if (temperature != null && temperature > 37.5) {
      status = 'attention';
    }
    if (pulsations != null && (pulsations > 120 || pulsations < 40)) {
      status = 'alert';
    } else if (pulsations != null && (pulsations > 100 || pulsations < 60)) {
      status = 'attention';
    }
    if (oxygenie != null && oxygenie < 90) {
      status = 'alert';
    } else if (oxygenie != null && oxygenie < 95) {
      status = 'attention';
    }

    await prefs.setString('latest_status', status);

    // Save to database via API
    try {
      final apiResult = await ApiService.saveHealthData(
        systolic: systolic,
        diastolic: diastolic,
        glycemie: glycemie,
        temperature: temperature?.toDouble(),
        pulsations: pulsations,
        oxygenie: oxygenie,
        recordedAt: dateStr,
        symptoms: _selectedSymptoms.toList(),
        birthDate: _dobController.text.isNotEmpty ? _dobController.text : null,
      );

      if (apiResult['success'] != true) {
        final msg = apiResult['message'] ?? apiResult.toString();
        debugPrint('Failed to save to API: $msg');
        debugPrint('birthDate sent: ${_dobController.text}');
        debugPrint('birthDate local saved: ${prefs.getString('birthDate')}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur API: ${apiResult['message'] ?? ""}"),
              backgroundColor: const Color(0xFFE74C3C),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
    } catch (e) {
      debugPrint('API error: $e');
    }

    // Notifier le médecin si anomalie détectée
    if (status == 'alert' || status == 'attention') {
      try {
        // Calculer le danger_rate (0-100)
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

        dangerRate = dangerRate.clamp(0, 100);

        // Notifier le médecin
        final specialty = _getRecommendedSpecialty(
          systolic,
          diastolic,
          glycemie,
          temperature,
          pulsations,
          oxygenie,
        );

        await ApiService.notifyDoctorOfRisk(
          dangerRate: dangerRate,
          severity: status == 'alert' ? 'critical' : 'moderate',
          recommendedSpecialty: specialty,
          symptoms: _selectedSymptoms.toList(),
          systolic: systolic,
          diastolic: diastolic,
          glucose: glycemie,
          temperature: temperature,
          pulse: pulsations,
          oxygenSaturation: oxygenie,
        );

        debugPrint('✅ Médecin notifié avec succès');
      } catch (e) {
        debugPrint('❌ Erreur notification médecin: $e');
      }
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données de santé enregistrées avec succès!'),
          backgroundColor: Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
        ),
      );

      _systolicController.clear();
      _diastolicController.clear();
      _glycemieController.clear();
      _temperatureController.clear();
      _pulsationsController.clear();
      _oxygenieController.clear();
      setState(() {
        _selectedSymptoms.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Saisie Manuelle',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 10, 96, 142),
        elevation: 0,
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showDobField) ...[
                _SectionHeader(
                  title: 'Date de naissance',
                  icon: Icons.cake_outlined,
                  color: const Color.fromARGB(255, 12, 12, 12),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _selectbirthDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              255,
                              17,
                              119,
                              166,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            color: Color.fromARGB(255, 10, 96, 142),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _dobController.text.isEmpty
                                ? 'Sélectionnez votre date de naissance'
                                : _dobController.text,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _dobController.text.isEmpty
                                  ? const Color(0xFF94A3B8)
                                  : const Color.fromARGB(255, 10, 96, 142),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _SectionHeader(
                title: 'Tension artérielle',
                icon: Icons.favorite_outline_rounded,
                color: const Color(0xFFE74C3C),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _NumericInputField(
                        controller: _systolicController,
                        label: 'Systolique',
                        hint: '120',
                        unit: 'mmHg',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        height: 40,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    Expanded(
                      child: _NumericInputField(
                        controller: _diastolicController,
                        label: 'Diastolique',
                        hint: '80',
                        unit: 'mmHg',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Glycémie',
                icon: Icons.water_drop_outlined,
                color: const Color(0xFFF39C12),
              ),
              const SizedBox(height: 12),
              _MeasurementCard(
                child: _NumericInputField(
                  controller: _glycemieController,
                  label: 'Glycémie',
                  hint: '95',
                  unit: 'mg/dL',
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Température corporelle',
                icon: Icons.thermostat_outlined,
                color: const Color(0xFFE67E22),
              ),
              const SizedBox(height: 12),
              _MeasurementCard(
                child: _NumericInputField(
                  controller: _temperatureController,
                  label: 'Température',
                  hint: '37',
                  unit: '°C',
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Fréquence cardiaque',
                icon: Icons.favorite_border_rounded,
                color: const Color(0xFFE91E63),
              ),
              const SizedBox(height: 12),
              _MeasurementCard(
                child: _NumericInputField(
                  controller: _pulsationsController,
                  label: 'Fréquence cardiaque',
                  hint: '72',
                  unit: 'bpm',
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Saturation en oxygène',
                icon: Icons.air_outlined,
                color: const Color(0xFF3498DB),
              ),
              const SizedBox(height: 12),
              _MeasurementCard(
                child: _NumericInputField(
                  controller: _oxygenieController,
                  label: 'SpO₂',
                  hint: '98',
                  unit: '%',
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Symptômes associés',
                icon: Icons.sick,
                color: const Color(0xFF9B59B6),
              ),
              const SizedBox(height: 12),
              _SymptomCategory(
                title: 'Sélectionnez vos symptômes',
                symptoms: getLocalizedSymptoms(context),
                selectedSymptoms: _selectedSymptoms,
                onToggle: _toggleSymptom,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Enregistrer les données',

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(255, 23, 95, 114),
          ),
        ),
      ],
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final Widget child;
  const _MeasurementCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}

class _NumericInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String unit;
  const _NumericInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.unit,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 10, 96, 142),
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFCBD5E1),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SymptomCategory extends StatelessWidget {
  final String title;
  final List<SymptomData> symptoms;
  final Set<String> selectedSymptoms;
  final Function(String) onToggle;
  const _SymptomCategory({
    required this.title,
    required this.symptoms,
    required this.selectedSymptoms,
    required this.onToggle,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: symptoms.map((symptom) {
              final isSelected = selectedSymptoms.contains(symptom.id);
              return GestureDetector(
                onTap: () => onToggle(symptom.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2C3E50)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2C3E50)
                          : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        symptom.icon,
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        symptom.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
