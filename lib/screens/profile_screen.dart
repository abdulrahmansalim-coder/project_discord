import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          // Profile header
          _ProfileHeader(),
          const SizedBox(height: 24),

          _SettingsSection(
            label: 'Account',
            items: [
              _SettingsTile(icon: Icons.person_outline, label: 'Edit Profile', trailing: null),
              _SettingsTile(icon: Icons.lock_outline, label: 'Privacy', trailing: null),
              _SettingsTile(icon: Icons.security_outlined, label: 'Security', trailing: null),
              _SettingsTile(icon: Icons.phone_outlined, label: 'Phone Number', value: '+62 812 3456 7890'),
            ],
          ),

          _SettingsSection(
            label: 'Preferences',
            items: [
              _SettingsTile(icon: Icons.notifications_outlined, label: 'Notifications', trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: AppTheme.primary,
              )),
              _SettingsTile(icon: Icons.dark_mode_outlined, label: 'Dark Mode', trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: AppTheme.primary,
              )),
              _SettingsTile(icon: Icons.language_outlined, label: 'Language', value: 'English'),
              _SettingsTile(icon: Icons.data_usage_outlined, label: 'Data & Storage'),
            ],
          ),

          _SettingsSection(
            label: 'Support',
            items: [
              _SettingsTile(icon: Icons.help_outline, label: 'Help Center'),
              _SettingsTile(icon: Icons.chat_outlined, label: 'Contact Us'),
              _SettingsTile(icon: Icons.star_outline, label: 'Rate the App'),
              _SettingsTile(icon: Icons.info_outline, label: 'About', value: 'v1.0.0'),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.bgCard,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(color: AppTheme.accentWarm, fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF3B35B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: NetworkImage(currentUser.avatarUrl),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alex Johnson',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '🚀 Building things & exploring ideas',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatChip(label: 'Chats', value: '${sampleChats.length}'),
                    const SizedBox(width: 12),
                    _StatChip(label: 'Contacts', value: '${sampleUsers.length}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$value $label',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String label;
  final List<Widget> items;
  const _SettingsSection({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: items.asMap().entries.map((e) {
                final last = e.key == items.length - 1;
                return Column(
                  children: [
                    e.value,
                    if (!last) const Divider(color: AppTheme.divider, height: 1, indent: 52),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.bgInput,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 18),
      ),
      title: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      trailing: trailing ?? (value != null
          ? Text(value!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13))
          : const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18)),
    );
  }
}
