import 'package:flutter/material.dart';
import '../utils/validators.dart';

/// Example: How to use validators in TextFormField
class ValidatorUsageExample extends StatefulWidget {
  const ValidatorUsageExample({super.key});

  @override
  State<ValidatorUsageExample> createState() => _ValidatorUsageExampleState();
}

class _ValidatorUsageExampleState extends State<ValidatorUsageExample> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _systolicController = TextEditingController();
  final _glycemieController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _medNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _stockController = TextEditingController(text: '30');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _systolicController.dispose();
    _glycemieController.dispose();
    _temperatureController.dispose();
    _medNameController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formulaire valide! ✅'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exemples de Validators')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // =========================================
            // SECTION 1: Inscription / Login Fields
            // =========================================
            const Text(
              '📝 Champs inscription',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: validateName, // 👈 Simple!
            ),
            const SizedBox(height: 12),

            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              validator: validateEmail, // 👈 Simple!
            ),
            const SizedBox(height: 12),

            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              validator: validatePassword, // 👈 Simple!
            ),
            const SizedBox(height: 24),

            // =========================================
            // SECTION 2: Manual Entry Health Data
            // =========================================
            const Text(
              '❤️ Données santé (Manual Entry)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Systolic BP
            TextFormField(
              controller: _systolicController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tension systolique (mmHg)',
                hintText: 'Ex: 120',
                prefixIcon: Icon(Icons.favorite),
                border: OutlineInputBorder(),
              ),
              validator: validateSystolic, // 👈 Simple!
            ),
            const SizedBox(height: 12),

            // Glycemia
            TextFormField(
              controller: _glycemieController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Glycémie (mg/dL)',
                hintText: 'Ex: 95',
                prefixIcon: Icon(Icons.water_drop),
                border: OutlineInputBorder(),
              ),
              validator: validateGlycemia, // 👈 Simple!
            ),
            const SizedBox(height: 12),

            // Temperature
            TextFormField(
              controller: _temperatureController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Température (°C)',
                hintText: 'Ex: 37.0',
                prefixIcon: Icon(Icons.thermostat),
                border: OutlineInputBorder(),
              ),
              validator: validateTemperature, // 👈 Simple!
            ),
            const SizedBox(height: 24),

            // =========================================
            // SECTION 3: Medication Fields
            // =========================================
            const Text(
              '💊 Médicaments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Medication name
            TextFormField(
              controller: _medNameController,
              decoration: const InputDecoration(
                labelText: 'Nom du médicament',
                prefixIcon: Icon(Icons.medication),
                border: OutlineInputBorder(),
              ),
              validator: validateMedicationName, // 👈 Simple!
            ),
            const SizedBox(height: 12),

            // Dosage
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                hintText: 'Ex: 500mg',
                prefixIcon: Icon(Icons.scale),
                border: OutlineInputBorder(),
              ),
              validator: validateDosage, // 👈 Simple!
            ),
            const SizedBox(height: 12),

            // Stock
            TextFormField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantité en stock',
                prefixIcon: Icon(Icons.inventory),
                border: OutlineInputBorder(),
              ),
              validator: validateStock, // 👈 Simple!
            ),
            const SizedBox(height: 32),

            // =========================================
            // SUBMIT BUTTON
            // =========================================
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: const Color(0xFF2C3E50),
              ),
              child: const Text(
                'Valider le formulaire',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),

            // =========================================
            // NOTES
            // =========================================
            const Card(
              color: Colors.blueGrey,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Notes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Chaque validator retourne null si valide\n'
                      '• Retourne un message d\'erreur en rouge si invalide\n'
                      '• Les champs santé sont optionnels (retournent null si vide)\n'
                      '• Utilisez directement dans le paramètre validator',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
