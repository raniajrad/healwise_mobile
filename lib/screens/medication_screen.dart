import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../screens/profile_screen.dart';

// ─────────────────────────────────────────────
//  Liste des médicaments reconnus
// ─────────────────────────────────────────────
const List<String> kMedicationNames = [
  'Paracétamol',
  'Amoxicilline',
  'Ibuprofène',
  'Aspirine',
  'Metformine',
  'Amlodipine',
  'Atorvastatine',
  'Oméprazole',
  'Lisinopril',
  'Metoprolol',
  'Azithromycine',
  'Ciprofloxacine',
  'Doxycycline',
  'Loratadine',
  'Cétirizine',
  'Salbutamol',
  'Prednisolone',
  'Diclofénac',
  'Tramadol',
  'Codéine',
  'Insuline',
  'Lévothyroxine',
  'Warfarine',
  'Furosémide',
  'Hydrochlorothiazide',
  'Pantoprazole',
  'Ranitidine',
  'Metronidazole',
  'Fluconazole',
  'Acyclovir',
  'Allopurinol',
  'Bisoprolol',
  'Ramipril',
  'Simvastatine',
  'Clopidogrel',
  'Amiodarone',
  'Gabapentine',
  'Sertraline',
  'Fluoxétine',
  'Lorazépam',
];

// ─────────────────────────────────────────────
//  Couleurs
// ─────────────────────────────────────────────
const Color _kBrand = Color(0xFF175F72);
const Color _kAccent = Color(0xFF000000);
const Color _kDanger = Color(0xFFE63946);
const Color _kSuccess = Color(0xFF1B6B3A);
const Color _kSurface = Color(0xFFF4F7FB);
const Color _kCard = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFE8EEF5);

const List<Color> _kMedColors = [
  Color(0xFFE63946),
  Color(0xFF3B8BFF),
  Color(0xFF2A9D8F),
  Color(0xFFF4A261),
  Color(0xFF7B2D8B),
  Color(0xFF4CAF50),
];

