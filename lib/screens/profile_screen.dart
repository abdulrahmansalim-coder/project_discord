import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user ?? {};

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Header card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF3B35B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: (user['avatar_url'] ?? '').isNotEmpty
                    ? NetworkImage(user['avatar_url']) : null,
                backgroundColor: Colors.white24,
                child: (user['avatar_url'] ?? '').isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 36) : null,
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user['name'] ?? 'User',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('@${user['username'] ?? ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
                if ((user['status_message'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(user['status_message'],
                    style: const TextStyle(color: Colors.white60, fontSize: 13)),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Text(user['status'] ?? 'offline',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ])),
            ]),
          ),

          // Status selector
          _Section(label: 'My Status', items: [
            _Tile(icon: Icons.circle, iconColor: AppTheme.online,   label: 'Online',
              onTap: () => _setStatus(context, 'online')),
            _Tile(icon: Icons.circle, iconColor: AppTheme.away,     label: 'Away',
              onTap: () => _setStatus(context, 'away')),
            _Tile(icon: Icons.circle, iconColor: AppTheme.offline,  label: 'Offline',
              onTap: () => _setStatus(context, 'offline')),
          ]),

          _Section(label: 'Account', items: [
            _Tile(icon: Icons.email_outlined,  label: user['email'] ?? ''),
            _Tile(icon: Icons.lock_outline,    label: 'Change Password', onTap: () {}),
          ]),

          _Section(label: 'Preferences', items: [
            _Tile(icon: Icons.notifications_outlined, label: 'Notifications',
              trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppTheme.primary)),
            _Tile(icon: Icons.language_outlined, label: 'Language', value: 'English'),
          ]),

          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: () => _logout(context),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.bgCard,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Sign Out',
                style: TextStyle(color: AppTheme.accentWarm, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _setStatus(BuildContext context, String status) {
    // Update locally immediately
    context.read<AuthProvider>().updateUser({'status': status});
    // Fire API call in background
    ApiService.updateStatus(status).catchError((_) {});
  }

  void _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Sign Out', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Are you sure you want to sign out?',
          style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: AppTheme.accentWarm))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}

// ── Reusable section / tile ───────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> items;
  const _Section({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11,
            fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: items.asMap().entries.map((e) => Column(children: [
              e.value,
              if (e.key < items.length - 1)
                const Divider(color: AppTheme.divider, height: 1, indent: 52),
            ])).toList(),
          ),
        ),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData  icon;
  final Color?    iconColor;
  final String    label;
  final String?   value;
  final Widget?   trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    this.iconColor,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppTheme.bgInput, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: iconColor ?? AppTheme.primary, size: 18),
    ),
    title: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
    trailing: trailing ??
        (value != null
            ? Text(value!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13))
            : onTap != null
                ? const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18)
                : null),
  );
}
