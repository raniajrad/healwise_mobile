import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme_config.dart';
import '../services/translation_service.dart';
import 'package:flutter/material.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.primaryColor;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Confidentialité'.translate(context),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: primaryColor,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(color: primaryColor),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              // ── Header Illustration ──────────────────────
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vos données sont protégées',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nous accordons une importance particulière à la confidentialité de vos données médicales',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Section 1: Description ──────────────────
              _SectionCard(
                title: '🔒 Stockage sécurisé',
                icon: Icons.storage_rounded,
                children: [
                  Text(
                    'privacy_data_storage'.translate(context),
                    style: textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      fontSize: 15,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Section 2: Encryption Status ────────────
              _SectionCard(
                title: 'Chiffrement des données',
                icon: Icons.lock_rounded,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'data_encryption_enabled'.translate(context),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.lock_rounded,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Toutes vos données sont chiffrées de bout en bout avec la norme AES-256',
                    style: textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Section 3: Data Collection ──────────────
              _SectionCard(
                title: 'Collecte des données',
                icon: Icons.data_usage_rounded,
                children: [
                  _InfoRow(
                    icon: Icons.check_circle_outline_rounded,
                    text: 'Données médicales (traitements, consultations)',
                    color: primaryColor,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.check_circle_outline_rounded,
                    text: 'Informations de profil (nom, email, téléphone)',
                    color: primaryColor,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.check_circle_outline_rounded,
                    text: 'Historique des rappels et notifications',
                    color: primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : primaryColor).withOpacity(
                        0.05,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isDark ? Colors.white : primaryColor)
                            .withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Nous ne partageons aucune donnée avec des tiers sans votre consentement',
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Section 4: Your Rights ──────────────────
              _SectionCard(
                title: 'Vos droits',
                icon: Icons.gavel_rounded,
                children: [
                  _InfoRow(
                    icon: Icons.visibility_rounded,
                    text: 'Droit d\'accès à vos données',
                    color: primaryColor,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.edit_rounded,
                    text: 'Droit de rectification',
                    color: primaryColor,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.delete_outline_rounded,
                    text: 'Droit à l\'effacement (RGPD)',
                    color: primaryColor,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.download_rounded,
                    text: 'Droit à la portabilité des données',
                    color: primaryColor,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Section 5: Contact Support ──────────────
              _SectionCard(
                title: 'Support technique',
                icon: Icons.support_agent_rounded,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.08),
                          primaryColor.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryColor.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.email_rounded,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'technical_support'.translate(context),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'support@healwise.tn',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Disponible 7j/7 de 9h à 18h',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: primaryColor,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Section 6: Last Update ──────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.update_rounded,
                      size: 14,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Dernière mise à jour : ${_getLastUpdateDate()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLastUpdateDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
}

// ═══════════════════════════════════════════════════════════════
//  Section Card Widget
// ═══════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? color;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.primaryColor;
    final usedColor = color ?? primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFFE2E8F0).withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        usedColor.withOpacity(0.15),
                        usedColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: usedColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Info Row Widget
// ═══════════════════════════════════════════════════════════════
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
