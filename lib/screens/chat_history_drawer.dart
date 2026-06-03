import 'package:flutter/material.dart';
import '../models/chat_session.dart';
import 'package:share_plus/share_plus.dart';

class ChatHistoryDrawer extends StatefulWidget {
  final List<ChatSession> sessions;
  final Function(ChatSession) onSelect;
  final Function(String) onDelete;
  final TextEditingController searchController;

  const ChatHistoryDrawer({
    super.key,
    required this.sessions,
    required this.onSelect,
    required this.onDelete,
    required this.searchController,
  });
  @override
  State<ChatHistoryDrawer> createState() => _ChatHistoryDrawerState();
}

class _ChatHistoryDrawerState extends State<ChatHistoryDrawer> {
  List<ChatSession> filteredSessions = [];

  @override
  void initState() {
    super.initState();
    filteredSessions = widget.sessions;
    widget.searchController.addListener(_filterSessions);
  }

  void _filterSessions() {
    final query = widget.searchController.text.toLowerCase();
    setState(() {
      filteredSessions = widget.sessions.where((session) {
        return session.title.toLowerCase().contains(query) ||
            session.preview.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_filterSessions);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 14, 83, 110),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color.fromARGB(255, 23, 95, 114),
                  child: Icon(Icons.chat, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Historique des discussions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${widget.sessions.length} conversations',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          // Search
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: widget.searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Sessions list
          Expanded(
            child: filteredSessions.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune conversation trouvée',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredSessions.length,
                    itemBuilder: (context, index) {
                      final session = filteredSessions[index];
                      final isActive = widget.sessions.indexOf(session) == 0;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: isActive
                            ? const Color(0xFFF3F4F6)
                            : Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xFF1F2937,
                            ).withOpacity(0.1),
                            child: Text(
                              session.title.isNotEmpty
                                  ? session.title[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            session.title,
                            style: TextStyle(
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              session.dateLabel,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.grey,
                            ),
                            onSelected: (value) {
                              switch (value) {
                                case 'share':
                                  Share.share(
                                    'Conversation: ${session.title}\n${session.preview}',
                                    subject: 'Ma discussion Healwise',
                                  );
                                  break;
                                case 'delete':
                                  widget.onDelete(session.id);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'share',
                                child: Row(
                                  children: [
                                    Icon(Icons.share, color: Colors.green),
                                    const SizedBox(width: 12),
                                    const Text('Partager'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    const SizedBox(width: 12),
                                    const Text('Supprimer'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => widget.onSelect(session),
                        ),
                      );
                    },
                  ),
          ),
          // New chat button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: Navigator.of(context).pop,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle conversation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 23, 95, 114),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
