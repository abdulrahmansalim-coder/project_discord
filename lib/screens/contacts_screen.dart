import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/conversations_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _contacts = [];
  List<dynamic> _requests = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([ApiService.getContacts(), ApiService.getContactRequests()]);
      setState(() { _contacts = results[0]; _requests = results[1]; });
    } catch (_) {}
    setState(() => _loading = false);
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _contacts;
    final q = _search.toLowerCase();
    return _contacts.where((c) =>
      (c['name'] ?? '').toLowerCase().contains(q) ||
      (c['username'] ?? '').toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isDark  = theme.brightness == Brightness.dark;
    final bg      = theme.scaffoldBackgroundColor;
    final textPri = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('People', style: TextStyle(color: textPri)),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt_1_outlined, color: textPri),
            onPressed: _showAddContact),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppTheme.primary,
            unselectedLabelColor: isDark ? AppTheme.textMuted : AppTheme.textMutedLight,
            indicatorColor: AppTheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              const Tab(text: 'Contacts'),
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Requests'),
                if (_requests.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.accentWarm, borderRadius: BorderRadius.circular(10)),
                    child: Text('${_requests.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                ],
              ])),
            ],
          ),
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : TabBarView(controller: _tabCtrl, children: [
            _contactsTab(isDark),
            _requestsTab(isDark),
          ]),
    );
  }

  Widget _contactsTab(bool isDark) {
    final filtered = _filtered;
    final textMut  = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    return Column(children: [
      ChatSearchBar(onChanged: (v) => setState(() => _search = v), hintText: 'Search contacts…'),
      Expanded(
        child: filtered.isEmpty
          ? _empty(Icons.people_outline, _search.isNotEmpty ? 'No contacts match "$_search"' : 'No contacts yet.\nTap + to add someone.', isDark)
          : RefreshIndicator(
              color: AppTheme.primary, backgroundColor: Theme.of(context).cardColor,
              onRefresh: _load,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _contactTile(Map<String, dynamic>.from(filtered[i] as Map), isDark),
              ),
            ),
      ),
    ]);
  }

  Widget _contactTile(Map<String, dynamic> user, bool isDark) {
    final textPri = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final textMut = isDark ? AppTheme.textMuted    : AppTheme.textMutedLight;
    final status  = user['status'] == 'online' ? UserStatus.online
      : user['status'] == 'away' ? UserStatus.away : UserStatus.offline;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: UserAvatar(avatarUrl: user['avatar_url'] ?? '', status: status, size: 48),
      title: Text(user['name'] ?? '', style: TextStyle(color: textPri, fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text('@${user['username'] ?? ''}', style: TextStyle(color: textMut, fontSize: 12)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        _iconBtn(Icons.chat_bubble_outline, AppTheme.primary, () => _openChat(user)),
        const SizedBox(width: 8),
        _iconBtn(Icons.person_remove_outlined, AppTheme.accentWarm, () => _removeContact(user)),
      ]),
    );
  }

  Widget _requestsTab(bool isDark) {
    if (_requests.isEmpty) return _empty(Icons.mark_email_unread_outlined, 'No pending contact requests', isDark);
    return RefreshIndicator(
      color: AppTheme.primary, backgroundColor: Theme.of(context).cardColor,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: _requests.length,
        itemBuilder: (_, i) => _requestTile(Map<String, dynamic>.from(_requests[i] as Map), isDark),
      ),
    );
  }

  Widget _requestTile(Map<String, dynamic> user, bool isDark) {
    final textPri = isDark ? AppTheme.textPrimary   : AppTheme.textPrimaryLight;
    final textSec = isDark ? AppTheme.textSecondary  : AppTheme.textSecondaryLight;
    final cardBg  = isDark ? AppTheme.bgCard         : AppTheme.bgCardLight;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1)),
      child: Row(children: [
        UserAvatar(avatarUrl: user['avatar_url'] ?? '', size: 46, showStatus: false),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user['name'] ?? '', style: TextStyle(color: textPri, fontWeight: FontWeight.w600, fontSize: 15)),
          Text('@${user['username'] ?? ''}', style: TextStyle(color: textSec, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Wants to connect with you', style: TextStyle(color: textSec, fontSize: 12)),
        ])),
        const SizedBox(width: 8),
        Column(children: [
          GestureDetector(
            onTap: () => _acceptRequest(user),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
              child: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)))),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _declineRequest(user),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: isDark ? AppTheme.bgInput : AppTheme.bgInputLight, borderRadius: BorderRadius.circular(10)),
              child: Text('Decline', style: TextStyle(color: isDark ? AppTheme.textMuted : AppTheme.textMutedLight, fontSize: 13)))),
        ]),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
    GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: color)));

  Widget _empty(IconData icon, String message, bool isDark) {
    final textMut = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 64, color: textMut.withOpacity(0.4)),
      const SizedBox(height: 16),
      Text(message, textAlign: TextAlign.center, style: TextStyle(color: textMut, fontSize: 15, height: 1.6)),
    ]));
  }

  void _showAddContact() {
    showModalBottomSheet(context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddContactSheet(onAdded: _load));
  }

  Future<void> _openChat(Map<String, dynamic> user) async {
    final convo = await context.read<ConversationsProvider>().getOrCreateDirect(int.parse(user['id'].toString()));
    if (convo != null && mounted) Navigator.push(context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: convo)))
      .then((_) => context.read<ConversationsProvider>().load());
  }

  Future<void> _acceptRequest(Map<String, dynamic> user) async {
    try {
      await ApiService.acceptContact(int.parse(user['id'].toString()));
      _showSnack('${user['name']} added to contacts!', AppTheme.accent);
      _load();
    } on ApiException catch (e) { _showSnack(e.message, AppTheme.accentWarm); }
  }

  Future<void> _declineRequest(Map<String, dynamic> user) async {
    try {
      await ApiService.removeContact(int.parse(user['id'].toString()));
      setState(() => _requests.remove(user));
    } on ApiException catch (e) { _showSnack(e.message, AppTheme.accentWarm); }
  }

  Future<void> _removeContact(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text('Remove ${user['name']} from contacts?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: AppTheme.accentWarm))),
        ]));
    if (confirm == true) {
      try {
        await ApiService.removeContact(int.parse(user['id'].toString()));
        _showSnack('Contact removed', AppTheme.textMuted);
        _load();
      } on ApiException catch (e) { _showSnack(e.message, AppTheme.accentWarm); }
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}

