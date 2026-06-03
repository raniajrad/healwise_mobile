import 'dart:async';
import 'dart:io' as io;
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // UNE SEULE SOURCE POUR L'URL
  static const String baseUrl = 'http://192.168.1.14:8000/api';
  static const String chatbotUrl = 'http://192.168.1.14:5000';
  static const Duration timeout = Duration(seconds: 60);

  /// Password reset (Laravel)
  /// /// Route backend: POST /forgot-password
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl + '/forgot-password'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email}),
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message':
              data['message'] ?? 'Un email a été envoyé si l’adresse existe.',
        };
      }

      // Laravel: souvent 422 pour validation
      if (response.statusCode == 422) {
        return {'success': false, 'message': _extractValidationError(data)};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Erreur de réinitialisation',
      };
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  /// Centralized network error handler
  static Map<String, dynamic> _handleNetworkError(dynamic error) {
    String message;
    if (error is io.SocketException) {
      message =
          'Serveur inaccessible.\nVérifiez que le téléphone et le PC sont sur le même WiFi.';
    } else if (error is TimeoutException) {
      message =
          'Le serveur met trop de temps à répondre.\nVérifiez votre connexion ou réessayez.';
    } else {
      message = 'Erreur réseau: ' + error.toString();
    }
    return {'success': false, 'message': message};
  }

  /// FIX: Extract first validation error message from Laravel 422 response
  static String _extractValidationError(Map<String, dynamic> data) {
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final firstField = errors.values.first;
      if (firstField is List && firstField.isNotEmpty) {
        return firstField.first.toString();
      }
    }
    return data['message'] ?? 'Erreur de validation';
  }

  /// Étape 1 Flutter : Envoyer un PDF au médecin via multipart/form-data
  static Future<Map<String, dynamic>> sendPdfToDoctor({
    required String filePath, // chemin local du fichier PDF
    required int doctorId,
    required int patientId,
  }) async {
    try {
      final token = await getToken();

      // Créer la requête multipart
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(baseUrl + '/send-pdf'),
      );

      // Ajouter les headers d'authentification
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['Accept'] = 'application/json';
      }

      // Ajouter les champs texte
      request.fields['doctor_id'] = doctorId.toString();
      request.fields['patient_id'] = patientId.toString();

      // Ajouter le fichier PDF
      final file = await http.MultipartFile.fromPath(
        'pdf', // nom du champ côté Laravel
        filePath,
        contentType: MediaType('application', 'pdf'),
      );
      request.files.add(file);

      // Envoyer la requête avec timeout
      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);

      print('[SEND_PDF] status: ${response.statusCode}');
      print('[SEND_PDF] body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else if (response.statusCode == 422) {
        return {'success': false, 'message': _extractValidationError(data)};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'envoi du PDF',
        };
      }
    } catch (e) {
      print('[SEND_PDF] exception: $e');
      return _handleNetworkError(e);
    }
  }

  /// Récupérer les rapports PDF d'un médecin
  static Future<Map<String, dynamic>> getDoctorReports() async {
    return await get('/doctor/reports');
  }

  // MEDICATION
  static Future<Map<String, dynamic>> getMedications() async =>
      await get('/medications');
  static Future<Map<String, dynamic>> getTodayMedications() async =>
      await get('/medications/today');

  static Future<Map<String, dynamic>> addMedication({
    required int userId,
    required String name,
    required String dosage,
    required String frequency,
    required String reminderTime,
    String? notes,
    bool reportEnabled = false,
  }) async {
    final body = {
      'user_id': userId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'reminder_time': reminderTime,
      'notes': notes,
      'report_enabled': reportEnabled,
    };
    return await post('/medications', body);
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await getToken();
      final response = await http
          .patch(
            Uri.parse(baseUrl + endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  static Future<Map<String, dynamic>> addMedicationSchedule(
    int medicationId, {
    required String timeSlot,
    required String reminderTime,
    String? instructions,
  }) async =>
      await post('/medications/' + medicationId.toString() + '/schedules', {
        'time_slot': timeSlot,
        'reminder_time': reminderTime,
        'instructions': instructions,
      });
  static Future<Map<String, dynamic>> deleteSchedule(
    int medicationId,
    int scheduleId,
  ) async {
    try {
      final token = await getToken();
      final response = await http
          .delete(
            Uri.parse(
              baseUrl +
                  '/medications/' +
                  medicationId.toString() +
                  '/schedules/' +
                  scheduleId.toString(),
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer ' + token,
            },
          )
          .timeout(ApiConfig.timeout);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'data': data};
      } else if (response.statusCode == 422) {
        return {'success': false, 'message': _extractValidationError(data)};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  static Future<Map<String, dynamic>> updateMedication(
    int id, {
    String? name,
    String? dosage,
    String? frequency,
    String? reminderTime,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (dosage != null) body['dosage'] = dosage;
    if (frequency != null) body['frequency'] = frequency;
    if (reminderTime != null) body['reminder_time'] = reminderTime;
    if (notes != null) body['notes'] = notes;
    return await put('/medications/' + id.toString(), body);
  }

  static Future<Map<String, dynamic>> markMedicationTaken(int id) async =>
      await post('/medications/' + id.toString() + '/taken', {});
  static Future<Map<String, dynamic>> resetMedicationTaken(int id) async =>
      await post('/medications/' + id.toString() + '/reset', {});

  static Future<Map<String, dynamic>> deleteMedication(int id) async {
    try {
      final token = await getToken();
      final response = await http
          .delete(
            Uri.parse(baseUrl + '/medications/' + id.toString()),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer ' + token,
            },
          )
          .timeout(ApiConfig.timeout);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'data': data};
      } else if (response.statusCode == 422) {
        return {'success': false, 'message': _extractValidationError(data)};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  static Future<Map<String, dynamic>> getMedicationsForReport() async =>
      await get('/medications/report');

  // PDF HEALTH DATA
  static Future<Map<String, dynamic>> getHealthDataForPdf() async {
    try {
      final token = await getToken();
      final response = await http
          .get(
            Uri.parse('$baseUrl/pdf/health-data'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      print('Health data response: $data');

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data'] ?? data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> generatePdfReport({
    int? systolic,
    int? diastolic,
    int? glycemie,
    int? temperature,
    int? pulsations,
    int? oxygenie,
    String? date,
  }) async {
    final body = <String, dynamic>{};
    if (systolic != null) body['systolic'] = systolic;
    if (diastolic != null) body['diastolic'] = diastolic;
    if (glycemie != null) body['glycemie'] = glycemie;
    if (temperature != null) body['temperature'] = temperature;
    if (pulsations != null) body['pulsations'] = pulsations;
    if (oxygenie != null) body['oxygenie'] = oxygenie;
    if (date != null) body['date'] = date;
    return await post('/pdf/generate', body);
  }

  // HEALTH DATA
  static Future<Map<String, dynamic>> saveHealthData({
    int? userId,
    String? birthDate,
    int? systolic,
    int? diastolic,
    dynamic glycemie,
    int? oxygenie,
    double? temperature,
    int? pulsations,
    String? recordedAt,
    List<String>? symptoms,
  }) async {
    // Debug: helps understand why API may reject insertion
    // (remove later if needed)

    final body = <String, dynamic>{};

    if (userId != null) {
      body['user_id'] = userId;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.get('user_id');
      if (id != null) body['user_id'] = (id as num).toInt();
    }

    if (systolic != null && diastolic != null) {
      body['blood_pressure'] = "$systolic/$diastolic";
    }

    // Backend Laravel expects `birth_date` (snake_case) in request validation.
    // On insertion it maps to HealthData::birthDate.

    if (birthDate != null && birthDate.isNotEmpty) {
      body['birth_date'] = birthDate;
    }

    if (glycemie != null) body['glycemie'] = glycemie;
    if (oxygenie != null) body['oxygenie'] = oxygenie;
    if (temperature != null) body['temperature'] = temperature;
    if (pulsations != null) body['pulsations'] = pulsations;

    // symptoms (if backend has a column / json cast)
    if (symptoms != null && symptoms.isNotEmpty) {
      body['symptoms'] = symptoms;
    }

    // Helpful: send recorded date if backend expects it.
    // Laravel usually uses `created_at`, but your backend might map `recordedAt`.
    // We send `recordedAt` and also `created_at` to be safe.
    if (recordedAt != null) {
      body['recordedAt'] = recordedAt;
      body['created_at'] = recordedAt;
    }

    // helpful debug when backend rejects/ignores payload
    // print('[SAVE_HEALTH_DATA] body: $body');
    return await post('/health-data', body);
  }

  static Future<Map<String, dynamic>> getHealthHistory({int days = 7}) async {
    final result = await get('/health-data?days=' + days.toString());
    // Normaliser si data est une List
    if (result['success'] == true && result['data'] is List) {
      return {
        'success': true,
        'data': {
          'records': result['data'],
        }, // wrapper pour éviter les cast errors
      };
    }
    return result;
  }

  static Future<Map<String, dynamic>> getLatestHealthData() async =>
      await get('/health-data/latest');

  // CHATBOT
  static Future<Map<String, dynamic>> getChatSessions({String? query}) async {
    String endpoint = '/chat/history';
    if (query != null && query.isNotEmpty) {
      endpoint += '?query=' + Uri.encodeComponent(query);
    }
    return await get(endpoint);
  }

  static Future<Map<String, dynamic>> getChatSession(int sessionId) async =>
      await get('/chat/history/' + sessionId.toString());
  static Future<Map<String, dynamic>> createChatSession(
    String firstMessage,
  ) async => await post('/chat', {'message': firstMessage});

  static Future<Map<String, dynamic>> sendChatMessage(
    int sessionId,
    String message, {
    Map<String, dynamic>? healthData,
  }) async {
    try {
      final body = <String, dynamic>{
        'message': message,
        'session_id': sessionId,
      };
      if (healthData != null && healthData.isNotEmpty) {
        body['health_data'] = healthData;
      }
      final response = await http
          .post(
            Uri.parse(ApiConfig.chatbotUrl + '/chat'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': 'Erreur IA (' + response.statusCode.toString() + ')',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Serveur Python injoignable: ' + e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> sendChatMessageDirect(
    String message,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.chatbotUrl + '/chat'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'message': message}),
          )
          .timeout(ApiConfig.timeout);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': 'Erreur IA (' + response.statusCode.toString() + ')',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Serveur Python injoignable: ' + e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> shareChatSession(int sessionId) async =>
      await get('/chat/share/' + sessionId.toString());

  static Future<Map<String, dynamic>> deleteChatSession(int sessionId) async {
    try {
      final token = await getToken();
      final response = await http
          .delete(
            Uri.parse(baseUrl + '/chat/session/' + sessionId.toString()),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer ' + token,
            },
          )
          .timeout(ApiConfig.timeout);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'data': data};
      } else if (response.statusCode == 422) {
        return {'success': false, 'message': _extractValidationError(data)};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  // ==================== AUTH ====================

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      print('=== LOGIN RESPONSE ===');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Récupérer le token et l'utilisateur
        final token = data['token'];
        final user = data['user'];

        // Sauvegarder dans SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setInt('user_id', user['id']);
        await prefs.setString('user_name', user['name']);
        await prefs.setString('user_email', user['email']);
        await prefs.setString('user_role', user['role']);

        // ✅ CRUCIAL : Sauvegarder doctor_id
        if (user['doctor_id'] != null) {
          await prefs.setInt('doctor_id', user['doctor_id']);
          print('✅ Doctor ID saved: ${user['doctor_id']}');
        } else {
          print('⚠️ No doctor_id in response');
        }

        if (user['ipp'] != null) {
          await prefs.setString('ipp', user['ipp']);
        }

        return {'success': true, 'data': data, 'token': token, 'user': user};
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erreur de connexion',
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // ==================== DOCTOR PATIENT METHODS ====================

  /// Récupérer le médecin associé au patient connecté
  static Future<Map<String, dynamic>> getPatientDoctor() async {
    try {
      final token = await getToken();

      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/patient/doctor'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.timeout);

      print('[GET_PATIENT_DOCTOR] status: ${response.statusCode}');
      print('[GET_PATIENT_DOCTOR] body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['doctor'] ?? data['data'] ?? data,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Aucun médecin associé à ce patient',
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message':
              data['message'] ?? 'Erreur lors de la récupération du médecin',
        };
      }
    } catch (e) {
      print('[GET_PATIENT_DOCTOR] error: $e');
      return _handleNetworkError(e);
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl + '/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'password_confirmation': password,
            }),
          )
          .timeout(ApiConfig.timeout);

      // FIX: log pour débogage
      print('[REGISTER] status: ${response.statusCode}');
      print('[REGISTER] body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();

        // FIX: le token peut être dans data['token'] ou data['data']['token']
        final token = data['token'] ?? data['data']?['token'];
        if (token != null) {
          await prefs.setString('token', token.toString());
          await prefs.setString('user_name', name);
        }

        // FIX: user peut être dans data['user'] ou data['data']['user']
        final user = data['user'] ?? data['data']?['user'];
        if (user != null && user['id'] != null) {
          await prefs.setInt('user_id', (user['id'] as num).toInt());
        }

        // Save IPP
        final ipp = data['ipp'] ?? user?['ipp'];
        if (ipp != null) {
          await prefs.setString('ipp', ipp.toString());
        }

        // FIX: normaliser la réponse
        return {
          'success': true,
          'data': {
            'user': user ?? {'name': name},
            'token': token,
          },
        };
      } else if (response.statusCode == 422) {
        // FIX: Laravel retourne 422 pour email déjà utilisé, password trop court etc.
        return {'success': false, 'message': _extractValidationError(data)};
      } else if (response.statusCode == 409) {
        // FIX: 409 Conflict = email déjà existant sur certains backends
        return {
          'success': false,
          'message': data['message'] ?? 'Cet email est déjà utilisé',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur d\'inscription',
        };
      }
    } catch (e) {
      print('[REGISTER] exception: $e');
      return _handleNetworkError(e);
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('ipp');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('🔑 Getting token: ${token != null ? "Token exists" : "No token"}');
    return token;
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ==================== GENERIC HTTP ====================
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final token = await getToken();
      final response = await http
          .get(
            Uri.parse(baseUrl + endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ✅ Normaliser la réponse pour les recommandations
        if (data['success'] == true &&
            data['data'] is Map &&
            data['data']['data'] != null) {
          return {'success': true, 'data': data['data']['data']};
        }
        // ✅ Normaliser la réponse pour les autres endpoints
        if (data['success'] == true && data['data'] != null) {
          return {'success': true, 'data': data['data']};
        }
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expirée, reconnectez-vous',
        };
      } else if (response.statusCode == 422) {
        return {'success': false, 'message': _extractValidationError(data)};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur serveur',
        };
      }
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await getToken();
      final response = await http
          .post(
            Uri.parse(baseUrl + endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer ' + token,
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else if (response.statusCode == 422) {
        // FIX: gestion des erreurs de validation Laravel
        return {'success': false, 'message': _extractValidationError(data)};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expirée, reconnectez-vous',
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await getToken();
      final response = await http
          .put(
            Uri.parse(baseUrl + endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer ' + token,
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else if (response.statusCode == 422) {
        return {'success': false, 'message': _extractValidationError(data)};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expirée, reconnectez-vous',
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  // ==================== ARTICLES ====================

  /// Retourne la liste des articles (MedicalArticle) depuis `GET /articles`
  static Future<Map<String, dynamic>> fetchMedicalArticles() async {
    return await get('/articles');
  }

  // ==================== DOCTOR RECOMMENDATIONS ====================

  static Future<Map<String, dynamic>> fetchDoctorRecommendations() async {
    return await get('/recommendations');
  }

  static Future<Map<String, dynamic>> notifyDoctorOfRisk({
    required int dangerRate,
    required String severity,
    String? recommendedSpecialty,
    List<String>? symptoms,
    int? systolic,
    int? diastolic,
    int? glucose,
    int? temperature,
    int? pulse,
    int? oxygenSaturation,
  }) async {
    print('=== NOTIFICATION DOCTEUR ===');
    print('Danger rate: $dangerRate');
    print('Severity: $severity');

    final body = <String, dynamic>{
      'danger_rate': dangerRate,
      'severity': severity,
      'type': 'auto_alert',
    };

    if (recommendedSpecialty != null) {
      body['suggested_specialty'] = recommendedSpecialty;
    }
    if (symptoms != null && symptoms.isNotEmpty) {
      body['symptoms'] = symptoms;
    }
    if (systolic != null && diastolic != null) {
      body['blood_pressure'] = '$systolic/$diastolic';
    }
    if (glucose != null) body['glucose'] = glucose;
    if (temperature != null) body['temperature'] = temperature;
    if (pulse != null) body['pulse'] = pulse;
    if (oxygenSaturation != null) body['oxygen_saturation'] = oxygenSaturation;

    print('Body: $body');
    return await post('/recommendations/notify-doctor', body);
  }
  // ==================== DOCTOR / IPP FUNCTIONS ====================

  static Future<String> getOrGenerateIpp() async {
    final prefs = await SharedPreferences.getInstance();
    String? ipp = prefs.getString('ipp');

    if (ipp == null || ipp.isEmpty) {
      final year = DateTime.now().year;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      ipp = 'IPP-$year-${(timestamp % 10000).toString().padLeft(4, '0')}';
      await prefs.setString('ipp', ipp);
    }

    return ipp;
  }

  static Future<Map<String, dynamic>> registerDoctor({
    required String name,
    required String email,
    required String password,
    required String matricule,
    required String specialty,
    String? phone,
  }) async {
    final ipp = await getOrGenerateIpp();
    return await post('/doctors/register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
      'matricule': matricule,
      'specialty': specialty,
      'phone': phone,
      'ipp': ipp,
    });
  }

  static Future<Map<String, dynamic>> getDoctorAvailability(
    int doctorId,
  ) async {
    return await get('/doctors/' + doctorId.toString() + '/availability');
  }

  static Future<Map<String, dynamic>> updateDoctorAvailability({
    required int doctorId,
    required String status,
  }) async {
    return await put('/doctors/' + doctorId.toString() + '/availability', {
      'status': status,
    });
  }

  static Future<Map<String, dynamic>> getDoctorPatients() async {
    return await get('/doctors/patients');
  }

  static Future<Map<String, dynamic>> attachPatientToDoctor(
    String patientIpp,
  ) async {
    return await post('/doctors/patients/attach', {'patient_ipp': patientIpp});
  }

  static Future<Map<String, dynamic>> detachPatientFromDoctor(
    String patientIpp,
  ) async {
    try {
      final token = await getToken();
      final response = await http
          .delete(
            Uri.parse(baseUrl + '/doctors/patients/detach'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer ' + token,
            },
            body: jsonEncode({'patient_ipp': patientIpp}),
          )
          .timeout(ApiConfig.timeout);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'data': data};
      } else if (response.statusCode == 422) {
        return {'success': false, 'message': _extractValidationError(data)};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur'};
      }
    } catch (e) {
      return _handleNetworkError(e);
    }
  }

  static Future<Map<String, dynamic>> searchDoctors({
    String? specialty,
    String? query,
  }) async {
    String endpoint = '/doctors';
    final params = <String>[];
    if (specialty != null && specialty.isNotEmpty) {
      params.add('specialty=${Uri.encodeComponent(specialty)}');
    }
    if (query != null && query.isNotEmpty) {
      params.add('q=${Uri.encodeComponent(query)}');
    }
    if (params.isNotEmpty) {
      endpoint += '?' + params.join('&');
    }
    return await get(endpoint);
  }

  static Future<Map<String, dynamic>> getDoctorInfo(int doctorId) async {
    return await get('/doctors/' + doctorId.toString());
  }

  // ==================== AI ANALYSIS ====================

  static Future<Map<String, dynamic>> analyzeHealthData({
    required int systolic,
    required int diastolic,
    int? glucose,
    int? temperature,
    int? pulse,
    int? oxygenSaturation,
    List<String>? symptoms,
  }) async {
    try {
      final body = <String, dynamic>{
        "user_id": await getUserId() ?? 0,
        "blood_pressure": "$systolic/$diastolic",
        "glycemie": glucose,
        "oxygenie": oxygenSaturation,
        "temperature": temperature?.toDouble(),
        "pulsations": pulse,
        "symptoms": symptoms ?? [],
      };

      final response = await http
          .post(
            Uri.parse(ApiConfig.chatbotUrl + '/ai/analyze'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': 'Erreur IA (${response.statusCode})',
        };
      }
    } catch (e) {
      print('[ANALYZE] FastAPI unavailable, using local fallback: $e');
      return _localHealthAnalysis(
        systolic: systolic,
        diastolic: diastolic,
        glucose: glucose,
        temperature: temperature,
        pulse: pulse,
        oxygenSaturation: oxygenSaturation,
        symptoms: symptoms,
      );
    }
  }

  static Map<String, dynamic> _localHealthAnalysis({
    required int systolic,
    required int diastolic,
    int? glucose,
    int? temperature,
    int? pulse,
    int? oxygenSaturation,
    List<String>? symptoms,
  }) {
    int dangerRate = 0;
    String severity = 'normal';
    String? recommendedSpecialty;

    if (systolic > 180 || diastolic > 120) {
      dangerRate += 40;
      recommendedSpecialty = 'Cardiologue';
    } else if (systolic > 140 || diastolic > 90) {
      dangerRate += 20;
    }

    if (glucose != null) {
      if (glucose > 250 || glucose < 70) {
        dangerRate += 30;
        recommendedSpecialty = 'Endocrinologue';
      } else if (glucose > 126 || glucose < 80) {
        dangerRate += 15;
      }
    }

    if (temperature != null) {
      if (temperature > 39.5 || temperature < 35) {
        dangerRate += 25;
      } else if (temperature > 38 || temperature < 36) {
        dangerRate += 10;
      }
    }

    if (pulse != null) {
      if (pulse > 120 || pulse < 40) {
        dangerRate += 20;
        recommendedSpecialty = 'Cardiologue';
      } else if (pulse > 100 || pulse < 50) {
        dangerRate += 10;
      }
    }

    if (oxygenSaturation != null) {
      if (oxygenSaturation < 90) {
        dangerRate += 35;
        recommendedSpecialty = 'Pneumologue';
      } else if (oxygenSaturation < 95) {
        dangerRate += 15;
      }
    }

    if (symptoms != null && symptoms.isNotEmpty) {
      final criticalSymptoms = [
        'chest_pain',
        'shortness_breath',
        'dizziness',
        'severe_headache',
      ];
      final foundCritical = symptoms
          .where((s) => criticalSymptoms.contains(s))
          .length;
      dangerRate += foundCritical * 15;

      if (symptoms.contains('chest_pain')) {
        recommendedSpecialty = 'Cardiologue';
      } else if (symptoms.contains('shortness_breath')) {
        recommendedSpecialty = 'Pneumologue';
      } else if (symptoms.contains('headache') && dangerRate > 20) {
        recommendedSpecialty = 'Neurologue';
      }
    }

    if (dangerRate >= 60) {
      severity = 'alert';
    } else if (dangerRate >= 30) {
      severity = 'attention';
    }

    return {
      'success': true,
      'data': {
        'danger_rate': dangerRate.clamp(0, 100),
        'severity': severity,
        'recommended_specialty': recommendedSpecialty,
        'recommendations': _getRecommendations(
          dangerRate,
          severity,
          recommendedSpecialty,
        ),
      },
    };
  }

  static List<String> _getRecommendations(
    int dangerRate,
    String severity,
    String? specialty,
  ) {
    final recommendations = <String>[];

    if (severity == 'alert') {
      recommendations.add('Consultation médicale urgente recommandée');
      if (specialty != null) {
        recommendations.add('Contactez un spécialiste en $specialty');
      }
    } else if (severity == 'attention') {
      recommendations.add('Surveillez vos symptômes');
      recommendations.add('Contactez votre médecin traitant');
    } else {
      recommendations.add('Continuez à surveiller votre santé');
      recommendations.add('Maintenez une bonne hydratation');
    }

    return recommendations;
  }

  static Future<Map<String, dynamic>> analyzeSymptomsForSpecialty(
    List<String> symptoms,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.chatbotUrl + '/analyze-specialty'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'symptoms': symptoms}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Erreur IA'};
      }
    } catch (e) {
      return _localSpecialtyAnalysis(symptoms);
    }
  }

  static Map<String, dynamic> _localSpecialtyAnalysis(List<String> symptoms) {
    String specialty = 'Generaliste';
    int confidence = 50;

    final specialtyMap = <String, List<String>>{
      'Cardiologue': [
        'chest_pain',
        'palpitations',
        'shortness_breath',
        'fatigue',
      ],
      'Pneumologue': ['shortness_breath', 'cough', 'wheezing', 'sputum'],
      'Neurologue': ['headache', 'dizziness', 'seizures', 'numbness'],
      'Gastro-enterologue': [
        'nausea',
        'abdominal_pain',
        'diarrhea',
        'bloating',
      ],
      'Endocrinologue': ['fatigue', 'weight_change', 'thirst', 'hunger'],
      'Dermatologue': ['rash', 'itching', 'skin_change', 'lesions'],
      'Psychiatre': ['anxiety', 'depression', 'sleep_issue', 'mood'],
      'Pediatre': ['fever', 'cough', 'rash', 'vomiting'],
    };

    for (final entry in specialtyMap.entries) {
      final matchCount = symptoms.where((s) => entry.value.contains(s)).length;
      if (matchCount > 0 && matchCount * 20 > confidence) {
        specialty = entry.key;
        confidence = (matchCount * 20).clamp(50, 95);
      }
    }

    return {
      'success': true,
      'data': {'specialty': specialty, 'confidence': confidence},
    };
  }

  static Future<Map<String, dynamic>> fetchMedicalArticles2() async {
    try {
      final response = await get('/articles');
      return response;
    } catch (e) {
      return {'success': false, 'data': []};
    }
  }

  static Future<Map<String, dynamic>> fetchPatientNotifications() async {
    try {
      final token = await getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/api/patient/notifications'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
