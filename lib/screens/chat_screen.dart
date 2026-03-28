import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  bool _showTypingIndicator = false;
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.chat.messages);
    _inputCtrl.addListener(() {
      setState(() => _isTyping = _inputCtrl.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    final msg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      content: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    setState(() {
      _messages.add(msg);
      _inputCtrl.clear();
      _isTyping = false;
    });

    _scrollToBottom();

    // Simulate the other person typing & replying
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _showTypingIndicator = true);
      _scrollToBottom();
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final replies = [
        'Sounds good! 👍',
        'Got it, thanks!',
        'Sure, no problem!',
        'Haha, nice 😄',
        'Let me check and get back to you.',
        'Absolutely!',
        '❤️',
        'That\'s great news!',
        'On it!',
        'Will do, talk soon!',
      ];
      final reply = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: widget.chat.participants.first.id,
        content: replies[DateTime.now().second % replies.length],
        timestamp: DateTime.now(),
      );
      setState(() {
        _showTypingIndicator = false;
        _messages.add(reply);
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        leadingWidth: 36,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            chat.isGroup
                ? GroupAvatar(participants: chat.participants, size: 38)
                : UserAvatar(
                    avatarUrl: chat.displayAvatar,
                    status: chat.displayStatus,
                    size: 38,
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    chat.isGroup
                        ? '${chat.participants.length} members'
                        : chat.displayStatus == UserStatus.online
                            ? 'Online'
                            : 'Last seen recently',
                    style: TextStyle(
                      fontSize: 12,
                      color: chat.displayStatus == UserStatus.online && !chat.isGroup
                          ? AppTheme.online
                          : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () => _showCallOverlay(isVideo: true),
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () => _showCallOverlay(isVideo: false),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: GestureDetector(
              onTap: () => _focusNode.unfocus(),
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                physics: const BouncingScrollPhysics(),
                itemCount: _messages.length + (_showTypingIndicator ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _messages.length) return const TypingIndicator();
                  final msg = _messages[i];
                  final isMine = msg.senderId == 'me';

                  // Date separator
                  Widget? separator;
                  if (i == 0 ||
                      _messages[i - 1].timestamp.day != msg.timestamp.day) {
                    separator = DateSeparator(date: msg.timestamp);
                  }

                  final showAvatar = chat.isGroup &&
                      !isMine &&
                      (i == _messages.length - 1 ||
                          _messages[i + 1].senderId != msg.senderId);

                  return Column(
                    children: [
                      if (separator != null) separator,
                      MessageBubble(
                        message: msg,
                        isMine: isMine,
                        showAvatar: showAvatar,
                        sender: chat.participants.firstWhere(
                          (u) => u.id == msg.senderId,
                          orElse: () => sampleUsers.first,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: AppTheme.bgDark,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment
          _CircleIconBtn(
            icon: Icons.add,
            onTap: () {},
            color: AppTheme.bgInput,
            iconColor: AppTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppTheme.bgInput,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 5,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Message…',
                        hintStyle: TextStyle(color: AppTheme.textMuted),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 6),
                    child: IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined, size: 22),
                      color: AppTheme.textMuted,
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send / mic button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: _isTyping
                ? _CircleIconBtn(
                    key: const ValueKey('send'),
                    icon: Icons.send_rounded,
                    onTap: _sendMessage,
                    color: AppTheme.primary,
                    iconColor: Colors.white,
                  )
                : _CircleIconBtn(
                    key: const ValueKey('mic'),
                    icon: Icons.mic_outlined,
                    onTap: () {},
                    color: AppTheme.bgInput,
                    iconColor: AppTheme.textSecondary,
                  ),
          ),
        ],
      ),
    );
  }

  void _showCallOverlay({required bool isVideo}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _CallOverlay(chat: widget.chat, isVideo: isVideo),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;

  const _CircleIconBtn({
    super.key,
    required this.icon,
    required this.onTap,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}

// ── Call overlay ──────────────────────────────────────────────────────────────

class _CallOverlay extends StatelessWidget {
  final Chat chat;
  final bool isVideo;

  const _CallOverlay({required this.chat, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          UserAvatar(
            avatarUrl: chat.displayAvatar,
            size: 80,
            showStatus: false,
          ),
          const SizedBox(height: 16),
          Text(
            chat.displayName,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isVideo ? 'Starting video call…' : 'Calling…',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CallBtn(icon: Icons.mic_off, label: 'Mute', color: AppTheme.bgInput),
              _CallBtn(
                icon: Icons.call_end,
                label: 'End',
                color: AppTheme.accentWarm,
                onTap: () => Navigator.pop(context),
              ),
              _CallBtn(
                icon: isVideo ? Icons.videocam_off : Icons.volume_up,
                label: isVideo ? 'Camera' : 'Speaker',
                color: AppTheme.bgInput,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CallBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _CallBtn({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
