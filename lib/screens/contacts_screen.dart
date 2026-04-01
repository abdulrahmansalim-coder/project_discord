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
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getContacts(),
        ApiService.getContactRequests(),
      ]);
      setState(() {
        _contacts = results[0];
        _requests = results[1];
      });
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
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text('People'),
        actions: [
          // Add contact button
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: _showAddContact,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              const Tab(text: 'Contacts'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Requests'),
                    if (_requests.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentWarm,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${_requests.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : TabBarView(
            controller: _tabCtrl,
            children: [
              _contactsTab(),
              _requestsTab(),
            ],
          ),
    );
  }

  // ── Contacts tab ─────────────────────────────────────────────────────────────

  Widget _contactsTab() {
    final filtered = _filtered;
    return Column(children: [
      ChatSearchBar(onChanged: (v) => setState(() => _search = v), hintText: 'Search contacts…'),
      Expanded(
        child: filtered.isEmpty
          ? _emptyState(
              icon: Icons.people_outline,
              message: _search.isNotEmpty
                ? 'No contacts match "$_search"'
                : 'No contacts yet.\nTap + to add someone.',
            )
          : RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.bgCard,
              onRefresh: _load,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _contactTile(filtered[i] as Map<String, dynamic>),
              ),
            ),
      ),
    ]);
  }

  Widget _contactTile(Map<String, dynamic> user) {
    final status = user['status'] == 'online' ? UserStatus.online
      : user['status'] == 'away' ? UserStatus.away : UserStatus.offline;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: UserAvatar(avatarUrl: user['avatar_url'] ?? '', status: status, size: 48),
      title: Text(user['name'] ?? '',
        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(
        '@${user['username'] ?? ''}',
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
      ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        // Message button
        _iconBtn(Icons.chat_bubble_outline, AppTheme.primary, () => _openChat(user)),
        const SizedBox(width: 8),
        // Remove button
        _iconBtn(Icons.person_remove_outlined, AppTheme.accentWarm, () => _removeContact(user)),
      ]),
    );
  }

  // ── Requests tab ─────────────────────────────────────────────────────────────

  Widget _requestsTab() {
    if (_requests.isEmpty) {
      return _emptyState(
        icon: Icons.mark_email_unread_outlined,
        message: 'No pending contact requests',
      );
    }
    return RefreshIndicator(
      color: AppTheme.primary,
      backgroundColor: AppTheme.bgCard,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: _requests.length,
        itemBuilder: (_, i) => _requestTile(_requests[i] as Map<String, dynamic>),
      ),
    );
  }

  Widget _requestTile(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1),
      ),
      child: Row(children: [
        UserAvatar(avatarUrl: user['avatar_url'] ?? '', size: 46, showStatus: false),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user['name'] ?? '',
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
          Text('@${user['username'] ?? ''}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          const Text('Wants to connect with you',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ])),
        const SizedBox(width: 8),
        Column(children: [
          // Accept
          GestureDetector(
            onTap: () => _acceptRequest(user),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Accept',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 6),
          // Decline
          GestureDetector(
            onTap: () => _declineRequest(user),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.bgInput,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Decline',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Add contact bottom sheet ───────────────────────────────────────────────

  void _showAddContact() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddContactSheet(onAdded: _load),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _openChat(Map<String, dynamic> user) async {
    final convo = await context.read<ConversationsProvider>()
        .getOrCreateDirect(int.parse(user['id'].toString()));
    if (convo != null && mounted) {
      Navigator.push(context,
        MaterialPageRoute(builder: (_) => ChatScreen(conversation: convo)));
    }
  }

  Future<void> _acceptRequest(Map<String, dynamic> user) async {
    try {
      await ApiService.acceptContact(int.parse(user['id'].toString()));
      _showSnack('${user['name']} added to contacts!', AppTheme.accent);
      _load();
    } on ApiException catch (e) {
      _showSnack(e.message, AppTheme.accentWarm);
    }
  }

  Future<void> _declineRequest(Map<String, dynamic> user) async {
    try {
      await ApiService.removeContact(int.parse(user['id'].toString()));
      setState(() => _requests.remove(user));
    } on ApiException catch (e) {
      _showSnack(e.message, AppTheme.accentWarm);
    }
  }

  Future<void> _removeContact(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Remove Contact', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Remove ${user['name']} from your contacts?',
          style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: AppTheme.accentWarm))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.removeContact(int.parse(user['id'].toString()));
        _showSnack('Contact removed', AppTheme.textMuted);
        _load();
      } on ApiException catch (e) {
        _showSnack(e.message, AppTheme.accentWarm);
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );

  Widget _emptyState({required IconData icon, required String message}) =>
    Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 64, color: AppTheme.textMuted.withOpacity(0.4)),
      const SizedBox(height: 16),
      Text(message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 15, height: 1.6)),
    ]));
}

// ── Add Contact Bottom Sheet ──────────────────────────────────────────────────

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
  Set<int> _adding = {};

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _search(String q) async {
    if (q.length < 2) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    try {
      _results = await ApiService.searchUsers(q);
    } catch (_) { _results = []; }
    setState(() => _searching = false);
  }

  Future<void> _add(Map<String, dynamic> user) async {
    final id = int.parse(user['id'].toString());
    setState(() => _adding.add(id));
    try {
      await ApiService.sendContactRequest(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${user['name']} added to contacts!'),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        Navigator.pop(context);
        widget.onAdded();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppTheme.accentWarm,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      setState(() => _adding.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Add Contact',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Search by name or username',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 16),

          // Search field
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: _search,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. ariana or sofia…',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
              suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)))
                : null,
              filled: true,
              fillColor: AppTheme.bgInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
            ),
          ),

          const SizedBox(height: 12),

          // Results
          if (_results.isEmpty && !_searching && _ctrl.text.length >= 2)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No users found', style: TextStyle(color: AppTheme.textMuted)),
            )
          else
            ..._results.map((u) {
              final id = int.parse(u['id'].toString());
              final isAdding = _adding.contains(id);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                leading: CircleAvatar(
                  backgroundImage: (u['avatar_url'] ?? '').isNotEmpty
                    ? NetworkImage(u['avatar_url']) : null,
                  backgroundColor: AppTheme.bgInput,
                  child: (u['avatar_url'] ?? '').isEmpty
                    ? const Icon(Icons.person, color: AppTheme.textMuted) : null,
                ),
                title: Text(u['name'],
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text('@${u['username']}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                trailing: GestureDetector(
                  onTap: isAdding ? null : () => _add(u as Map<String, dynamic>),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isAdding
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Add',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              );
            }),

          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
