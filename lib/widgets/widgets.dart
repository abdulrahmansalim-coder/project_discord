import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum UserStatus { online, away, offline }

// ── Avatar with status dot ────────────────────────────────────────────────────

class UserAvatar extends StatelessWidget {
  final String avatarUrl;
  final UserStatus? status;
  final double size;
  final bool showStatus;

  const UserAvatar({super.key, required this.avatarUrl, this.status, this.size = 48, this.showStatus = true});

  Color _statusColor(UserStatus s) {
    switch (s) {
      case UserStatus.online:  return AppTheme.online;
      case UserStatus.away:    return AppTheme.away;
      case UserStatus.offline: return AppTheme.offline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppTheme.bgInput : AppTheme.bgInputLight;
    final iconClr = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    return Stack(children: [
      CircleAvatar(radius: size / 2, backgroundColor: inputBg,
        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl.isEmpty ? Icon(Icons.person, color: iconClr, size: size * 0.5) : null),
      if (showStatus && status != null)
        Positioned(bottom: 1, right: 1,
          child: Container(width: size * 0.28, height: size * 0.28,
            decoration: BoxDecoration(color: _statusColor(status!), shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)))),
    ]);
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class ChatSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;
  const ChatSearchBar({super.key, required this.onChanged, this.hintText = 'Search...'});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppTheme.bgInput : AppTheme.bgInputLight;
    final hintClr = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    final textClr = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(16)),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(color: textClr, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText, hintStyle: TextStyle(color: hintClr),
          prefixIcon: Icon(Icons.search, color: hintClr, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14)),
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
      Future.delayed(Duration(milliseconds: i * 150), c.repeat);
      return c;
    });
  }

  @override
  void dispose() { for (final c in _controllers) { c.dispose(); } super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bubbleBg  = isDark ? AppTheme.bgBubbleOther : AppTheme.bgBubbleOtherLight;
    final dotColor  = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;

    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: bubbleBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20),
              bottomRight: Radius.circular(20), bottomLeft: Radius.circular(4))),
          child: Row(children: List.generate(3, (i) => AnimatedBuilder(
            animation: _controllers[i],
            builder: (_, __) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7, height: 7 + (_controllers[i].value * 5),
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle))))),
        ),
      ]),
    );
  }
}

// ── Date separator ────────────────────────────────────────────────────────────

class DateSeparator extends StatelessWidget {
  final DateTime date;
  const DateSeparator({super.key, required this.date});

  String _label(DateTime d) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day   = DateTime(d.year, d.month, d.day);
    final diff  = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final textMut = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    final divClr  = isDark ? AppTheme.divider   : AppTheme.dividerLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        Expanded(child: Divider(color: divClr, indent: 16)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(_label(date), style: TextStyle(color: textMut, fontSize: 12))),
        Expanded(child: Divider(color: divClr, endIndent: 16)),
      ]),
    );
  }
}
