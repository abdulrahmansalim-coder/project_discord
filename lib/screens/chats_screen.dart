import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/conversations_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'chat_screen.dart';
import 'create_group_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});
  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>
    with SingleTickerProviderStateMixin {
  String _search = '';
  String _myId   = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _myId = context.read<AuthProvider>().user?['id'].toString() ?? '';
      context.read<ConversationsProvider>().load();
    });
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Map<String, dynamic>? _other(Map<String, dynamic> c) {
    if (c['type'] == 'group') return null;
    final parts = (c['participants'] as List?) ?? [];
    final others = parts.where((p) => (p as Map)['id'].toString() != _myId).toList();
    return others.isNotEmpty ? Map<String, dynamic>.from(others.first as Map) : null;
  }

  String _displayName(Map<String, dynamic> c) {
    if (c['type'] == 'group') return c['name'] ?? 'Group Chat';
    return _other(c)?['name'] ?? 'Unknown';
  }

  String _displayAvatar(Map<String, dynamic> c) {
    if (c['type'] == 'group') return c['avatar_url'] ?? '';
    return _other(c)?['avatar_url'] ?? '';
  }

  String _displayStatus(Map<String, dynamic> c) {
    if (c['type'] == 'group') return 'offline';
    return _other(c)?['status'] ?? 'offline';
  }

  List<dynamic> _filtered(List<dynamic> all) {
    if (_search.isEmpty) return all;
    final q = _search.toLowerCase();
    return all.where((c) {
      final chat = Map<String, dynamic>.from(c as Map);
      return _displayName(chat).toLowerCase().contains(q) ||
          (chat['last_message']?['content'] ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg     = theme.scaffoldBackgroundColor;
    final cardBg = theme.cardColor;

    final authUser = context.watch<AuthProvider>().user;
    if (authUser != null && _myId.isEmpty) {
      _myId = authUser['id'].toString();
    }

    final provider = context.watch<ConversationsProvider>();
    final all    = _filtered(provider.conversations);
    final groups = all.where((c) => (c as Map)['type'] == 'group').toList();
    final unread = all.where((c) => int.parse(((c as Map)['unread_count'] ?? 0).toString()) > 0).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Messages', style: TextStyle(color: theme.colorScheme.onBackground)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_square, color: theme.colorScheme.onBackground),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: isDark ? AppTheme.textMuted : AppTheme.textMutedLight,
            indicatorColor: AppTheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [Tab(text: 'All'), Tab(text: 'Groups'), Tab(text: 'Unread')],
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
                  children: [_list(all, isDark), _list(groups, isDark), _list(unread, isDark)],
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.edit_outlined, color: Colors.white),
        onPressed: () => _showNewChatOptions(context),
      ),
    );
  }

  Widget _list(List<dynamic> chats, bool isDark) {
    if (chats.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.chat_bubble_outline, size: 64,
          color: (isDark ? AppTheme.textMuted : AppTheme.textMutedLight).withOpacity(0.4)),
        const SizedBox(height: 16),
        Text('No conversations yet',
          style: TextStyle(color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight, fontSize: 16)),
      ]));
    }
    return RefreshIndicator(
      color: AppTheme.primary,
      backgroundColor: Theme.of(context).cardColor,
      onRefresh: () => context.read<ConversationsProvider>().load(),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: chats.length,
        itemBuilder: (_, i) => _tile(Map<String, dynamic>.from(chats[i] as Map), isDark),
      ),
    );
  }

  Widget _tile(Map<String, dynamic> chat, bool isDark) {
    final textPri = isDark ? AppTheme.textPrimary   : AppTheme.textPrimaryLight;
    final textMut = isDark ? AppTheme.textMuted      : AppTheme.textMutedLight;
    final textSec = isDark ? AppTheme.textSecondary  : AppTheme.textSecondaryLight;

    final last    = chat['last_message'] != null
        ? Map<String, dynamic>.from(chat['last_message'] as Map) : null;
    final unread  = int.parse((chat['unread_count'] ?? 0).toString());
    final isGroup = chat['type'] == 'group';
    final name    = _displayName(chat);
    final avatar  = _displayAvatar(chat);
    final status  = _displayStatus(chat);
    final lastTime = last != null ? DateTime.tryParse(last['created_at'] ?? '') : null;
    final isToday  = lastTime != null && lastTime.day == DateTime.now().day;

    return InkWell(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => ChatScreen(conversation: chat))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          isGroup ? _groupAvatar(chat['participants'] as List? ?? [])
                  : _avatar(avatar, status),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(name,
                style: TextStyle(color: textPri, fontWeight: FontWeight.w700, fontSize: 16),
                overflow: TextOverflow.ellipsis)),
              if (lastTime != null) Text(
                isToday
                  ? '${lastTime.hour.toString().padLeft(2,'0')}:${lastTime.minute.toString().padLeft(2,'0')}'
                  : '${lastTime.day}/${lastTime.month}',
                style: TextStyle(color: unread > 0 ? AppTheme.primary : textMut, fontSize: 12)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Text(last?['content'] ?? 'No messages yet',
                style: TextStyle(
                  color: unread > 0 ? textSec : textMut, fontSize: 14,
                  fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal),
                overflow: TextOverflow.ellipsis, maxLines: 1)),
              if (unread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                  child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
              ],
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _avatar(String url, String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppTheme.bgInput : AppTheme.bgInputLight;
    Color statusColor = status == 'online' ? AppTheme.online
        : status == 'away' ? AppTheme.away : AppTheme.offline;
    return Stack(children: [
      CircleAvatar(radius: 26, backgroundColor: inputBg,
        backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
        child: url.isEmpty ? Icon(Icons.person, color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight) : null),
      Positioned(bottom: 1, right: 1, child: Container(width: 13, height: 13,
        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)))),
    ]);
  }

  Widget _groupAvatar(List parts) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppTheme.bgInput : AppTheme.bgInputLight;
    // Filter out current user from display
    final others = parts.where((p) => (p as Map)['id'].toString() != _myId).toList();
    final p0 = others.isNotEmpty ? Map<String, dynamic>.from(others[0] as Map) : null;
    final p1 = others.length > 1 ? Map<String, dynamic>.from(others[1] as Map) : null;
    if (p0 == null) {
      return CircleAvatar(radius: 26, backgroundColor: AppTheme.primary.withOpacity(0.2),
        child: const Icon(Icons.group, color: AppTheme.primary, size: 26));
    }
    return SizedBox(width: 52, height: 52, child: Stack(children: [
      Positioned(top: 0, left: 0, child: CircleAvatar(radius: 18,
        backgroundImage: (p0['avatar_url'] ?? '').isNotEmpty ? NetworkImage(p0['avatar_url']) : null,
        backgroundColor: AppTheme.primary,
        child: (p0['avatar_url'] ?? '').isEmpty
          ? Text(p0['name'].toString()[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)) : null)),
      if (p1 != null) Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18,
        backgroundImage: (p1['avatar_url'] ?? '').isNotEmpty ? NetworkImage(p1['avatar_url']) : null,
        backgroundColor: AppTheme.accent,
        child: (p1['avatar_url'] ?? '').isEmpty
          ? Text(p1['name'].toString()[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)) : null)),
    ]));
  }

  Widget _errorView(String error, VoidCallback retry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMut = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.wifi_off, size: 52, color: textMut),
      const SizedBox(height: 16),
      Text(error, style: TextStyle(color: textMut), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      TextButton(onPressed: retry,
        child: const Text('Retry', style: TextStyle(color: AppTheme.primary))),
    ]));
  }

  void _showNewChatOptions(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final cardBg  = isDark ? AppTheme.bgCard : AppTheme.bgCardLight;
    final textPri = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final textMut = isDark ? AppTheme.textMuted   : AppTheme.textMutedLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: textMut, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('New Conversation', style: TextStyle(
              color: textPri, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.person_outline,
              label: 'New Direct Message',
              subtitle: 'Chat with one person',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                // Open contacts tab
                // User can tap a contact to start DM
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Go to People tab and tap the chat icon next to a contact'),
                  behavior: SnackBarBehavior.floating));
              },
            ),
            _OptionTile(
              icon: Icons.group_outlined,
              label: 'New Group Chat',
              subtitle: 'Chat with multiple people',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const CreateGroupScreen()));
              },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon, required this.label, required this.subtitle,
    required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textPri = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final textMut = isDark ? AppTheme.textMuted   : AppTheme.textMutedLight;
    final inputBg = isDark ? AppTheme.bgInput     : AppTheme.bgInputLight;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(width: 48, height: 48,
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.12), shape: BoxShape.circle),
        child: Icon(icon, color: AppTheme.primary, size: 22)),
      title: Text(label, style: TextStyle(color: textPri, fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: textMut, fontSize: 12)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: textMut),
    );
  }
}
