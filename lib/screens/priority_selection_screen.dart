import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';
import '../config/theme_config.dart';

class PrioritySelectionScreen extends StatefulWidget {
  const PrioritySelectionScreen({super.key});

  @override
  State<PrioritySelectionScreen> createState() =>
      _PrioritySelectionScreenState();
}

class _PrioritySelectionScreenState extends State<PrioritySelectionScreen> {
  List<String> _priorityOrder = [];
  final List<Map<String, dynamic>> _allItems = [
    {'id': 'pouls', 'icon': Icons.favorite, 'color': Colors.red},
    {'id': 'tension', 'icon': Icons.speed, 'color': Colors.blue},
    {'id': 'glycemie', 'icon': Icons.water_drop, 'color': Colors.orange},
    {'id': 'temperature', 'icon': Icons.thermostat, 'color': Colors.purple},
    {'id': 'spo2', 'icon': Icons.air, 'color': Colors.cyan},
    {'id': 'statut', 'icon': Icons.mood, 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _loadPriority();
  }

  Future<void> _loadPriority() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrder = prefs.getStringList('health_priority_order');
    if (savedOrder != null && savedOrder.isNotEmpty) {
      setState(() {
        _priorityOrder = savedOrder;
      });
    } else {
      setState(() {
        _priorityOrder = _allItems.map((item) => item['id'] as String).toList();
      });
    }
  }

  Future<void> _savePriority() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('health_priority_order', _priorityOrder);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.get('priority_saved')),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  Future<void> _resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('health_priority_order');

    setState(() {
      _priorityOrder = _allItems.map((item) => item['id'] as String).toList();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTranslations.get('priority_reset')),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  String _getItemLabel(String id) {
    final labels = {
      'pouls': AppTranslations.get('heart_rate'),
      'tension': AppTranslations.get('blood_pressure'),
      'glycemie': AppTranslations.get('glucose'),
      'temperature': AppTranslations.get('temperature'),
      'spo2': 'SpO2',
      'statut': AppTranslations.get('health_status'),
    };
    return labels[id] ?? id;
  }

  IconData _getItemIcon(String id) {
    final item = _allItems.firstWhere(
      (item) => item['id'] == id,
      orElse: () => _allItems[0],
    );
    return item['icon'] as IconData;
  }

  Color _getItemColor(String id) {
    final item = _allItems.firstWhere(
      (item) => item['id'] == id,
      orElse: () => _allItems[0],
    );
    return item['color'] as Color;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.darkBackground : Colors.white;
    final cardColor = isDarkMode ? AppTheme.darkSurface : Color(0xFFF5F7FA);
    final textColor = isDarkMode ? Colors.white : Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: Text(
          AppTranslations.get('Personnaliser les priorités'),
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppTranslations.get('faites glisser pour réorganiser'),
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14),
            ),
          ),
          Expanded(
            child: ReorderableListView(
              children: _priorityOrder.map((id) {
                return Container(
                  key: Key(id),
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getItemColor(id).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getItemIcon(id),
                          color: _getItemColor(id),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        _getItemLabel(id),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.drag_handle,
                        color: textColor.withOpacity(0.4),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _priorityOrder.removeAt(oldIndex);
                  _priorityOrder.insert(newIndex, item);
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetToDefault,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppTranslations.get('réinitialiser par défaut'),
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _savePriority();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppTranslations.get('enregistrer la priorité'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
