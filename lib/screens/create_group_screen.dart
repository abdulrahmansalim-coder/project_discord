import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/conversations_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});
  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameCtrl   = TextEditingController();
  List<dynamic>     _contacts  = [];
  List<dynamic>     _selected  = [];
  bool _loadingContacts = true;
  bool _creating        = false;
  String _search        = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _loadContacts() async {
    setState(() => _loadingContacts = true);
    try { _contacts = await ApiService.getContacts(); } catch (_) {}
    setState(() => _loadingContacts = false);
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _contacts;
    final q = _search.toLowerCase();
    return _contacts.where((c) =>
      (c['name'] ?? '').toLowerCase().contains(q) ||
      (c['username'] ?? '').toLowerCase().contains(q)).toList();
  }

  bool _isSelected(dynamic contact) =>
    _selected.any((s) => s['id'].toString() == contact['id'].toString());

  void _toggle(dynamic contact) {
    setState(() {
      if (_isSelected(contact)) {
        _selected.removeWhere((s) => s['id'].toString() == contact['id'].toString());
      } else {
        _selected.add(contact);
      }
    });
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a group name', AppTheme.accentWarm);
      return;
    }
    if (_selected.length < 2) {
      _showSnack('Select at least 2 people', AppTheme.accentWarm);
      return;
    }

    setState(() => _creating = true);
    try {
      final ids = _selected.map((s) => int.parse(s['id'].toString())).toList();
      final convo = await ApiService.createGroup(
        name: _nameCtrl.text.trim(),
        participantIds: ids,
      );

      // Add to conversations list
      if (mounted) {
        context.read<ConversationsProvider>().load();
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => ChatScreen(
            conversation: Map<String, dynamic>.from(convo))));
      }
    } on ApiException catch (e) {
      _showSnack(e.message, AppTheme.accentWarm);
    } finally {
      setState(() => _creating = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isDark  = theme.brightness == Brightness.dark;
    final bg      = theme.scaffoldBackgroundColor;
    final cardBg  = isDark ? AppTheme.bgCard      : AppTheme.bgCardLight;
    final inputBg = isDark ? AppTheme.bgInput     : AppTheme.bgInputLight;
    final textPri = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final textMut = isDark ? AppTheme.textMuted   : AppTheme.textMutedLight;
    final textSec = isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('New Group', style: TextStyle(color: textPri)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 18, color: textPri),
          onPressed: () => Navigator.pop(context)),
        actions: [
          // Create button in app bar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _creating ? null : _create,
              child: _creating
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                : const Text('Create', style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // ── Group name input ───────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            // Group icon
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.group, color: AppTheme.primary, size: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                style: TextStyle(color: textPri, fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Group name…',
                  hintStyle: TextStyle(color: textMut),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 8),

        // ── Selected members chips ─────────────────────────────────────────
        if (_selected.isNotEmpty)
          Container(
            height: 90,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selected.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final s = _selected[i];
                return Column(children: [
                  Stack(children: [
                    UserAvatar(avatarUrl: s['avatar_url'] ?? '', size: 52, showStatus: false),
                    Positioned(top: 0, right: 0,
                      child: GestureDetector(
                        onTap: () => _toggle(s),
                        child: Container(width: 20, height: 20,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentWarm, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 12, color: Colors.white)))),
                  ]),
                  const SizedBox(height: 4),
                  Text(s['name'].toString().split(' ').first,
                    style: TextStyle(color: textSec, fontSize: 11)),
                ]);
              },
            ),
          ),

        // ── Member count ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Text('ADD MEMBERS', style: TextStyle(
              color: textMut, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            const Spacer(),
            Text('${_selected.length} selected',
              style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),

        // ── Search ─────────────────────────────────────────────────────────
        ChatSearchBar(
          onChanged: (v) => setState(() => _search = v),
          hintText: 'Search contacts…'),

        // ── Contacts list ──────────────────────────────────────────────────
        Expanded(
          child: _loadingContacts
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _filtered.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.people_outline, size: 52, color: textMut.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  Text('No contacts to add', style: TextStyle(color: textMut, fontSize: 15)),
                ]))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final c        = Map<String, dynamic>.from(_filtered[i] as Map);
                    final selected = _isSelected(c);
                    final status   = c['status'] == 'online' ? UserStatus.online
                      : c['status'] == 'away' ? UserStatus.away : UserStatus.offline;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: UserAvatar(avatarUrl: c['avatar_url'] ?? '', status: status, size: 48),
                      title: Text(c['name'] ?? '',
                        style: TextStyle(color: textPri, fontWeight: FontWeight.w600, fontSize: 15)),
                      subtitle: Text('@${c['username'] ?? ''}',
                        style: TextStyle(color: textMut, fontSize: 12)),
                      trailing: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primary : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppTheme.primary : textMut,
                            width: 2),
                        ),
                        child: selected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                      ),
                      onTap: () => _toggle(c),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