class _AddContactSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddContactSheet({required this.onAdded});
  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  final _ctrl = TextEditingController();
  List<dynamic> _results = [];
  bool _searching = false;
  final Set<int> _adding = {};

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _search(String q) async {
    if (q.length < 2) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    try { _results = await ApiService.searchUsers(q); } catch (_) { _results = []; }
    setState(() => _searching = false);
  }

  Future<void> _add(Map<String, dynamic> user) async {
    final id = int.parse(user['id'].toString());
    setState(() => _adding.add(id));
    try {
      await ApiService.sendContactRequest(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${user['name']} added!'),
          backgroundColor: AppTheme.accent, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
        Navigator.pop(context);
        widget.onAdded();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message), backgroundColor: AppTheme.accentWarm,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } finally { setState(() => _adding.remove(id)); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final textPri = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final textMut = isDark ? AppTheme.textMuted    : AppTheme.textMutedLight;
    final inputBg = isDark ? AppTheme.bgInput      : AppTheme.bgInputLight;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: textMut, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Add Contact', style: TextStyle(color: textPri, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Search by name or username', style: TextStyle(color: textMut, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl, autofocus: true, onChanged: _search,
            style: TextStyle(color: textPri),
            decoration: InputDecoration(
              hintText: 'e.g. ariana or sofia…', hintStyle: TextStyle(color: textMut),
              prefixIcon: Icon(Icons.search, color: textMut),
              suffixIcon: _searching ? const Padding(padding: EdgeInsets.all(12),
                child: SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))) : null,
              filled: true, fillColor: inputBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5))),
          ),
          const SizedBox(height: 12),
          if (_results.isEmpty && !_searching && _ctrl.text.length >= 2)
            Padding(padding: const EdgeInsets.all(20),
              child: Text('No users found', style: TextStyle(color: textMut)))
          else
            ..._results.map((u) {
              final user = Map<String, dynamic>.from(u as Map);
              final id   = int.parse(user['id'].toString());
              final isAdding = _adding.contains(id);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                leading: CircleAvatar(
                  backgroundImage: (user['avatar_url'] ?? '').isNotEmpty ? NetworkImage(user['avatar_url']) : null,
                  backgroundColor: inputBg,
                  child: (user['avatar_url'] ?? '').isEmpty ? Icon(Icons.person, color: textMut) : null),
                title: Text(user['name'], style: TextStyle(color: textPri, fontWeight: FontWeight.w600)),
                subtitle: Text('@${user['username']}', style: TextStyle(color: textMut, fontSize: 12)),
                trailing: GestureDetector(
                  onTap: isAdding ? null : () => _add(user),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                    child: isAdding
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)))));
            }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