const List<String> _kForms = ['Comprimé', 'Gélule', 'Sirop', 'Injection'];
const List<String> _kFrequencies = [
  'Quotidien',
  'Hebdomadaire',
  'Mensuel',
  'Sur ordonnance',
];
const List<String> _kMealOptions = ['Pendant repas', 'Après repas', 'À jeun'];

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────
String _fmt(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _fmtDt(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

// ─────────────────────────────────────────────
//  Modèle MedicationEntry
// ─────────────────────────────────────────────
class MedicationEntry {
  final String id;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  Color color;
  String frequency = 'Quotidien';
  String form = 'Comprimé';
  String meal = 'Pendant repas';
  List<TimeOfDay> selectedTimes = [];
  bool alertsEnabled = false; 
  bool reportEnabled = true; 

  MedicationEntry({required this.id, required int index})
    : color = _kMedColors[index % _kMedColors.length];

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    noteController.dispose();
  }
}

// ═══════════════════════════════════════════════
//  MedicationScreen
// ═══════════════════════════════════════════════
class MedicationScreen extends StatefulWidget {
  const MedicationScreen({Key? key}) : super(key: key);

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();
  final List<MedicationEntry> _medications = [];
  bool _isLoading = false;
  int _idCounter = 0;

  @override
  void initState() {
    super.initState();
    _addMedication();
  }

  @override
  void dispose() {
    for (final m in _medications) m.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _addMedication() {
    setState(() {
      _medications.add(
        MedicationEntry(id: 'med_$_idCounter', index: _medications.length),
      );
      _idCounter++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeMedication(MedicationEntry med) {
    if (_medications.length == 1) return;
    HapticFeedback.lightImpact();
    setState(() {
      med.dispose();
      _medications.remove(med);
    });
  }

  Future<void> _pickTime(MedicationEntry med) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kBrand,
            onPrimary: Colors.white,
            surface: _kCard,
            onSurface: _kBrand,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && !med.selectedTimes.contains(picked)) {
      HapticFeedback.selectionClick();
      setState(() => med.selectedTimes.add(picked));
      med.selectedTimes.sort((a, b) {
        if (a.hour == b.hour) return a.minute.compareTo(b.minute);
        return a.hour.compareTo(b.hour);
      });
    }
  }

  bool _validateAll() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _snack('Veuillez remplir tous les champs obligatoires', isError: true);
      return false;
    }
    if (_medications.any((m) => m.selectedTimes.isEmpty)) {
      _snack(
        'Ajoutez au moins un horaire pour chaque médicament',
        isError: true,
      );
      return false;
    }
    return true;
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? _kDanger : _kSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _saveAll() async {
    if (!_validateAll()) return;
    setState(() => _isLoading = true);

    String? errorMessage;
    bool saveSuccess = true;

    try {
      for (int i = 0; i < _medications.length; i++) {
        final med = _medications[i];
        final userId = await ApiService.getUserId() ?? 1;
        final now = DateTime.now();
        final first = med.selectedTimes.first;
        final reminderTime = _fmtDt(
          DateTime(now.year, now.month, now.day, first.hour, first.minute),
        );

        // Dans _saveAll() de MedicationScreen
        final result = await ApiService.addMedication(
          userId: userId,
          name: med.nameController.text.trim(),
          dosage: med.dosageController.text.trim(),
          frequency: med.frequency,
          reminderTime: reminderTime,
          notes: med.noteController.text.trim(),
          reportEnabled: med.reportEnabled,
        );

        if (!(result['success'] as bool)) {
          errorMessage = 'Échec : ${result['message'] ?? 'Erreur serveur'}';
          saveSuccess = false;
          break;
        }

        final medicationId = result['data']?['id'];

        if (medicationId != null && med.selectedTimes.length > 1) {
          for (int s = 1; s < med.selectedTimes.length; s++) {
            final t = med.selectedTimes[s];
            await ApiService.addMedicationSchedule(
              medicationId,
              timeSlot: 'prise_$s',
              reminderTime: _fmtDt(
                DateTime(now.year, now.month, now.day, t.hour, t.minute),
              ),
            );
          }
        }

        // Seulement si l'utilisateur a activé les alertes
        if (med.alertsEnabled) {
          for (int j = 0; j < med.selectedTimes.length; j++) {
            final t = med.selectedTimes[j];
            var scheduled = DateTime(
              now.year,
              now.month,
              now.day,
              t.hour,
              t.minute,
            );
            if (scheduled.isBefore(now)) {
              scheduled = scheduled.add(const Duration(days: 1));
            }
            await NotificationService.scheduleNotification(
              i * 100 + j,
              'HealWise - Rappel Traitement',
              'Prenez ${med.nameController.text} (${med.dosageController.text})',
              scheduled,
            );
          }
        }
      }

      if (!mounted) return;
      if (saveSuccess) {
        _snack('${_medications.length} traitement(s) enregistré(s) !');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
          (route) => false,
        );
      } else {
        _snack(errorMessage ?? 'Erreur inconnue', isError: true);
      }
    } catch (e) {
      if (mounted) _snack('Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: _kBrand,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes Traitements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${_medications.length} médicament${_medications.length > 1 ? 's' : ''} ajouté${_medications.length > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white60,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _addMedication,
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: const Text(
                'Ajouter',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: _kAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kBrand))
          : Form(
              key: _formKey,
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 100),
                itemCount: _medications.length,
                itemBuilder: (ctx, i) => _MedicationCard(
                  key: ValueKey(_medications[i].id),
                  med: _medications[i],
                  index: i,
                  canRemove: _medications.length > 1,
                  onRemove: () => _removeMedication(_medications[i]),
                  onPickTime: () => _pickTime(_medications[i]),
                  onUpdate: () => setState(() {}),
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveAll,
        backgroundColor: _kBrand,
        elevation: 6,
        icon: const Icon(Icons.save_rounded),
        label: const Text(
          'Enregistrer',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  _MedicationCard
// ═══════════════════════════════════════════════
class _MedicationCard extends StatelessWidget {
  final MedicationEntry med;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onPickTime;
  final VoidCallback onUpdate;

  const _MedicationCard({
    Key? key,
    required this.med,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onPickTime,
    required this.onUpdate,
  }) : super(key: key);

  bool _isKnown(String name) =>
      kMedicationNames.any((m) => m.toLowerCase() == name.toLowerCase());

  InputDecoration _deco({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF94A3B8),
      ),
      hintText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFFAFBFD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBrand, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kBrand.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: med.color,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Médicament ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kBrand,
                    ),
                  ),
                ),
                if (canRemove)
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _kDanger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: _kDanger,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F4F8)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom du médicament
                const Text(
                  'NOM DU MÉDICAMENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 5),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.trim().isEmpty)
                      return const Iterable<String>.empty();
                    return kMedicationNames.where(
                      (String n) => n.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                    );
                  },
                  onSelected: (String selection) {
                    med.nameController.text = selection;
                    onUpdate();
                  },
                  fieldViewBuilder:
                      (
                        BuildContext context,
                        TextEditingController textEditingController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        if (textEditingController.text !=
                            med.nameController.text) {
                          textEditingController.text = med.nameController.text;
                        }
                        textEditingController.addListener(() {
                          med.nameController.text = textEditingController.text;
                        });
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: _deco(
                            label: 'Ex: Paracétamol',
                            icon: Icons.medication_rounded,
                            suffix: med.nameController.text.isNotEmpty
                                ? Icon(
                                    _isKnown(med.nameController.text)
                                        ? Icons.check_circle_rounded
                                        : Icons.warning_amber_rounded,
                                    color: _isKnown(med.nameController.text)
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 18,
                                  )
                                : null,
                          ),
                          validator: (String? value) {
                            final val = value?.trim() ?? '';
                            if (val.isEmpty) return 'Le nom est obligatoire';
                            if (val.length < 3) return 'Minimum 3 caractères';
                            if (!RegExp(
                              r'^[a-zA-ZÀ-ÿ0-9 \-\.]+$',
                            ).hasMatch(val))
                              return 'Caractères spéciaux non autorisés';
                            if (!_isKnown(val)) return 'Médicament non reconnu';
                            return null;
                          },
                          onChanged: (String _) => onUpdate(),
                        );
                      },
                  optionsViewBuilder:
                      (
                        BuildContext context,
                        AutocompleteOnSelected<String> onSelected,
                        Iterable<String> options,
                      ) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(12),
                            shadowColor: _kBrand.withOpacity(0.15),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 220,
                                maxWidth: 300,
                              ),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int i) {
                                  final String option = options.elementAt(i);
                                  return InkWell(
                                    onTap: () => onSelected(option),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.medication_outlined,
                                            size: 14,
                                            color: med.color,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              option,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                ),
                const SizedBox(height: 10),

                // Dosage + Forme
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DOSAGE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: med.dosageController,
                            decoration: _deco(
                              label: 'Ex: 500mg',
                              icon: Icons.monitor_weight_outlined,
                            ),
                            validator: (String? value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'Obligatoire'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FORME',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 5),
                          DropdownButtonFormField<String>(
                            value: med.form,
                            isExpanded: true,
                            items: _kForms
                                .map(
                                  (String form) => DropdownMenuItem<String>(
                                    value: form,
                                    child: Text(
                                      form,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                med.form = newValue;
                                onUpdate();
                              }
                            },
                            decoration: _deco(
                              label: 'Forme',
                              icon: Icons.category_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Fréquence + Prise - CORRIGÉ POUR ÉVITER LE DÉBORDEMENT
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FRÉQUENCE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            constraints: const BoxConstraints(minWidth: 0),
                            child: DropdownButtonFormField<String>(
                              value: med.frequency,
                              isExpanded: true,
                              items: _kFrequencies
                                  .map(
                                    (String freq) => DropdownMenuItem<String>(
                                      value: freq,
                                      child: Text(
                                        freq,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  med.frequency = newValue;
                                  onUpdate();
                                }
                              },
                              decoration:
                                  _deco(
                                    label: 'Fréquence',
                                    icon: Icons.repeat_rounded,
                                  ).copyWith(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 12,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PRISE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            constraints: const BoxConstraints(minWidth: 0),
                            child: DropdownButtonFormField<String>(
                              value: med.meal,
                              isExpanded: true,
                              items: _kMealOptions
                                  .map(
                                    (String meal) => DropdownMenuItem<String>(
                                      value: meal,
                                      child: Text(
                                        meal,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  med.meal = newValue;
                                  onUpdate();
                                }
                              },
                              decoration:
                                  _deco(
                                    label: 'Prise',
                                    icon: Icons.restaurant_rounded,
                                  ).copyWith(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 12,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Horaires
                const Text(
                  'HORAIRES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                if (med.selectedTimes.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: med.selectedTimes.map((TimeOfDay time) {
                      return _TimeChip(
                        time: _fmt(time),
                        color: med.color,
                        onDelete: () {
                          med.selectedTimes.remove(time);
                          onUpdate();
                        },
                      );
                    }).toList(),
                  ),
                if (med.selectedTimes.isNotEmpty) const SizedBox(height: 8),
                _AddTimeButton(color: med.color, onTap: onPickTime),
                const SizedBox(height: 4),

                // Toggles - Alertes et Rapport PDF (désactivés par défaut)
                const Divider(height: 20, color: Color(0xFFF0F4F8)),
                _ToggleRow(
                  title: 'Alertes',
                  subtitle: 'Recevoir des rappels',
                  value: med.alertsEnabled,
                  color: med.color,
                  onChanged: (bool newValue) {
                    med.alertsEnabled = newValue;
                    onUpdate();
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF8FAFC)),
                _ToggleRow(
                  title: 'Rapport PDF',
                  subtitle: 'Inclure dans le document',
                  value: med.reportEnabled,
                  color: _kBrand,
                  onChanged: (bool newValue) {
                    med.reportEnabled = newValue;
                    onUpdate();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _TimeChip
// ─────────────────────────────────────────────
class _TimeChip extends StatelessWidget {
  final String time;
  final Color color;
  final VoidCallback onDelete;

  const _TimeChip({
    required this.time,
    required this.color,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close_rounded,
              size: 12,
              color: color.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _AddTimeButton
// ─────────────────────────────────────────────
class _AddTimeButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _AddTimeButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_alarm_rounded, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              'Ajouter un horaire',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _ToggleRow
// ─────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kBrand,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.4),
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
