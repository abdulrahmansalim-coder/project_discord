import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> with SingleTickerProviderStateMixin {
  String _search = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Chat> get _filtered {
    final q = _search.toLowerCase();
    return sampleChats.where((c) {
      return c.displayName.toLowerCase().contains(q) ||
          (c.lastMessage?.content.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<Chat> get _pinned => _filtered.where((c) => c.isPinned).toList();
  List<Chat> get _allChats => _filtered.where((c) => !c.isPinned).toList();
  List<Chat> get _groups => _filtered.where((c) => c.isGroup).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Groups'),
              Tab(text: 'Unread'),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          SearchBar(
            onChanged: (v) => setState(() => _search = v),
            hintText: 'Search conversations…',
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(_pinned, _allChats),
                _buildSimpleList(_groups),
                _buildSimpleList(_filtered.where((c) => c.unreadCount > 0).toList()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        onPressed: () {},
      ),
    );
  }

  Widget _buildList(List<Chat> pinned, List<Chat> all) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        if (pinned.isNotEmpty) ...[
          _sectionHeader('Pinned'),
          ...pinned.map(_chatTile),
          _sectionHeader('All Messages'),
        ],
        ...all.map(_chatTile),
      ],
    );
  }

  Widget _buildSimpleList(List<Chat> chats) {
    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.textMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('Nothing here yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: chats.length,
      itemBuilder: (_, i) => _chatTile(chats[i]),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _chatTile(Chat chat) {
    final last = chat.lastMessage;
    final isToday = last != null &&
        last.timestamp.day == DateTime.now().day &&
        last.timestamp.month == DateTime.now().month;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            chat.isGroup
                ? GroupAvatar(participants: chat.participants)
                : UserAvatar(
                    avatarUrl: chat.displayAvatar,
                    status: chat.displayStatus,
                    size: 52,
                  ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (chat.isPinned)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.push_pin, size: 13, color: AppTheme.primary),
                        ),
                      Expanded(
                        child: Text(
                          chat.displayName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        last != null
                            ? isToday
                                ? '${last.timestamp.hour.toString().padLeft(2,'0')}:${last.timestamp.minute.toString().padLeft(2,'0')}'
                                : '${last.timestamp.day}/${last.timestamp.month}'
                            : '',
                        style: TextStyle(
                          color: chat.unreadCount > 0 ? AppTheme.primary : AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          last?.content ?? '',
                          style: TextStyle(
                            color: chat.unreadCount > 0 ? AppTheme.textSecondary : AppTheme.textMuted,
                            fontSize: 14,
                            fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (chat.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${chat.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
