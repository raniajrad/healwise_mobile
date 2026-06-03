import 'package:intl/intl.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<Map<String, dynamic>> messages; // or separate model

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    this.messages = const [],
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      messages: List<Map<String, dynamic>>.from(json['messages'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'messages': messages,
  };

  String get preview => title.length > 50 ? '${title.substring(0, 50)}...' : title;
  
  String get dateLabel => DateFormat('MMM d, HH:mm').format(createdAt);
}
