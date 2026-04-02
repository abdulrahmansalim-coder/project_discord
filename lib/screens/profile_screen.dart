import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user      = context.watch<AuthProvider>().user ?? {};
    final isDark    = context.watch<ThemeProvider>().isDark;
    final cardColor = isDark ? AppTheme.bgCard  : AppTheme.bgCardLight;
    final bgColor   = isDark ? AppTheme.bgDark  : AppTheme.bgLight;
    final textPri   = isDark ? AppTheme.textPrimary   : AppTheme.textPrimaryLight;
    final textSec   = isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;
    final textMut   = isDark ? AppTheme.textMuted     : AppTheme.textMutedLight;
    final inputBg   = isDark ? AppTheme.bgInput       : AppTheme.bgInputLight;
    final divColor  = isDark ? AppTheme.divider       : AppTheme.dividerLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('Profile', style: TextStyle(color: textPri)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: textPri),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Profile header card ─────────────────────────────────────────────
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
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 20, offset: const Offset(0, 8),
                ),
              ],
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
                  decoration: BoxDecoration(
                    color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: user['status'] == 'online' ? AppTheme.online
                          : user['status'] == 'away' ? AppTheme.away : Colors.white38,
                        shape: BoxShape.circle)),
                    Text(user['status'] ?? 'offline',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ])),
            ]),
          ),

          // ── Status ─────────────────────────────────────────────────────────
          _Section(label: 'My Status', cardColor: cardColor, divColor: divColor, items: [
            _Tile(icon: Icons.circle, iconColor: AppTheme.online,  label: 'Online',
              textColor: textPri, mutedColor: textMut, inputBg: inputBg,
              onTap: () => _setStatus(context, 'online')),
            _Tile(icon: Icons.circle, iconColor: AppTheme.away,    label: 'Away',
              textColor: textPri, mutedColor: textMut, inputBg: inputBg,
              onTap: () => _setStatus(context, 'away')),
            _Tile(icon: Icons.circle, iconColor: AppTheme.offline,  label: 'Offline',
              textColor: textPri, mutedColor: textMut, inputBg: inputBg,
              onTap: () => _setStatus(context, 'offline')),
          ]),

          // ── Account ────────────────────────────────────────────────────────
          _Section(label: 'Account', cardColor: cardColor, divColor: divColor, items: [
            _Tile(icon: Icons.email_outlined, label: user['email'] ?? '',
              textColor: textPri, mutedColor: textMut, inputBg: inputBg),
            _Tile(icon: Icons.lock_outline,   label: 'Change Password',
              textColor: textPri, mutedColor: textMut, inputBg: inputBg, onTap: () {}),
          ]),

          // ── Preferences ────────────────────────────────────────────────────
          _Section(label: 'Preferences', cardColor: cardColor, divColor: divColor, items: [
            _Tile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              textColor: textPri, mutedColor: textMut, inputBg: inputBg,
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: AppTheme.primary,
              ),
            ),
            _Tile(
              icon: isDark ? Icons.dark_mode : Icons.light_mode,
              label: isDark ? 'Dark Mode' : 'Light Mode',
              textColor: textPri, mutedColor: textMut, inputBg: inputBg,
              trailing: Switch(
                value: isDark,
                onChanged: (_) => context.read<ThemeProvider>().toggle(),
                activeColor: AppTheme.primary,
              ),
            ),
            _Tile(
              icon: Icons.language_outlined, label: 'Language', value: 'English',
              textColor: textPri, mutedColor: textMut, inputBg: inputBg,
            ),
          ]),

          // ── Sign out ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: () => _logout(context),
              style: TextButton.styleFrom(
                backgroundColor: cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Sign Out',
                style: TextStyle(color: AppTheme.accentWarm, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),

          Center(child: Text('Chatter v1.0.0',
            style: TextStyle(color: textMut, fontSize: 12))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _setStatus(BuildContext context, String status) {
    context.read<AuthProvider>().updateUser({'status': status});
    ApiService.updateStatus(status).catchError((_) {});
  }

  void _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: AppTheme.accentWarm))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> items;
  final Color cardColor;
  final Color divColor;

  const _Section({
    required this.label,
    required this.items,
    required this.cardColor,
    required this.divColor,
  });

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
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
          child: Column(children: items.asMap().entries.map((e) => Column(children: [
            e.value,
            if (e.key < items.length - 1)
              Divider(color: divColor, height: 1, indent: 52),
          ])).toList()),
        ),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData   icon;
  final Color?     iconColor;
  final String     label;
  final String?    value;
  final Widget?    trailing;
  final VoidCallback? onTap;
  final Color      textColor;
  final Color      mutedColor;
  final Color      inputBg;

  const _Tile({
    required this.icon,
    this.iconColor,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    required this.textColor,
    required this.mutedColor,
    required this.inputBg,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: iconColor ?? AppTheme.primary, size: 18),
    ),
    title: Text(label, style: TextStyle(color: textColor, fontSize: 14)),
    trailing: trailing ??
        (value != null
            ? Text(value!, style: TextStyle(color: mutedColor, fontSize: 13))
            : onTap != null
                ? Icon(Icons.chevron_right, color: mutedColor, size: 18)
                : null),
  );
}
