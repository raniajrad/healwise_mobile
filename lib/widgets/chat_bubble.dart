import 'package:flutter/material.dart';
import '../services/translation_service.dart';

enum ChatMessageType { user, ai }

class ChatBubble extends StatelessWidget {
  final String message;
  final ChatMessageType type;
  final String? timestamp;

  const ChatBubble({
    super.key,
    required this.message,
    required this.type,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = type == ChatMessageType.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: isUser ? 48 : 16,
          right: isUser ? 16 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color.fromARGB(255, 16, 75, 105) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      size: 16,
                      color: const Color.fromARGB(255, 23, 95, 114),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppTranslations.translate(context, 'health_assistant'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: const Color.fromARGB(255, 23, 95, 114),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 4),
              Text(
                timestamp!,
                style: TextStyle(
                  fontSize: 10,
                  color: isUser
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Chat message model for history
class ChatMessage {
  final String id;
  final String message;
  final ChatMessageType type;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.message,
    required this.type,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      message: json['message'],
      type: json['type'] == 'user' ? ChatMessageType.user : ChatMessageType.ai,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'type': type == ChatMessageType.user ? 'user' : 'ai',
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// Chat group by date
class ChatDateGroup {
  final String dateLabel;
  final List<ChatMessage> messages;

  ChatDateGroup({required this.dateLabel, required this.messages});
}
