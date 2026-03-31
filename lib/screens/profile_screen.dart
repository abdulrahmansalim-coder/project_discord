import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  String _phoneNumber = '+62 812 3456 7890';

  // ── Edit Profile ──────────────────────────────────────────
  void _openEditProfile() {
    final nameCtrl = TextEditingController(text: 'Alex Johnson');
    final bioCtrl = TextEditingController(text: '🚀 Building things & exploring ideas');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Profile', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _buildTextField(nameCtrl, 'Display Name', Icons.person_outline),
            const SizedBox(height: 12),
            _buildTextField(bioCtrl, 'Bio', Icons.edit_note_outlined),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () { Navigator.pop(ctx); _showSnackbar('Profile updated!', Icons.check_circle_outline); },
                child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Privacy ───────────────────────────────────────────────
  void _openPrivacy() => _openToggleSheet('Privacy Settings', [
    {'label': 'Last Seen', 'value': true},
    {'label': 'Profile Photo', 'value': true},
    {'label': 'Read Receipts', 'value': false},
    {'label': 'Online Status', 'value': true},
  ]);

  // ── Security ──────────────────────────────────────────────
  void _openSecurity() => _openToggleSheet('Security Settings', [
    {'label': 'Two-Factor Authentication', 'value': false},
    {'label': 'Biometric Lock', 'value': true},
    {'label': 'Login Alerts', 'value': true},
  ]);

  // ── Phone Number ──────────────────────────────────────────
  void _openPhoneNumber() {
    final phoneCtrl = TextEditingController(text: _phoneNumber);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Phone Number', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _buildTextField(phoneCtrl, 'Phone Number', Icons.phone_outlined, inputType: TextInputType.phone),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () { setState(() => _phoneNumber = phoneCtrl.text.trim()); Navigator.pop(ctx); _showSnackbar('Phone number updated!', Icons.check_circle_outline); },
                child: const Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Language ──────────────────────────────────────────────
  void _openLanguage() {
    const languages = ['English', 'Indonesian', 'Spanish', 'French', 'Japanese', 'Korean'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Language', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...languages.map((lang) => RadioListTile<String>(
                value: lang, groupValue: _selectedLanguage, activeColor: AppTheme.primary,
                title: Text(lang, style: const TextStyle(color: AppTheme.textPrimary)),
                onChanged: (val) { setInner(() {}); setState(() => _selectedLanguage = val!); Navigator.pop(ctx); _showSnackbar('Language set to $val', Icons.language_outlined); },
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Data & Storage ────────────────────────────────────────
  void _openDataStorage() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Data & Storage', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStorageRow('Photos', '128 MB'),
            _buildStorageRow('Videos', '512 MB'),
            _buildStorageRow('Documents', '34 MB'),
            _buildStorageRow('Other', '12 MB'),
            const Divider(color: AppTheme.divider, height: 24),
            _buildStorageRow('Total', '686 MB', bold: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); _showSnackbar('Cache cleared!', Icons.cleaning_services_outlined); }, child: const Text('Clear Cache', style: TextStyle(color: AppTheme.accentWarm))),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AppTheme.primary))),
        ],
      ),
    );
  }

  // ── Help Center ───────────────────────────────────────────
  void _openHelpCenter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Help Center', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...[
              ('How to change profile picture?', Icons.image_outlined),
              ('How to block a contact?', Icons.block_outlined),
              ('How to enable dark mode?', Icons.dark_mode_outlined),
              ('How to backup my chats?', Icons.backup_outlined),
              ('How to delete my account?', Icons.delete_outline),
            ].map((item) => ListTile(
              leading: Icon(item.$2, color: AppTheme.primary, size: 20),
              title: Text(item.$1, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
              onTap: () { Navigator.pop(ctx); _showSnackbar('Opening article...', Icons.open_in_new); },
            )),
          ],
        ),
      ),
    );
  }

  // ── Contact Us ────────────────────────────────────────────
  void _openContactUs() {
    final msgCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact Us', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('We usually reply within 24 hours.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: msgCtrl, maxLines: 4,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(hintText: 'Describe your issue...', hintStyle: const TextStyle(color: AppTheme.textMuted), filled: true, fillColor: AppTheme.bgInput, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () { Navigator.pop(ctx); _showSnackbar("Message sent! We'll get back to you soon.", Icons.send_outlined); },
                child: const Text('Send Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rate the App ──────────────────────────────────────────
  void _openRateApp() {
    int selectedStars = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Rate the App', style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How would you rate your experience?', style: TextStyle(color: AppTheme.textMuted, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setInner(() => selectedStars = i + 1),
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Icon(i < selectedStars ? Icons.star_rounded : Icons.star_outline_rounded, color: i < selectedStars ? Colors.amber : AppTheme.textMuted, size: 36)),
                )),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: selectedStars == 0 ? null : () { Navigator.pop(ctx); _showSnackbar(selectedStars >= 4 ? 'Thanks for the $selectedStars stars! ⭐' : 'Thanks for your feedback!', Icons.star_outline); },
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── About ─────────────────────────────────────────────────
  void _openAbout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.chat_bubble_rounded, color: AppTheme.primary, size: 40)),
            const SizedBox(height: 12),
            const Text('Chatter', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Version 1.0.0 (Build 100)', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            const Text('Made with ❤️ in Indonesia', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () { Clipboard.setData(const ClipboardData(text: '1.0.0')); Navigator.pop(ctx); _showSnackbar('Version copied!', Icons.copy_outlined); }, child: const Text('Copy Version', style: TextStyle(color: AppTheme.textMuted))),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AppTheme.primary))),
        ],
      ),
    );
  }

  // ── Sign Out ──────────────────────────────────────────────
  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: AppTheme.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentWarm, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: tambah logika sign out kamu di sini
              _showSnackbar('Signed out successfully', Icons.logout_outlined);
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Change Avatar ─────────────────────────────────────────
  void _openChangeAvatar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change Profile Photo', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...[
              ('Take a Photo', Icons.camera_alt_outlined, false),
              ('Choose from Gallery', Icons.photo_library_outlined, false),
              ('Remove Photo', Icons.delete_outline, true),
            ].map((item) => ListTile(
              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.bgInput, borderRadius: BorderRadius.circular(12)), child: Icon(item.$2, color: item.$3 ? AppTheme.accentWarm : AppTheme.primary)),
              title: Text(item.$1, style: TextStyle(color: item.$3 ? AppTheme.accentWarm : AppTheme.textPrimary)),
              onTap: () { Navigator.pop(ctx); _showSnackbar(item.$3 ? 'Profile photo removed' : 'Opening ${item.$1.toLowerCase()}...', item.$2); },
            )),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  void _showSnackbar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 10), Expanded(child: Text(message, style: const TextStyle(color: Colors.white)))]),
      backgroundColor: AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  void _openToggleSheet(String title, List<Map<String, dynamic>> toggles) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...toggles.map((item) => SwitchListTile(
                value: item['value'] as bool, activeColor: AppTheme.primary,
                title: Text(item['label'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                onChanged: (val) { setInner(() => item['value'] = val); _showSnackbar('${item['label']} ${val ? 'enabled' : 'disabled'}', val ? Icons.check_circle_outline : Icons.cancel_outlined); },
              )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: ctrl, keyboardType: inputType,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppTheme.textMuted), prefixIcon: Icon(icon, color: AppTheme.primary, size: 20), filled: true, fillColor: AppTheme.bgInput, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
    );
  }

  Widget _buildStorageRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: bold ? AppTheme.textPrimary : AppTheme.textMuted, fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        Text(value, style: TextStyle(color: bold ? AppTheme.primary : AppTheme.textMuted, fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
      ]),
    );
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _openEditProfile),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _ProfileHeader(onCameraTap: _openChangeAvatar),
          const SizedBox(height: 24),
          _SettingsSection(label: 'Account', items: [
            _SettingsTile(icon: Icons.person_outline, label: 'Edit Profile', onTap: _openEditProfile),
            _SettingsTile(icon: Icons.lock_outline, label: 'Privacy', onTap: _openPrivacy),
            _SettingsTile(icon: Icons.security_outlined, label: 'Security', onTap: _openSecurity),
            _SettingsTile(icon: Icons.phone_outlined, label: 'Phone Number', value: _phoneNumber, onTap: _openPhoneNumber),
          ]),
          _SettingsSection(label: 'Preferences', items: [
            _SettingsTile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (val) { setState(() => _notificationsEnabled = val); _showSnackbar('Notifications ${val ? 'enabled' : 'disabled'}', val ? Icons.notifications_active_outlined : Icons.notifications_off_outlined); },
                activeColor: AppTheme.primary,
              ),
            ),
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              label: 'Dark Mode',
              // Baca themeNotifier dari main.dart, update langsung ganti tema seluruh app
              trailing: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, themeMode, _) => Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (val) async {
                    themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isDarkMode', val);
                    _showSnackbar('Dark mode ${val ? 'enabled' : 'disabled'}', val ? Icons.dark_mode_outlined : Icons.light_mode_outlined);
                  },
                  activeColor: AppTheme.primary,
                ),
              ),
            ),
            _SettingsTile(icon: Icons.language_outlined, label: 'Language', value: _selectedLanguage, onTap: _openLanguage),
            _SettingsTile(icon: Icons.data_usage_outlined, label: 'Data & Storage', onTap: _openDataStorage),
          ]),
          _SettingsSection(label: 'Support', items: [
            _SettingsTile(icon: Icons.help_outline, label: 'Help Center', onTap: _openHelpCenter),
            _SettingsTile(icon: Icons.chat_outlined, label: 'Contact Us', onTap: _openContactUs),
            _SettingsTile(icon: Icons.star_outline, label: 'Rate the App', onTap: _openRateApp),
            _SettingsTile(icon: Icons.info_outline, label: 'About', value: 'v1.0.0', onTap: _openAbout),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextButton(
              onPressed: _confirmSignOut,
              style: TextButton.styleFrom(backgroundColor: AppTheme.bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Sign Out', style: TextStyle(color: AppTheme.accentWarm, fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onCameraTap;
  const _ProfileHeader({required this.onCameraTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF3B35B0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(radius: 36, backgroundImage: NetworkImage(currentUser.avatarUrl)),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: onCameraTap,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle, border: Border.all(color: AppTheme.primary, width: 2)),
                    child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alex Johnson', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('🚀 Building things & exploring ideas', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 10),
                Row(children: [
                  _StatChip(label: 'Chats', value: '${sampleChats.length}'),
                  const SizedBox(width: 12),
                  _StatChip(label: 'Contacts', value: '${sampleUsers.length}'),
                ]),
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Text('$value $label', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
          Text(label.toUpperCase(), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: items.asMap().entries.map((e) {
                final last = e.key == items.length - 1;
                return Column(children: [e.value, if (!last) const Divider(color: AppTheme.divider, height: 1, indent: 52)]);
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
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.label, this.value, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.bgInput, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.primary, size: 18),
      ),
      title: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      trailing: trailing ?? (value != null ? Text(value!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)) : const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18)),
    );
  }
}