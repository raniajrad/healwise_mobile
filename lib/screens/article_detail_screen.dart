import 'package:flutter/material.dart';

class ArticleDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final String category;
  final String author;
  final String date;
  final String? imageUrl;

  const ArticleDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.category,
    required this.author,
    required this.date,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        backgroundColor: const Color.fromARGB(255, 23, 95, 114),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Meta info (author, category, date)
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildMetaInfo(Icons.person_outline, author),
                _buildMetaInfo(Icons.category_outlined, category),
                _buildMetaInfo(Icons.calendar_today, date),
              ],
            ),
            const Divider(height: 24),

            // Content
            Text(
              content.isNotEmpty
                  ? content
                  : 'Aucun contenu disponible pour le moment.',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text.isNotEmpty ? text : 'Non spécifié',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
