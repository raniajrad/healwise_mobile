import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class SymptomData {
  final String id;
  final String label;
  final IconData icon;

  const SymptomData({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class SymptomIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SymptomIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 23, 95, 114)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 23, 95, 114)
                : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color.fromARGB(255, 23, 95, 114).withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? Colors.white
                  : const Color.fromARGB(255, 23, 95, 114),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

List<SymptomData> getLocalizedSymptoms(BuildContext context) {
  // TOUS les symptômes en FRANÇAIS
  return [
    // Symptômes de base
    SymptomData(id: 'headache', label: 'Mal de tête', icon: Icons.psychology),
    SymptomData(id: 'fatigue', label: 'Fatigue', icon: Icons.battery_1_bar),
    SymptomData(id: 'nausea', label: 'Nausées', icon: Icons.sick),
    SymptomData(id: 'dizziness', label: 'Vertiges', icon: Icons.rotate_right),
    SymptomData(
      id: 'chest_pain',
      label: 'Douleur thoracique',
      icon: Icons.favorite,
    ),
    SymptomData(
      id: 'shortness_breath',
      label: 'Essoufflement',
      icon: Icons.air,
    ),
    SymptomData(
      id: 'back_pain',
      label: 'Douleur dorsale',
      icon: Icons.accessibility_new,
    ),
    SymptomData(
      id: 'joint_pain',
      label: 'Douleur articulaire',
      icon: Icons.pan_tool,
    ),
    SymptomData(id: 'fever', label: 'Fièvre', icon: Icons.thermostat),
    SymptomData(id: 'cough', label: 'Toux', icon: Icons.masks),
    SymptomData(
      id: 'sore_throat',
      label: 'Mal de gorge',
      icon: Icons.record_voice_over,
    ),
    SymptomData(
      id: 'runny_nose',
      label: 'Nez qui coule',
      icon: Icons.water_drop,
    ),

    // NOUVEAUX SYMPTÔMES AJOUTÉS (en français)
    SymptomData(
      id: 'abdominal_pain',
      label: 'Douleur abdominale',
      icon: Icons.medical_services,
    ),
    SymptomData(
      id: 'vomiting',
      label: 'Vomissements',
      icon: Icons.sick_outlined,
    ),
    SymptomData(id: 'diarrhea', label: 'Diarrhée', icon: Icons.water),
    SymptomData(
      id: 'constipation',
      label: 'Constipation',
      icon: Icons.hourglass_bottom,
    ),
    SymptomData(id: 'insomnia', label: 'Insomnie', icon: Icons.nights_stay),
    SymptomData(id: 'anxiety', label: 'Anxiété', icon: Icons.psychology_alt),
    SymptomData(
      id: 'muscle_pain',
      label: 'Douleur musculaire',
      icon: Icons.fitness_center,
    ),
    SymptomData(
      id: 'skin_rash',
      label: 'Éruption cutanée',
      icon: Icons.sanitizer,
    ),
    SymptomData(
      id: 'blurred_vision',
      label: 'Vision floue',
      icon: Icons.visibility_off,
    ),
    SymptomData(
      id: 'numbness',
      label: 'Engourdissement',
      icon: Icons.touch_app,
    ),
    SymptomData(
      id: 'loss_appetite',
      label: 'Perte d\'appétit',
      icon: Icons.restaurant,
    ),
    SymptomData(
      id: 'sweating',
      label: 'Transpiration excessive',
      icon: Icons.water_drop_outlined,
    ),
    SymptomData(id: 'chills', label: 'Frissons', icon: Icons.ac_unit),
    SymptomData(id: 'ear_pain', label: 'Mal d\'oreille', icon: Icons.hearing),
    SymptomData(
      id: 'eye_pain',
      label: 'Douleur oculaire',
      icon: Icons.visibility,
    ),
  ];
}

// Version anglaise pour la compatibilité (si nécessaire)
const List<SymptomData> availableSymptoms = [
  SymptomData(id: 'headache', label: 'Headache', icon: Icons.psychology),
  SymptomData(id: 'fatigue', label: 'Fatigue', icon: Icons.battery_1_bar),
  SymptomData(id: 'nausea', label: 'Nausea', icon: Icons.sick),
  SymptomData(id: 'dizziness', label: 'Dizziness', icon: Icons.rotate_right),
  SymptomData(id: 'chest_pain', label: 'Chest Pain', icon: Icons.favorite),
  SymptomData(
    id: 'shortness_breath',
    label: 'Shortness of Breath',
    icon: Icons.air,
  ),
  SymptomData(
    id: 'back_pain',
    label: 'Back Pain',
    icon: Icons.accessibility_new,
  ),
  SymptomData(id: 'joint_pain', label: 'Joint Pain', icon: Icons.pan_tool),
  SymptomData(id: 'fever', label: 'Fever', icon: Icons.thermostat),
  SymptomData(id: 'cough', label: 'Cough', icon: Icons.masks),
  SymptomData(
    id: 'sore_throat',
    label: 'Sore Throat',
    icon: Icons.record_voice_over,
  ),
  SymptomData(id: 'runny_nose', label: 'Runny Nose', icon: Icons.water_drop),
  SymptomData(
    id: 'abdominal_pain',
    label: 'Abdominal Pain',
    icon: Icons.medical_services,
  ),
  SymptomData(id: 'vomiting', label: 'Vomiting', icon: Icons.sick_outlined),
  SymptomData(id: 'diarrhea', label: 'Diarrhea', icon: Icons.water),
  SymptomData(
    id: 'constipation',
    label: 'Constipation',
    icon: Icons.hourglass_bottom,
  ),
  SymptomData(id: 'insomnia', label: 'Insomnia', icon: Icons.nights_stay),
  SymptomData(id: 'anxiety', label: 'Anxiety', icon: Icons.psychology_alt),
  SymptomData(
    id: 'muscle_pain',
    label: 'Muscle Pain',
    icon: Icons.fitness_center,
  ),
  SymptomData(id: 'skin_rash', label: 'Skin Rash', icon: Icons.sanitizer),
  SymptomData(
    id: 'blurred_vision',
    label: 'Blurred Vision',
    icon: Icons.visibility_off,
  ),
  SymptomData(id: 'numbness', label: 'Numbness', icon: Icons.touch_app),
];
