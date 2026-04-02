import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/conversations_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> conversation;
  const ChatScreen({super.key, required this.conversation});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode  = FocusNode();

  List<dynamic> _messages = [];
  bool _loadingMsgs = true;
  bool _sending     = false;
  bool _isTyping    = false;
  int  _page        = 1;
  bool _hasMore     = true;

  int    get _convoId => int.parse(widget.conversation['id'].toString());
  String get _myId    => context.read<AuthProvider>().user?['id'].toString() ?? '';

  Map<String, dynamic>? get _otherParticipant {
    if (widget.conversation['type'] == 'group') return null;
    final parts = (widget.conversation['participants'] as List?) ?? [];
    final others = parts.where((p) => (p as Map)['id'].toString() != _myId).toList();
    return others.isNotEmpty ? Map<String, dynamic>.from(others.first as Map) : null;
  }

  String get _title {
    if (widget.conversation['type'] == 'group') return widget.conversation['name'] ?? 'Group';
    return _otherParticipant?['name'] ?? 'Chat';
  }

  String get _subtitle {
    if (widget.conversation['type'] == 'group') {
      final count = (widget.conversation['participants'] as List?)?.length ?? 0;
      return '$count members';
    }
    final status = _otherParticipant?['status'] ?? 'offline';
    return status == 'online' ? 'Online' : 'Last seen recently';
  }

  String get _avatarUrl {
    if (widget.conversation['type'] == 'group') return widget.conversation['avatar_url'] ?? '';
    return _otherParticipant?['avatar_url'] ?? '';
  }

  bool get _isOnline => _otherParticipant?['status'] == 'online';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _inputCtrl.addListener(() => setState(() => _isTyping = _inputCtrl.text.isNotEmpty));
    ApiService.markAllRead(_convoId).catchError((_) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationsProvider>().markRead(_convoId);
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool loadMore = false}) async {
    if (loadMore && !_hasMore) return;
    setState(() => _loadingMsgs = !loadMore);
    try {
      final data = await ApiService.getMessages(_convoId, page: loadMore ? _page + 1 : 1);
      final msgs = data['messages'] as List;
      final pagination = data['pagination'];
      setState(() {
        if (loadMore) {
          _messages = [...msgs.map((m) => Map<String, dynamic>.from(m as Map)), ..._messages];
          _page++;
        } else {
          _messages = msgs.map((m) => Map<String, dynamic>.from(m as Map)).toList();
          _page = 1;
        }
        _hasMore = (_page < (pagination['total_pages'] ?? 1));
        _loadingMsgs = false;
      });
      if (!loadMore) _scrollToBottom();
    } on ApiException catch (e) {
      setState(() => _loadingMsgs = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.accentWarm));
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _inputCtrl.clear();
    setState(() { _sending = true; _isTyping = false; });

    final optimistic = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'sender_id': int.tryParse(_myId) ?? 0,
      'content': text, 'type': 'text',
      'created_at': DateTime.now().toIso8601String(),
      'is_deleted': false, 'read_count': 0,
    };
    setState(() => _messages.add(optimistic));
    _scrollToBottom();

    try {
      final sent = await ApiService.sendMessage(_convoId, text);
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == optimistic['id']);
        if (idx != -1) _messages[idx] = Map<String, dynamic>.from(sent);
      });
      if (mounted) context.read<ConversationsProvider>().updateConversationLastMessage(_convoId, sent);
    } on ApiException catch (e) {
      setState(() => _messages.remove(optimistic));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.accentWarm));
    } finally {
      setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg     = theme.scaffoldBackgroundColor;
    final textPri = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final textMut = isDark ? AppTheme.textMuted    : AppTheme.textMutedLight;
    final inputBg = isDark ? AppTheme.bgInput      : AppTheme.bgInputLight;
    final bubbleOther = isDark ? AppTheme.bgBubbleOther : AppTheme.bgBubbleOtherLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leadingWidth: 36,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 18, color: textPri),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          CircleAvatar(radius: 19, backgroundColor: inputBg,
            backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
            child: _avatarUrl.isEmpty
              ? Icon(widget.conversation['type'] == 'group' ? Icons.group : Icons.person,
                  size: 18, color: textMut)
              : null),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPri)),
            Text(_subtitle, style: TextStyle(fontSize: 12,
              color: _isOnline ? AppTheme.online : textMut)),
          ])),
        ]),
        actions: [
          IconButton(icon: Icon(Icons.call_outlined, color: textPri), onPressed: () {}),
          IconButton(icon: Icon(Icons.more_vert, color: textPri), onPressed: () {}),
        ],
      ),
      body: Column(children: [
        if (_hasMore)
          TextButton(
            onPressed: () => _loadMessages(loadMore: true),
            child: const Text('Load older messages', style: TextStyle(color: AppTheme.primary, fontSize: 13))),

        Expanded(
          child: _loadingMsgs
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _messages.isEmpty
              ? Center(child: Text('No messages yet.\nSay hello! 👋',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textMut, fontSize: 16)))
              : GestureDetector(
                  onTap: () => _focusNode.unfocus(),
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg    = _messages[i] as Map<String, dynamic>;
                      final isMine = msg['sender_id'].toString() == _myId;
                      Widget? separator;
                      final t = DateTime.tryParse(msg['created_at'] ?? '');
                      if (t != null && (i == 0 || _dayChanged(_messages[i-1], msg))) {
                        separator = DateSeparator(date: t);
                      }
                      return Column(children: [
                        if (separator != null) separator,
                        _buildBubble(msg, isMine, isDark, bubbleOther, textPri, textMut),
                      ]);
                    },
                  ),
                ),
        ),
        _buildInputBar(isDark, inputBg, textMut),
      ]),
    );
  }

  bool _dayChanged(dynamic prev, dynamic curr) {
    final a = DateTime.tryParse(prev['created_at'] ?? '');
    final b = DateTime.tryParse(curr['created_at'] ?? '');
    if (a == null || b == null) return false;
    return a.day != b.day || a.month != b.month;
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isMine, bool isDark,
      Color bubbleOther, Color textPri, Color textMut) {
    final isTemp    = msg['id'].toString().startsWith('temp_');
    final isDeleted = msg['is_deleted'] == true;
    final isGroup   = widget.conversation['type'] == 'group';
    final senderName = msg['sender_name'] ?? '';

    return Padding(
      padding: EdgeInsets.only(left: isMine ? 64 : 12, right: isMine ? 12 : 64, bottom: 4),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Show sender name in group chats
          if (isGroup && !isMine && senderName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 3),
              child: Text(senderName,
                style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? AppTheme.bgBubbleSelf : bubbleOther,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMine ? 20 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 20),
              ),
            ),
            child: Text(
              isDeleted ? '🚫 Message deleted' : msg['content'] ?? '',
              style: TextStyle(
                color: isDeleted ? textMut : (isMine ? Colors.white : textPri),
                fontSize: 15,
                fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
            child: Row(
              mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(_formatTime(msg['created_at']),
                  style: TextStyle(color: textMut, fontSize: 11)),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(isTemp ? Icons.access_time : Icons.done_all,
                    size: 13,
                    color: int.parse((msg['read_count'] ?? 0).toString()) > 1
                        ? AppTheme.accent : textMut),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark, Color inputBg, Color textMut) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        _CircleBtn(icon: Icons.add, onTap: () {}, color: inputBg, iconColor: textMut),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(24)),
            child: TextField(
              controller: _inputCtrl, focusNode: _focusNode,
              minLines: 1, maxLines: 5,
              style: TextStyle(color: isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Message…',
                hintStyle: TextStyle(color: textMut),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: _isTyping
            ? _CircleBtn(key: const ValueKey('send'), icon: Icons.send_rounded,
                onTap: _sendMessage, color: AppTheme.primary, iconColor: Colors.white)
            : _CircleBtn(key: const ValueKey('mic'), icon: Icons.mic_outlined,
                onTap: () {}, color: inputBg, iconColor: textMut),
        ),
      ]),
    );
  }

  String _formatTime(dynamic raw) {
    final t = raw is String ? DateTime.tryParse(raw) : null;
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color, iconColor;
  const _CircleBtn({super.key, required this.icon, required this.onTap, required this.color, required this.iconColor});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 44, height: 44,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 22)),
  );
}
