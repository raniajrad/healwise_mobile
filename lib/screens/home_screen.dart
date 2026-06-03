import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../widgets/health_article_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/translation_service.dart';
import '../services/language_service.dart';
import 'manual_entry_screen.dart';
import 'chatbot_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import 'medication_screen.dart';
import 'login_screen.dart';
import 'article_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Patient';
  int _currentIndex = 0;
  // Health data from SharedPreferences
  String _tensionArterielle = '--';
  String _temperature = '--';
  String _glycemie = '--';
  String _pulsations = '--';
  String _oxygenie = '--';
  String _healthStatus = 'bien';
  String _recordDate = '';
  bool _isLoading = false;

  // Notifications patient
  int _patientNotificationsCount = 0;
  List<Map<String, dynamic>> _patientRecommendations = [];

  // Priority order for health metrics
  List<String> _priorityOrder = [
    'Tension artérielle',
    'glycemie',
    'temperature',
    'pulsations',
    'oxygenie',
    'statut',
  ];

  // Fallback articles
  final List<Map<String, dynamic>> _articlesFallback = [
    {
      'title': 'Hydratation',
      'subtitle': 'Conseils d’hydratation',
      'imageUrl':
          'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=400',
      'authorName': 'Dr.',
    },
    {
      'title': 'Sommeil',
      'subtitle': 'Bonnes habitudes de sommeil',
      'imageUrl':
          'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=400',
      'authorName': 'Dr.',
    },
  ];
  List<Map<String, dynamic>> _articles = [];

  @override
  void initState() {
    super.initState();
    LanguageService.onLocaleChanged = () {
      if (mounted) setState(() {});
    };
    _loadUserData();
    _loadPriorityOrder();
    _loadMedicalArticles();
    _loadPatientRecommendations();
  }

  // Charger les recommandations du patient
  Future<void> _loadPatientRecommendations() async {
    try {
      final result = await ApiService.get('/recommendations');
      print('RECOMMENDATIONS API RESPONSE: $result');

      if (result['success'] == true && result['data'] != null) {
        // ✅ CORRECTION : Vérifier si data est un Map avec une clé 'data'
        List dataList = [];

        if (result['data'] is Map && result['data']['data'] != null) {
          // Cas où l'API retourne {success: true, data: {success: true, data: [...]}}
          dataList = result['data']['data'] as List;
        } else if (result['data'] is List) {
          // Cas normal
          dataList = result['data'] as List;
        } else {
          print('Format de données inattendu: ${result['data']}');
          return;
        }

        setState(() {
          _patientRecommendations = dataList.cast<Map<String, dynamic>>();
          _patientNotificationsCount = dataList
              .where(
                (rec) =>
                    rec['status'] == 'validated' || rec['status'] == 'adjusted',
              )
              .length;
        });
        print('Nombre de recommandations: ${_patientRecommendations.length}');
      }
    } catch (e) {
      print('Erreur chargement recommandations: $e');
    }
  }

  // Afficher les recommandations du patient
  void _showPatientRecommendations(BuildContext context) async {
    await _loadPatientRecommendations();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '📋 Mes Recommandations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 23, 95, 114),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_patientRecommendations.length} recommandation(s) reçue(s)',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _patientRecommendations.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Aucune recommandation pour le moment',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _patientRecommendations.length,
                      itemBuilder: (context, index) {
                        final rec = _patientRecommendations[index];
                        final status = rec['status'];
                        final isNew = status == 'pending_review';
                        final doctorName = rec['doctor']?['name'] ?? 'Médecin';
                        final content =
                            rec['content'] ?? 'Recommandation médicale';
                        final dangerRate = rec['danger_rate'] ?? 0;

                        Color borderColor;
                        Color bgColor;
                        if (dangerRate >= 70) {
                          borderColor = Colors.red;
                          bgColor = Colors.red.shade50;
                        } else if (dangerRate >= 40) {
                          borderColor = Colors.orange;
                          bgColor = Colors.orange.shade50;
                        } else {
                          borderColor = Colors.green;
                          bgColor = Colors.green.shade50;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: borderColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.medical_services,
                                      color: borderColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Dr. $doctorName',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (dangerRate > 0)
                                          Text(
                                            '⚠️ Danger: $dangerRate%',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: borderColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isNew
                                          ? Colors.orange
                                          : Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isNew ? 'Nouvelle' : 'Lue',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                content,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '📅 ${rec['created_at']?.toString().substring(0, 10) ?? ''}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _loadMedicalArticles() async {
    if (mounted) {
      setState(() {
        _articles = _articlesFallback;
      });
    }

    final apiResult = await ApiService.fetchMedicalArticles();
    if (!mounted) return;

    if (apiResult['success'] == true) {
      final data = apiResult['data'];
      if (data is List) {
        final mapped = data.map<Map<String, dynamic>>((item) {
          final doctorName = item['doctor']?['name'] ?? item['doctor_name'];
          final image = item['image'];

          String imageUrl = '';
          if (image is String) {
            if (image.startsWith('http')) {
              imageUrl = image;
            } else if (image.startsWith('storage/')) {
              imageUrl =
                  ApiService.baseUrl +
                  '/storage/' +
                  image.substring('storage/'.length);
            } else if (image.startsWith('/storage/')) {
              imageUrl = ApiService.baseUrl + image;
            } else {
              imageUrl = ApiService.baseUrl + '/storage/' + image;
            }
          }
          return {
            'title': item['title']?.toString() ?? '',
            'subtitle': item['category']?.toString() ?? '',
            'imageUrl': imageUrl,
            'authorName': doctorName?.toString() ?? 'Médecin',
            'content':
                item['content']?.toString() ??
                item['description']?.toString() ??
                'Aucun contenu disponible',
            'created_at': item['created_at']?.toString() ?? '',
          };
        }).toList();

        if (mapped.isNotEmpty) {
          setState(() {
            _articles = mapped;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    LanguageService.onLocaleChanged = null;
    super.dispose();
  }

  Future<void> _loadPriorityOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrder = prefs.getStringList('health_priority_order');
    if (savedOrder != null && savedOrder.isNotEmpty) {
      setState(() {
        _priorityOrder = savedOrder;
      });
    } else {
      setState(() {
        _priorityOrder = [
          'Tension artérielle',
          'glycemie',
          'temperature',
          'pulsations',
          'oxygenie',
          'statut',
        ];
      });
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Vérifier si l'utilisateur a déjà des données
    final hasData =
        prefs.containsKey('latest_systolic') ||
        prefs.containsKey('latest_diastolic') ||
        prefs.containsKey('latest_glycemie') ||
        prefs.containsKey('latest_temperature') ||
        prefs.containsKey('latest_pulse');

    final savedStatus = prefs.getString('latest_status');
    final systolic = prefs.getInt('latest_systolic');
    final diastolic = prefs.getInt('latest_diastolic');
    final temperature = prefs.getInt('latest_temperature');
    final glycemie = prefs.getInt('latest_glycemie');
    final pulsations = prefs.getInt('latest_pulse');
    final oxygenie = prefs.getInt('latest_oxygenie');
    final recordDate = prefs.getString('latest_record_date') ?? '';

    setState(() {
      _userName = prefs.getString('user_name') ?? 'Patient';
      _recordDate = recordDate;

      if (!hasData) {
        // ✅ Aucune donnée - Afficher "Aucune mesure"
        _healthStatus = 'no_data';
        _tensionArterielle = '--';
        _temperature = '--';
        _glycemie = '--';
        _pulsations = '--';
        _oxygenie = '--';
      } else {
        // ✅ L'utilisateur a des données
        _healthStatus = savedStatus ?? 'bien';

        if (systolic != null && diastolic != null) {
          _tensionArterielle = '$systolic/$diastolic mmHg';
        }
        if (temperature != null) {
          _temperature = '${temperature.toStringAsFixed(1)}°C';
        }
        _glycemie = glycemie != null ? '$glycemie mg/dL' : '--';
        _pulsations = pulsations != null ? '$pulsations bpm' : '--';
        _oxygenie = oxygenie != null ? '$oxygenie%' : '--';
      }
    });
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showArticleDialog(Map<String, dynamic> article) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image
              if (article['imageUrl'] != null &&
                  article['imageUrl']!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    article['imageUrl']!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              // Contenu
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article['title'] ?? 'Article',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        article['subtitle'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const Divider(height: 20),
                      Text(
                        article['content'] ?? 'Aucun contenu',
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              // Bouton fermer
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
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
      setState(() => _isLoading = true);

      try {
        await ApiService.logout();

        final prefs = await SharedPreferences.getInstance();

        await prefs.clear();

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        _snack('Erreur lors de la déconnexion: $e', error: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ManualEntryScreen()),
        ).then((_) => _loadUserData());
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatbotScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MedicationScreen()),
        ).then((_) => _loadUserData());
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  Color _getStatusColor() {
    switch (_healthStatus.toLowerCase()) {
      case 'alert':
        return Colors.red;
      case 'attention':
        return const Color(0xFFF59E0B);
      case 'no_data':
        return const Color.fromARGB(255, 77, 55, 2);
      default:
        return Colors.green;
    }
  }

  IconData _getStatusIcon() {
    switch (_healthStatus.toLowerCase()) {
      case 'alert':
        return Icons.warning_rounded;
      case 'attention':
        return Icons.info_outline_rounded;
      case 'no_data':
        return Icons.add_circle_outline;
      default:
        return Icons.check_circle_rounded;
    }
  }

  String _getStatusText() {
    switch (_healthStatus.toLowerCase()) {
      case 'alert':
        return 'État critique - Consultez un médecin';
      case 'attention':
        return 'État à surveiller - Paramètres anormaux';
      case 'no_data':
        return 'Aucune donnée - Ajoutez votre première mesure';
      default:
        return 'État stable - Tout va bien';
    }
  }

  bool _isValueAbnormal(String statId, String value) {
    if (value == '--' || value.isEmpty) return false;

    switch (statId) {
      case 'Tension artérielle':
        final bpValue = value.replaceAll(' mmHg', '').split('/');
        if (bpValue.length == 2) {
          final sys = int.tryParse(bpValue[0]) ?? 0;
          final dia = int.tryParse(bpValue[1]) ?? 0;
          return sys > 140 || dia > 90 || sys < 90 || dia < 60;
        }
        return false;

      case 'glycemie':
        final glu = int.tryParse(value.replaceAll(' mg/dL', '')) ?? 0;
        return glu > 126 || glu < 70;

      case 'temperature':
        final temp = double.tryParse(value.replaceAll('°C', '')) ?? 0;
        return temp > 37.5 || temp < 36.0;

      case 'pulsations':
        final pulse = int.tryParse(value.replaceAll(' bpm', '')) ?? 0;
        return pulse > 100 || pulse < 60;

      case 'oxygenie':
        final oxy = int.tryParse(value.replaceAll('%', '')) ?? 0;
        return oxy < 95;

      default:
        return false;
    }
  }

  Color _getValueColor(String statId, String value) {
    if (_isValueAbnormal(statId, value)) {
      if (_healthStatus == 'alert') return Colors.red;
      return const Color(0xFFF59E0B);
    }
    return Colors.green;
  }

  String _getWarningText(String statId, String value) {
    if (!_isValueAbnormal(statId, value)) return '';

    switch (statId) {
      case 'Tension artérielle':
        final bpValue = value.replaceAll(' mmHg', '').split('/');
        if (bpValue.length == 2) {
          final sys = int.tryParse(bpValue[0]) ?? 0;
          final dia = int.tryParse(bpValue[1]) ?? 0;
          if (sys > 180 || dia > 120) return 'CRITIQUE';
          if (sys > 140 || dia > 90) return 'ÉLEVÉE';
          if (sys < 90 || dia < 60) return 'BASSE';
        }
        return 'ANORMAL';

      case 'glycemie':
        final glu = int.tryParse(value.replaceAll(' mg/dL', '')) ?? 0;
        if (glu > 200) return 'TRÈS ÉLEVÉE';
        if (glu > 126) return 'ÉLEVÉE';
        if (glu < 70) return 'BASSE';
        return 'ANORMAL';

      case 'temperature':
        final temp = double.tryParse(value.replaceAll('°C', '')) ?? 0;
        if (temp > 39) return 'FORTE FIÈVRE';
        if (temp > 37.5) return 'FIÈVRE';
        if (temp < 36.0) return 'BASSE';
        return 'ANORMAL';

      case 'pulsations':
        final pulse = int.tryParse(value.replaceAll(' bpm', '')) ?? 0;
        if (pulse > 120) return 'TACHYCARDIE SÉVÈRE';
        if (pulse > 100) return 'TACHYCARDIE';
        if (pulse < 40) return 'BRADYCARDIE SÉVÈRE';
        if (pulse < 60) return 'BRADYCARDIE';
        return 'ANORMAL';

      case 'oxygenie':
        final oxy = int.tryParse(value.replaceAll('%', '')) ?? 0;
        if (oxy < 90) return 'DÉSATURATION SÉVÈRE';
        if (oxy < 95) return 'DÉSATURATION';
        return 'ANORMAL';

      default:
        return 'ANORMAL';
    }
  }

  Map<String, dynamic> _getStatData(String id) {
    switch (id) {
      case 'pulsations':
        return {
          'icon': Icons.favorite,
          'value': _pulsations,
          'label': 'Pulsations',
          'color': Colors.red,
        };
      case 'Tension artérielle':
        return {
          'icon': Icons.bloodtype,
          'value': _tensionArterielle,
          'label': 'Tension artérielle',
          'color': Colors.blue,
        };
      case 'glycemie':
        return {
          'icon': Icons.water_drop,
          'value': _glycemie,
          'label': 'Glycémie',
          'color': Colors.orange,
        };
      case 'temperature':
        return {
          'icon': Icons.thermostat,
          'value': _temperature,
          'label': 'Température',
          'color': const Color.fromARGB(255, 228, 30, 211),
        };
      case 'statut':
        return {
          'icon': Icons.health_and_safety,
          'value': _healthStatus,
          'label': 'Statut',
          'color': _healthStatus == 'bien' ? Colors.green : Colors.red,
        };
      case 'date':
        return {
          'icon': Icons.calendar_month,
          'value': _recordDate,
          'label': 'Date',
          'color': Colors.grey,
        };
      default:
        return {
          'icon': Icons.air,
          'value': _oxygenie,
          'label': 'Oxygène',
          'color': Colors.cyan,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color.fromARGB(255, 23, 95, 114),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ),
            actions: [
              // ✅ Icône UNIQUE pour les recommandations du médecin
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.medical_services_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () => _showPatientRecommendations(context),
                    tooltip: 'Mes recommandations',
                  ),
                  if (_patientNotificationsCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$_patientNotificationsCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 23, 95, 114),
                      Color.fromARGB(255, 23, 95, 114),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          AppTranslations.translate(
                            context,
                            'welcome_back_user',
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(),
                                color: _getStatusColor(),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getStatusText(),
                                style: TextStyle(
                                  color: _getStatusColor(),
                                  fontSize: 12,
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
          if (_healthStatus == 'no_data')
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color.fromARGB(255, 77, 55, 2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color.fromARGB(255, 77, 55, 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenue sur HealWise !',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 23, 95, 114),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ajoutez votre première mesure de santé pour voir votre état.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromARGB(255, 23, 95, 114),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ManualEntryScreen(),
                          ),
                        ).then((_) => _loadUserData());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 23, 95, 114),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
              ),
            ),

          // ==================== ACTIONS RAPIDES ====================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppTranslations.translate(context, 'Actions rapides'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AnalyticsScreen(),
                            ),
                          );
                        },
                        child: Text(
                          AppTranslations.translate(
                            context,
                            'voir-les détails',
                          ),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _priorityOrder.length,
                      itemBuilder: (context, index) {
                        final statId = _priorityOrder[index];
                        final statData = _getStatData(statId);
                        final value = statData['value'] as String;
                        final isAbnormal = _isValueAbnormal(statId, value);
                        final valueColor = _getValueColor(statId, value);
                        final warningText = _getWarningText(statId, value);

                        String shortLabel = statData['label'];
                        if (shortLabel == 'Tension artérielle') {
                          shortLabel = 'Tension';
                        } else if (shortLabel == 'Fréquence cardiaque') {
                          shortLabel = 'Cardiaque';
                        } else if (shortLabel == 'Saturation Oxygène') {
                          shortLabel = 'SpO₂';
                        }

                        return Container(
                          width: 95,
                          margin: EdgeInsets.only(
                            right: index < _priorityOrder.length - 1 ? 6 : 0,
                          ),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isAbnormal
                                ? valueColor.withOpacity(0.1)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isAbnormal
                                  ? valueColor
                                  : Colors.grey.shade200,
                              width: isAbnormal ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: valueColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  statData['icon'],
                                  color: valueColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                shortLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                value != '--' ? value : '---',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: valueColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (warningText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    warningText,
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w600,
                                      color: valueColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppTranslations.translate(context, 'Articles de santé'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 3, 3, 5),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      AppTranslations.translate(context, 'voir_tous'),
                      style: const TextStyle(
                        color: Color.fromARGB(255, 23, 95, 114),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _articles.length,
                itemBuilder: (context, index) {
                  final article = _articles[index];
                  return GestureDetector(
                    onTap: () {
                      final articleTitle = article['title']?.toString() ?? '';
                      final articleContent =
                          article['content']?.toString() ?? '';
                      final articleCategory =
                          article['subtitle']?.toString() ?? '';
                      final articleAuthor =
                          article['authorName']?.toString() ?? '';
                      final articleDate =
                          article['created_at']?.toString() ?? '';
                      final articleImage = article['imageUrl']?.toString();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleDetailScreen(
                            title: articleTitle,
                            content: articleContent,
                            category: articleCategory,
                            author: articleAuthor,
                            date: articleDate,
                            imageUrl: articleImage,
                          ),
                        ),
                      );
                    },
                    child: HealthArticleCard(
                      title: (article['title']?.toString().isNotEmpty ?? false)
                          ? article['title'].toString()
                          : (article['titleKey']?.toString() ?? ''),
                      subtitle:
                          (article['subtitle']?.toString().isNotEmpty ?? false)
                          ? article['subtitle'].toString()
                          : (article['subtitleKey']?.toString() ?? ''),
                      imageUrl: article['imageUrl']?.toString() ?? '',
                      author: article['authorName']?.toString() ?? '',
                      onTap:
                          () {}, // Laisser vide car on utilise GestureDetector
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.translate(context, 'Activité récente'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 15, 15, 18),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ✅ Vérifier si l'utilisateur a des données
                  if (_healthStatus == 'no_data')
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune activité pour le moment',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ajoutez votre première mesure de santé',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ManualEntryScreen(),
                                ),
                              ).then((_) => _loadUserData());
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Ajouter une mesure'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                23,
                                95,
                                114,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // ✅ Afficher les données si elles existent
                    Column(
                      children: [
                        for (int i = 0; i < _priorityOrder.length && i < 5; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Builder(
                              builder: (context) {
                                final statId = _priorityOrder[i];
                                final statData = _getStatData(statId);
                                final value = statData['value'] as String;
                                final isAbnormal = _isValueAbnormal(
                                  statId,
                                  value,
                                );
                                final valueColor = _getValueColor(
                                  statId,
                                  value,
                                );
                                final warningText = _getWarningText(
                                  statId,
                                  value,
                                );
                                final statusText = isAbnormal
                                    ? "⚠️ Anormal"
                                    : "✓ Normal";

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isAbnormal
                                        ? valueColor.withOpacity(0.05)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isAbnormal
                                          ? valueColor.withOpacity(0.3)
                                          : Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: valueColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          statData['icon'],
                                          color: valueColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              statData['label'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color.fromARGB(
                                                  255,
                                                  23,
                                                  95,
                                                  114,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text(
                                                  value != '--' ? value : '---',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: valueColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isAbnormal
                                                        ? valueColor
                                                              .withOpacity(0.2)
                                                        : const Color.fromARGB(
                                                            255,
                                                            79,
                                                            56,
                                                            3,
                                                          ).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    statusText,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isAbnormal
                                                          ? valueColor
                                                          : const Color.fromARGB(
                                                              255,
                                                              6,
                                                              159,
                                                              18,
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (warningText.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  warningText,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: valueColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Icon(
                                            isAbnormal
                                                ? Icons.warning_rounded
                                                : Icons.check_circle_rounded,
                                            color: isAbnormal
                                                ? valueColor
                                                : const Color.fromARGB(
                                                    255,
                                                    8,
                                                    186,
                                                    79,
                                                  ),
                                            size: 16,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _recordDate.isNotEmpty
                                                ? _recordDate
                                                : '--',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

// ==================== CLASSES EXISTANTES ====================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String time;
  const _ActivityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.time,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
