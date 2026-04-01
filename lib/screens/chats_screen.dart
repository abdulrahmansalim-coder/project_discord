import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/conversations_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationsProvider>().load();
    });
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  List<dynamic> _filtered(List<dynamic> all) {
    if (_search.isEmpty) return all;
    final q = _search.toLowerCase();
    return all.where((c) {
      final name = _displayName(c).toLowerCase();
      final last = (c['last_message']?['content'] ?? '').toLowerCase();
      return name.contains(q) || last.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversationsProvider>();
    final all    = _filtered(provider.conversations);
    final groups = all.where((c) => c['type'] == 'group').toList();
    final unread = all.where((c) => (c['unread_count'] ?? 0) > 0).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text('Messages'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_square), onPressed: () {}),
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
            tabs: [Tab(text: 'All'), Tab(text: 'Groups'), Tab(text: 'Unread')],
          ),
        ),
      ),
      body: Column(children: [
        ChatSearchBar(onChanged: (v) => setState(() => _search = v), hintText: 'Search conversations…'),
        Expanded(
          child: provider.loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : provider.error != null
              ? _errorView(provider.error!, provider.load)
              : TabBarView(
                  controller: _tabController,
                  children: [_list(all), _list(groups), _list(unread)],
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        onPressed: () {},
      ),
    );
  }

  Widget _list(List<dynamic> chats) {
    if (chats.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.textMuted.withOpacity(0.4)),
        const SizedBox(height: 16),
        const Text('No conversations yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
      ]));
    }
    return RefreshIndicator(
      color: AppTheme.primary, backgroundColor: AppTheme.bgCard,
      onRefresh: () => context.read<ConversationsProvider>().load(),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: chats.length,
        itemBuilder: (_, i) => _tile(chats[i] as Map<String, dynamic>),
      ),
    );
  }

  Widget _tile(Map<String, dynamic> chat) {
    final last   = chat['last_message'] as Map<String, dynamic>?;
    final unread = int.parse((chat['unread_count'] ?? 0).toString());
    final isGroup = chat['type'] == 'group';
    final name   = _displayName(chat);
    final avatar = _displayAvatar(chat);
    final status = _displayStatus(chat);
    final lastTime = last != null ? DateTime.tryParse(last['created_at'] ?? '') : null;
    final isToday = lastTime != null && lastTime.day == DateTime.now().day;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversation: chat))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          isGroup ? _groupAvatar(chat['participants'] as List? ?? []) : _avatar(avatar, status),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16), overflow: TextOverflow.ellipsis)),
              if (lastTime != null) Text(
                isToday ? '${lastTime.hour.toString().padLeft(2,'0')}:${lastTime.minute.toString().padLeft(2,'0')}' : '${lastTime.day}/${lastTime.month}',
                style: TextStyle(color: unread > 0 ? AppTheme.primary : AppTheme.textMuted, fontSize: 12),
              ),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Text(last?['content'] ?? 'No messages yet',
                style: TextStyle(color: unread > 0 ? AppTheme.textSecondary : AppTheme.textMuted, fontSize: 14,
                  fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal),
                overflow: TextOverflow.ellipsis, maxLines: 1)),
              if (unread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                  child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _avatar(String url, String status) {
    Color statusColor = status == 'online' ? AppTheme.online : status == 'away' ? AppTheme.away : AppTheme.offline;
    return Stack(children: [
      CircleAvatar(radius: 26, backgroundColor: AppTheme.bgInput,
        backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
        child: url.isEmpty ? const Icon(Icons.person, color: AppTheme.textMuted) : null),
      Positioned(bottom: 1, right: 1, child: Container(width: 13, height: 13,
        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle,
          border: Border.all(color: AppTheme.bgDark, width: 2)))),
    ]);
  }

  Widget _groupAvatar(List parts) {
    return SizedBox(width: 52, height: 52, child: Stack(children: [
      if (parts.isNotEmpty) Positioned(top: 0, left: 0, child: CircleAvatar(radius: 18,
        backgroundImage: parts[0]['avatar_url'] != null ? NetworkImage(parts[0]['avatar_url']) : null,
        backgroundColor: AppTheme.primary)),
      if (parts.length > 1) Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18,
        backgroundImage: parts[1]['avatar_url'] != null ? NetworkImage(parts[1]['avatar_url']) : null,
        backgroundColor: AppTheme.accent)),
    ]));
  }

  Widget _errorView(String error, VoidCallback retry) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off, size: 52, color: AppTheme.textMuted),
      const SizedBox(height: 16),
      Text(error, style: const TextStyle(color: AppTheme.textMuted), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      TextButton(onPressed: retry, child: const Text('Retry', style: TextStyle(color: AppTheme.primary))),
    ]));
  }

  String _displayName(Map<String, dynamic> c) {
    if (c['type'] == 'group') return c['name'] ?? 'Group Chat';
    final parts = (c['participants'] as List?) ?? [];
    return parts.isNotEmpty ? (parts.first['name'] ?? 'Unknown') : 'Unknown';
  }

  String _displayAvatar(Map<String, dynamic> c) {
    final parts = (c['participants'] as List?) ?? [];
    return parts.isNotEmpty ? (parts.first['avatar_url'] ?? '') : '';
  }

  String _displayStatus(Map<String, dynamic> c) {
    final parts = (c['participants'] as List?) ?? [];
    return parts.isNotEmpty ? (parts.first['status'] ?? 'offline') : 'offline';
  }
}
