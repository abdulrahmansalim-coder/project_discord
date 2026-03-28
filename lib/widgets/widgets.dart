import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

// ── Avatar with status dot ────────────────────────────────────────────────────

class UserAvatar extends StatelessWidget {
  final String avatarUrl;
  final UserStatus? status;
  final double size;
  final bool showStatus;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    this.status,
    this.size = 48,
    this.showStatus = true,
  });

  Color _statusColor(UserStatus s) {
    switch (s) {
      case UserStatus.online: return AppTheme.online;
      case UserStatus.away: return AppTheme.away;
      case UserStatus.offline: return AppTheme.offline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: AppTheme.bgInput,
          backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl.isEmpty
              ? Icon(Icons.person, color: AppTheme.textMuted, size: size * 0.5)
              : null,
        ),
        if (showStatus && status != null)
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: _statusColor(status!),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.bgDark, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Group avatar (stacked) ────────────────────────────────────────────────────

class GroupAvatar extends StatelessWidget {
  final List<User> participants;
  final double size;

  const GroupAvatar({super.key, required this.participants, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final shown = participants.take(2).toList();
    final half = size * 0.65;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            top: 0, left: 0,
            child: CircleAvatar(
              radius: half / 2,
              backgroundImage: shown.isNotEmpty ? NetworkImage(shown[0].avatarUrl) : null,
              backgroundColor: AppTheme.primary,
            ),
          ),
          if (shown.length > 1)
            Positioned(
              bottom: 0, right: 0,
              child: CircleAvatar(
                radius: half / 2,
                backgroundImage: NetworkImage(shown[1].avatarUrl),
                backgroundColor: AppTheme.accent,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final bool showAvatar;
  final User? sender;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showAvatar = false,
    this.sender,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 64 : 12,
        right: isMine ? 12 : 64,
        bottom: 4,
      ),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine && showAvatar) ...[
                UserAvatar(
                  avatarUrl: sender?.avatarUrl ?? '',
                  size: 28,
                  showStatus: false,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine ? AppTheme.bgBubbleSelf : AppTheme.bgBubbleOther,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMine ? 20 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isMine ? Colors.white : AppTheme.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Row(
              mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  _StatusIcon(status: message.status),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _StatusIcon extends StatelessWidget {
  final MessageStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return const Icon(Icons.access_time, size: 12, color: AppTheme.textMuted);
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 12, color: AppTheme.textMuted);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 12, color: AppTheme.textMuted);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 12, color: AppTheme.accent);
    }
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class ChatSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;

  const ChatSearchBar({super.key, required this.onChanged, this.hintText = 'Search...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgInput,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppTheme.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
        ),
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

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      Future.delayed(Duration(milliseconds: i * 150), c.repeat);
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.bgBubbleOther,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _controllers[i],
                  builder: (_, __) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 7,
                      height: 7 + (_controllers[i].value * 5),
                      decoration: const BoxDecoration(
                        color: AppTheme.textMuted,
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date separator ────────────────────────────────────────────────────────────

class DateSeparator extends StatelessWidget {
  final DateTime date;
  const DateSeparator({super.key, required this.date});

  String _label(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppTheme.divider, indent: 16)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _label(date),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
          const Expanded(child: Divider(color: AppTheme.divider, endIndent: 16)),
        ],
      ),
    );
  }
}
