import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String _search = '';

  List<User> get _filtered {
    final q = _search.toLowerCase();
    return sampleUsers.where((u) => u.name.toLowerCase().contains(q)).toList();
  }

  Map<String, List<User>> get _grouped {
    final map = <String, List<User>>{};
    for (final u in _filtered) {
      final letter = u.name[0].toUpperCase();
      map.putIfAbsent(letter, () => []).add(u);
    }
    return Map.fromEntries(map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final online = sampleUsers.where((u) => u.status == UserStatus.online).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text('People'),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_alt_1_outlined), onPressed: () {}),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          SearchBar(
            onChanged: (v) => setState(() => _search = v),
            hintText: 'Search people…',
          ),

          // Online now
          if (_search.isEmpty) ...[
            _sectionHeader('Online Now'),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: online.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (_, i) {
                  final u = online[i];
                  return Column(
                    children: [
                      UserAvatar(avatarUrl: u.avatarUrl, status: u.status, size: 56),
                      const SizedBox(height: 6),
                      Text(
                        u.name.split(' ').first,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Grouped contacts
          for (final entry in grouped.entries) ...[
            _sectionHeader(entry.key),
            ...entry.value.map((u) => _contactTile(u)),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _contactTile(User user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: UserAvatar(avatarUrl: user.avatarUrl, status: user.status, size: 46),
      title: Text(
        user.name,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: user.statusMessage != null
          ? Text(user.statusMessage!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12))
          : Text(
              user.status == UserStatus.online ? 'Online' : 'Offline',
              style: TextStyle(
                color: user.status == UserStatus.online ? AppTheme.online : AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SmallIconBtn(icon: Icons.call_outlined, onTap: () {}),
          const SizedBox(width: 8),
          _SmallIconBtn(icon: Icons.chat_bubble_outline, onTap: () {}),
        ],
      ),
    );
  }
}

class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.bgInput,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppTheme.textSecondary),
      ),
    );
  }
}
