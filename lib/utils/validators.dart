import 'package:flutter/material.dart';

/// Validators for HealWise Mobile App
/// Each function returns null if valid, or an error message string if invalid

// ============================================================
// GENERAL VALIDATORS
// ============================================================

/// Validates that a field is not empty
String? validateRequired(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName est requis';
  }
  return null;
}

/// Validates name (letters only, min 2 chars)
String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Le nom est requis';
  }
  if (value.trim().length < 2) {
    return 'Le nom doit contenir au moins 2 caractères';
  }
  if (value.trim().length > 50) {
    return 'Le nom ne doit pas dépasser 50 caractères';
  }
  // Allow letters, spaces, dashes, and apostrophes
  final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$");
  if (!nameRegex.hasMatch(value.trim())) {
    return 'Le nom ne doit contenir que des lettres';
  }
  return null;
}

/// Validates email format
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'L\'email est requis';
  }
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Veuillez entrer un email valide';
  }
  return null;
}

/// Validates password (min 6 chars)
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Le mot de passe est requis';
  }
  if (value.length < 6) {
    return 'Le mot de passe doit contenir au moins 6 caractères';
  }
  if (value.length > 50) {
    return 'Le mot de passe ne doit pas dépasser 50 caractères';
  }
  return null;
}

/// Validates date of birth (YYYY-MM-DD format and reasonable age)
String? validateDateOfBirth(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'La date de naissance est requise';
  }
  // Check format YYYY-MM-DD
  final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  if (!dateRegex.hasMatch(value.trim())) {
    return 'Format: AAAA-MM-JJ';
  }
  // Parse and validate year
  final parts = value.split('-');
  final year = int.tryParse(parts[0]);
  if (year == null || year < 1900 || year > DateTime.now().year) {
    return 'Année invalide';
  }
  return null;
}

// ============================================================
// HEALTH DATA VALIDATORS
// ============================================================

/// Validates systolic blood pressure (normal: 90-180 mmHg)
String? validateSystolic(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null; // Optional field
  }
  final num = int.tryParse(value);
  if (num == null) {
    return 'Valeur numérique requise';
  }
  if (num < 60 || num > 250) {
    return 'Valeur normale: 60-250 mmHg';
  }
  return null;
}

/// Validates diastolic blood pressure (normal: 40-120 mmHg)
String? validateDiastolic(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null; // Optional field
  }
  final num = int.tryParse(value);
  if (num == null) {
    return 'Valeur numérique requise';
  }
  if (num < 30 || num > 150) {
    return 'Valeur normale: 30-150 mmHg';
  }
  return null;
}

/// Validates glycemia (normal: 70-126 mg/dL)
String? validateGlycemia(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null; // Optional field
  }
  final num = int.tryParse(value);
  if (num == null) {
    return 'Valeur numérique requise';
  }
  if (num < 30 || num > 500) {
    return 'Valeur normale: 30-500 mg/dL';
  }
  return null;
}

/// Validates temperature (normal: 35-42°C)
String? validateTemperature(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null; // Optional field
  }
  // Handle comma or dot decimal
  final cleanValue = value.replaceAll(',', '.');
  final num = double.tryParse(cleanValue);
  if (num == null) {
    return 'Valeur numérique requise';
  }
  if (num < 30 || num > 45) {
    return 'Valeur normale: 30-45°C';
  }
  return null;
}

/// Validates heart rate / pulsations (normal: 40-200 bpm)
String? validatePulsations(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null; // Optional field
  }
  final num = int.tryParse(value);
  if (num == null) {
    return 'Valeur numérique requise';
  }
  if (num < 20 || num > 250) {
    return 'Valeur normale: 20-250 bpm';
  }
  return null;
}

/// Validates respiratory rate (normal: 8-40 resp/min)
String? validateRespiratoryRate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null; // Optional field
  }
  final num = int.tryParse(value);
  if (num == null) {
    return 'Valeur numérique requise';
  }
  if (num < 5 || num > 50) {
    return 'Valeur normale: 5-50 resp/min';
  }
  return null;
}

/// Validates oxygen saturation SpO2 (normal: 50-100%)
String? validateOxygen(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null; // Optional field
  }
  final num = int.tryParse(value);
  if (num == null) {
    return 'Valeur numérique requise';
  }
  if (num < 50 || num > 100) {
    return 'Valeur normale: 50-100%';
  }
  return null;
}

// ============================================================
// MEDICATION VALIDATORS
// ============================================================

/// Validates medication name
String? validateMedicationName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Le nom du médicament est requis';
  }
  if (value.trim().length < 2) {
    return 'Le nom doit contenir au moins 2 caractères';
  }
  if (value.trim().length > 100) {
    return 'Le nom ne doit pas dépasser 100 caractères';
  }
  return null;
}

/// Validates dosage (e.g., "500mg", "2 comprimés")
String? validateDosage(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Le dosage est requis';
  }
  if (value.trim().length > 50) {
    return 'Le dosage ne doit pas dépasser 50 caractères';
  }
  return null;
}

/// Validates stock quantity (positive integer)
String? validateStock(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Le stock est requis';
  }
  final num = int.tryParse(value);
  if (num == null) {
    return 'Nombre entier requis';
  }
  if (num < 0 || num > 9999) {
    return 'Stock: 0-9999';
  }
  return null;
}

/// Validates medication notes (optional field)
String? validateMedicationNote(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null; // Optional
  }
  if (value.trim().length > 500) {
    return 'Note: max 500 caractères';
  }
  return null;
}

// ============================================================
// PRE-BUILT VALIDATOR FOR FORMS
// ============================================================

/// Use this to wrap validators with multi-field support
/// Example: validator: (v) => validateField(v, [validateRequired, validateName])
String? validateField(
  String? value,
  List<String? Function(String?)> validators,
) {
  for (final validator in validators) {
    final error = validator(value);
    if (error != null) {
      return error;
    }
  }
  return null;
}

/// Theme colors for error messages (to use in InputDecoration)
class ValidatorTheme {
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;

  static InputDecoration errorDecoration(String label, String? errorText) {
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      errorStyle: const TextStyle(color: errorColor),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
    );
  }
}
