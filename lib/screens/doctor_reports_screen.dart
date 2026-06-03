import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

/// Étape 4 Flutter : Dashboard médecin — liste des rapports PDF reçus
class DoctorReportsScreen extends StatefulWidget {
  const DoctorReportsScreen({super.key});

  @override
  State<DoctorReportsScreen> createState() => _DoctorReportsScreenState();
}

class _DoctorReportsScreenState extends State<DoctorReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const _primaryColor = Color.fromARGB(255, 23, 95, 114);

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getDoctorReports();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        // Le backend retourne une liste
        _reports = List<Map<String, dynamic>>.from(data as List);
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Erreur lors du chargement';
      });
    }
  }

  /// Ouvrir le PDF dans le navigateur (ou l'app PDF du téléphone)
  Future<void> _openPdf(String pdfUrl) async {
    final uri = Uri.parse(pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir le PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Marquer le rapport comme lu
  Future<void> _markAsRead(int reportId, int index) async {
    try {
      // ✅ Utiliser patch au lieu de post
      final result = await ApiService.patch(
        '/doctor/reports/$reportId/read',
        {},
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _reports[index]['status'] = 'lu';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rapport marqué comme lu'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Rapports Patients',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        actions: [
          // Bouton actualiser
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadReports,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Chargement
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    // Erreur
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReports,
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              child: const Text(
                'Réessayer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    // Liste vide
    if (_reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun rapport reçu pour l\'instant',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Liste des rapports
    return RefreshIndicator(
      onRefresh: _loadReports,
      color: _primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          return _buildReportCard(_reports[index], index);
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, int index) {
    final isUnread = report['status'] == 'non_lu';
    final patientName = report['patient_name'] ?? 'Patient inconnu';
    final createdAt = report['created_at'] ?? '';
    final pdfUrl = report['pdf_url'] ?? '';
    final type = report['type'] ?? 'SUIVI';
    final reportId = report['id'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnread ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Bordure bleue si non lu
        side: isUnread
            ? const BorderSide(color: _primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icône PDF
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: _primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              patientName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          // Badge non lu
                          if (isUnread)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Nouveau',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Type : $type · $createdAt',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      // Dans le Drawer ou Menu principal
                      ListTile(
                        leading: const Icon(Icons.picture_as_pdf),
                        title: const Text('Rapports Patients'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DoctorReportsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Bouton ouvrir PDF
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: pdfUrl.isNotEmpty
                        ? () => _openPdf(pdfUrl)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Ouvrir PDF'),
                  ),
                ),
                const SizedBox(width: 8),
                // Bouton marquer comme lu (si non lu)
                if (isUnread)
                  OutlinedButton.icon(
                    onPressed: () => _markAsRead(reportId, index),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: const BorderSide(color: _primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Marquer lu'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
