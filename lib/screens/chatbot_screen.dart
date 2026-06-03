import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session.dart';
import 'chat_history_drawer.dart';
import '../widgets/chat_bubble.dart';
import '../services/language_service.dart';
import '../services/api_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  String _dynamicTitle = 'HealWise Assistant';
  Map<String, dynamic> _patientData = {};

  static const _primaryColor = Color.fromARGB(255, 23, 95, 114);

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _loadPatientData();
  }

  @override
  void dispose() {
    _saveSessions();
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'Patient';

    // FIX: on charge uniquement les valeurs réellement enregistrées
    // sans valeurs par défaut hardcodées qui fausseraient l'analyse IA
    final systolic = prefs.getInt('latest_systolic');
    final diastolic = prefs.getInt('latest_diastolic');
    final glycemie = prefs.getInt('latest_glucose');

    // ========== EL CORRECTION HEDHI ==========
    dynamic tempValue = prefs.get('latest_temperature');
    double? temperature;
    if (tempValue is int) {
      temperature = tempValue.toDouble();
    } else if (tempValue is double) {
      temperature = tempValue;
    }
    // ========================================

    final pulsations = prefs.getInt('latest_pulse');
    final oxygenie = prefs.getInt('latest_oxygen_saturation');
    final symptoms = prefs.getStringList('latest_symptoms');

    if (mounted) {
      setState(() {
        _patientData = {
          'name': name,
          if (systolic != null) 'systolic': systolic,
          if (diastolic != null) 'diastolic': diastolic,
          if (glycemie != null) 'glycemie': glycemie,
          if (temperature != null) 'temperature': temperature,
          if (pulsations != null) 'pulsations': pulsations,
          if (oxygenie != null) 'oxygen_saturation': oxygenie,
          if (symptoms != null && symptoms.isNotEmpty) 'symptoms': symptoms,
        };
      });
    }
  }

  // Rest of the code remains exactly the same...
  void _updateDynamicTitle(String responseText) {
    String newTitle = 'HealWise Assistant';
    if (responseText.contains('✅') || responseText.contains('ممتازة')) {
      newTitle = 'Analyse : Normale';
    } else if (responseText.contains('🚨') || responseText.contains('تحذير')) {
      newTitle = 'Alerte Santé !';
    } else if (responseText.contains('راحة') ||
        responseText.contains('repos')) {
      newTitle = 'Conseil : Repos';
    }

    if (mounted) {
      setState(() {
        _dynamicTitle = newTitle;
      });
    }
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getStringList('chat_sessions') ?? [];
    final List<ChatSession> loadedSessions = [];

    for (String jsonStr in sessionsJson) {
      try {
        final map = jsonDecode(jsonStr);
        loadedSessions.add(ChatSession.fromJson(map));
      } catch (e) {
        debugPrint('[CHAT] Failed to parse session: $e');
      }
    }

    if (mounted) {
      setState(() {
        _sessions = loadedSessions;
        if (loadedSessions.isNotEmpty) {
          _currentSession = loadedSessions.first;
          _messages = List<Map<String, dynamic>>.from(
            _currentSession!.messages,
          );
        } else {
          _newSession();
        }
      });
    }
  }

  Future<void> _saveSessions() async {
    if (_currentSession != null) {
      final idx = _sessions.indexWhere((s) => s.id == _currentSession!.id);
      if (idx != -1) {
        _sessions[idx] = _currentSession!;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final List<String> sessionsJson = _sessions
        .map((s) => jsonEncode(s.toJson()))
        .toList();
    await prefs.setStringList('chat_sessions', sessionsJson);
  }

  void _newSession() {
    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Nouvelle conversation',
      createdAt: DateTime.now(),
      messages: [],
    );
    if (mounted) {
      setState(() {
        _sessions.insert(0, newSession);
        _currentSession = newSession;
        _messages = [];
        _dynamicTitle = 'HealWise Assistant';
      });
    }
    _saveSessions();
    _sendWelcomeMessage();
  }

  Future<void> _sendWelcomeMessage() async {
    final name = _patientData['name'] as String? ?? 'Patient';
    final hasData =
        _patientData.containsKey('systolic') ||
        _patientData.containsKey('glucose') ||
        _patientData.containsKey('temperature');

    String welcomeText = 'Bonjour $name ! 👋\n\n';
    if (hasData) {
      welcomeText +=
          'Je suis votre assistant santé HealWise. J\'ai accès à vos dernières données de santé. Comment puis-je vous aider aujourd\'hui ?';
    } else {
      welcomeText +=
          'Je suis votre assistant santé HealWise. N\'hésitez pas à me parler de vos symptômes ou à me demander des conseils de santé.';
    }

    final aiMsg = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'message': welcomeText,
      'type': 'ai',
      'status': 'normal',
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (mounted) {
      setState(() {
        _messages.add(aiMsg);
        _currentSession?.messages.add(aiMsg);
      });
    }
    _saveSessions();
    _scrollToBottom();
  }

  void _selectSession(ChatSession session) {
    if (mounted) {
      Navigator.pop(context);
      setState(() {
        _currentSession = session;
        _messages = List<Map<String, dynamic>>.from(session.messages);
      });
      _scrollToBottom();
    }
  }

  void _deleteSession(String id) {
    if (!mounted) return;
    setState(() {
      _sessions.removeWhere((s) => s.id == id);
      if (_currentSession?.id == id) _newSession();
    });
    _saveSessions();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentSession == null) return;
    if (_isTyping) return;

    final userMsg = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'message': text,
      'type': 'user',
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (mounted) {
      setState(() {
        _messages.add(userMsg);
        _currentSession!.messages.add(userMsg);
        _messageController.clear();
        _isTyping = true;
      });
    }
    _scrollToBottom();

    final sessionId = int.tryParse(_currentSession!.id) ?? 0;
    final apiResult = await ApiService.sendChatMessage(
      sessionId,
      text,
      healthData: _patientData,
    );

    if (!mounted) return;

    String reply = 'Désolé, une erreur est survenue lors de l\'analyse.';
    String aiStatus = 'normal';

    if (apiResult['success'] == true) {
      reply = apiResult['data']['response'] ?? 'Analyse terminée.';
      aiStatus = apiResult['data']['alert_level'] ?? 'normal';
    } else {
      reply = apiResult['message'] ?? reply;
    }

    final aiMsg = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'message': reply,
      'type': 'ai',
      'status': aiStatus,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (mounted) {
      setState(() {
        _messages.add(aiMsg);
        _currentSession!.messages.add(aiMsg);
        _isTyping = false;
        _updateDynamicTitle(reply);

        if (_currentSession!.title == 'Nouvelle conversation') {
          _currentSession = ChatSession(
            id: _currentSession!.id,
            title: text.length > 30 ? '${text.substring(0, 30)}...' : text,
            createdAt: _currentSession!.createdAt,
            messages: _currentSession!.messages,
          );
          final idx = _sessions.indexWhere((s) => s.id == _currentSession!.id);
          if (idx != -1) _sessions[idx] = _currentSession!;
        }
      });
    }

    _saveSessions();
    _scrollToBottom();
  }

  void _scrollToBottom({bool delay = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Builder(
        builder: (context) => ChatHistoryDrawer(
          sessions: _sessions,
          onSelect: _selectSession,
          onDelete: _deleteSession,
          searchController: _searchController,
        ),
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          _dynamicTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
            onPressed: _newSession,
            tooltip: 'Nouvelle conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ChatBubble(
                          message: msg['message'] as String,
                          type: msg['type'] == 'user'
                              ? ChatMessageType.user
                              : ChatMessageType.ai,
                          timestamp: DateFormat(
                            'HH:mm',
                          ).format(DateTime.parse(msg['timestamp'] as String)),
                        ),
                      );
                    },
                  ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'HealWise analyse vos données...',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final name = _patientData['name'] as String? ?? 'Patient';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text(
            'Bonjour $name! 👋',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Votre assistant santé IA est prêt.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Parlez de votre santé...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: null,
                  enabled: !_isTyping,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageController,
              builder: (context, value, child) {
                final hasText = value.text.trim().isNotEmpty && !_isTyping;
                return FloatingActionButton(
                  onPressed: hasText ? _sendMessage : null,
                  mini: true,
                  backgroundColor: _primaryColor,
                  child: const Icon(Icons.send, color: Colors.white),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
