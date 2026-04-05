import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});
  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  List<dynamic> _stories = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _stories = (await ApiService.getStories())
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();
    } catch (_) {}
    setState(() => _loading = false);
  }

  // Group stories by user
  List<Map<String, dynamic>> get _grouped {
    final Map<String, Map<String, dynamic>> map = {};
    for (final s in _stories) {
      final story = Map<String, dynamic>.from(s);
      final user  = Map<String, dynamic>.from(story['user'] as Map? ?? {});
      final uid   = user['id'].toString();
      if (!map.containsKey(uid)) {
        map[uid] = {'user': user, 'stories': [], 'has_unviewed': false};
      }
      (map[uid]!['stories'] as List).add(story);
      if (story['viewed'] != true) map[uid]!['has_unviewed'] = true;
    }
    // Sort: unviewed first
    final list = map.values.toList();
    list.sort((a, b) => (b['has_unviewed'] ? 1 : 0) - (a['has_unviewed'] ? 1 : 0));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isDark  = theme.brightness == Brightness.dark;
    final bg      = theme.scaffoldBackgroundColor;
    final textPri = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final textMut = isDark ? AppTheme.textMuted   : AppTheme.textMutedLight;
    final myUser  = context.watch<AuthProvider>().user ?? {};
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Stories', style: TextStyle(color: textPri)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 28),
            onPressed: () => _showCreateStory(context, myUser, isDark),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : RefreshIndicator(
            color: AppTheme.primary,
            backgroundColor: theme.cardColor,
            onRefresh: _load,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── My story + horizontal strip ──────────────────────────────
                SliverToBoxAdapter(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          // My story bubble
                          _MyStoryBubble(
                            user: myUser,
                            isDark: isDark,
                            onTap: () => _showCreateStory(context, myUser, isDark),
                          ),
                          // Other users' stories
                          ...grouped.map((g) => _StoryBubble(
                            group: g,
                            isDark: isDark,
                            onTap: () => _openViewer(context, g),
                          )),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: isDark ? AppTheme.divider : AppTheme.dividerLight),
                    const SizedBox(height: 8),
                  ]),
                ),

                // ── Story list ────────────────────────────────────────────────
                grouped.isEmpty
                  ? SliverFillRemaining(
                      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.auto_stories_outlined, size: 64,
                          color: textMut.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text('No stories yet', style: TextStyle(color: textMut, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Be the first to share one!',
                          style: TextStyle(color: textMut.withOpacity(0.6), fontSize: 13)),
                      ])),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final g       = grouped[i];
                          final user    = g['user'] as Map<String, dynamic>;
                          final stories = g['stories'] as List;
                          final unviewed = g['has_unviewed'] as bool;
                          final avatar  = user['avatar_url'] ?? '';
                          final latest  = Map<String, dynamic>.from(stories.first as Map);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            onTap: () => _openViewer(context, g),
                            leading: _StoryRing(
                              avatarUrl: avatar,
                              hasUnviewed: unviewed,
                              size: 52,
                            ),
                            title: Text(user['name'] ?? 'User',
                              style: TextStyle(
                                color: textPri,
                                fontWeight: unviewed ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 15)),
                            subtitle: Row(children: [
                              Text(
                                latest['type'] == 'image' ? '📷 Photo' : (latest['content'] ?? ''),
                                style: TextStyle(color: textMut, fontSize: 12),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(width: 6),
                              Text('· ${stories.length} ${stories.length == 1 ? 'story' : 'stories'}',
                                style: TextStyle(color: textMut.withOpacity(0.6), fontSize: 11)),
                            ]),
                            trailing: unviewed
                              ? Container(width: 10, height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary, shape: BoxShape.circle))
                              : Icon(Icons.check_circle_outline, color: textMut, size: 18),
                          );
                        },
                        childCount: grouped.length,
                      ),
                    ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
    );
  }

  void _openViewer(BuildContext context, Map<String, dynamic> group) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => StoryViewerScreen(group: group, onDone: _load)));
  }

  void _showCreateStory(BuildContext context, Map<String, dynamic> myUser, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.bgCard : AppTheme.bgCardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => CreateStorySheet(onCreated: _load),
    );
  }
}

// ── Story ring widget ─────────────────────────────────────────────────────────

class _StoryRing extends StatelessWidget {
  final String avatarUrl;
  final bool hasUnviewed;
  final double size;

  const _StoryRing({
    required this.avatarUrl,
    required this.hasUnviewed,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final inputBg = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.bgInput : AppTheme.bgInputLight;

    return Container(
      width: size, height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasUnviewed
          ? const LinearGradient(
              colors: [AppTheme.primary, AppTheme.accent],
              begin: Alignment.topLeft, end: Alignment.bottomRight)
          : null,
        color: hasUnviewed ? null : inputBg,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).scaffoldBackgroundColor),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: avatarUrl.isNotEmpty
            ? Image.network(avatarUrl, fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, __, ___) => Icon(Icons.person,
                  color: inputBg, size: size * 0.4))
            : Icon(Icons.person, color: inputBg, size: size * 0.4),
        ),
      ),
    );
  }
}

// ── My story bubble ───────────────────────────────────────────────────────────

class _MyStoryBubble extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  final VoidCallback onTap;

  const _MyStoryBubble({required this.user, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final inputBg = isDark ? AppTheme.bgInput : AppTheme.bgInputLight;
    final textMut = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70, margin: const EdgeInsets.only(right: 12),
        child: Column(children: [
          Stack(children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: inputBg, shape: BoxShape.circle),
              child: ClipOval(
                child: (user['avatar_url'] ?? '').isNotEmpty
                  ? Image.network(user['avatar_url'], fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      errorBuilder: (_, __, ___) => Icon(Icons.person, color: textMut))
                  : Icon(Icons.person, color: textMut, size: 28),
              ),
            ),
            Positioned(bottom: 0, right: 0,
              child: Container(
                width: 22, height: 22,
                decoration: const BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                child: const Icon(Icons.add, size: 14, color: Colors.white))),
          ]),
          const SizedBox(height: 5),
          Text('My Story',
            style: TextStyle(color: textMut, fontSize: 11),
            overflow: TextOverflow.ellipsis, maxLines: 1),
        ]),
      ),
    );
  }
}

// ── Other user story bubble ───────────────────────────────────────────────────

class _StoryBubble extends StatelessWidget {
  final Map<String, dynamic> group;
  final bool isDark;
  final VoidCallback onTap;

  const _StoryBubble({required this.group, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final user       = group['user'] as Map<String, dynamic>;
    final hasUnviewed = group['has_unviewed'] as bool;
    final textMut    = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;
    final name       = (user['name'] ?? 'User').toString().split(' ').first;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70, margin: const EdgeInsets.only(right: 12),
        child: Column(children: [
          _StoryRing(avatarUrl: user['avatar_url'] ?? '', hasUnviewed: hasUnviewed, size: 60),
          const SizedBox(height: 5),
          Text(name,
            style: TextStyle(
              color: textMut,
              fontSize: 11,
              fontWeight: hasUnviewed ? FontWeight.w700 : FontWeight.normal),
            overflow: TextOverflow.ellipsis, maxLines: 1),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STORY VIEWER
// ══════════════════════════════════════════════════════════════════════════════

class StoryViewerScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  final VoidCallback onDone;

  const StoryViewerScreen({super.key, required this.group, required this.onDone});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  late AnimationController _progressCtrl;
  static const _duration = Duration(seconds: 5);

  List<dynamic> get _stories => widget.group['stories'] as List;
  Map<String, dynamic> get _story => Map<String, dynamic>.from(_stories[_current] as Map);

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this, duration: _duration);
    _startProgress();
    _markViewed();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  void _startProgress() {
    _progressCtrl.forward(from: 0);
    _progressCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _next();
    });
  }

  void _markViewed() {
    ApiService.viewStory(int.parse(_story['id'].toString())).catchError((_) {});
  }

  void _next() {
    if (_current < _stories.length - 1) {
      setState(() => _current++);
      _progressCtrl.removeStatusListener((_) {});
      _startProgress();
      _markViewed();
    } else {
      widget.onDone();
      Navigator.pop(context);
    }
  }

  void _prev() {
    if (_current > 0) {
      setState(() => _current--);
      _progressCtrl.removeStatusListener((_) {});
      _startProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user    = Map<String, dynamic>.from(widget.group['user'] as Map);
    final story   = _story;
    final isImage = story['type'] == 'image';
    final bgColor = story['bg_color'] ?? '#6C63FF';

    Color parsedBg;
    try {
      parsedBg = Color(int.parse(bgColor.replaceAll('#', '0xFF')));
    } catch (_) {
      parsedBg = AppTheme.primary;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (d) {
          final x = d.localPosition.dx;
          final w = MediaQuery.of(context).size.width;
          if (x < w / 3) _prev(); else _next();
        },
        child: Stack(fit: StackFit.expand, children: [
          // ── Background / content ─────────────────────────────────────────
          isImage
            ? Image.network(
                story['media_url'] ?? story['content'] ?? '',
                fit: BoxFit.contain,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, __, ___) => Container(color: parsedBg,
                  child: const Center(child: Icon(Icons.broken_image_outlined,
                    color: Colors.white54, size: 64))),
              )
            : Container(
                color: parsedBg,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      story['content'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

          // ── Gradient overlays ────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0, height: 120,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent])),
            ),
          ),

          // ── Progress bars ────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12, right: 12,
            child: Row(children: List.generate(_stories.length, (i) => Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
                child: i < _current
                  ? Container(decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(2)))
                  : i == _current
                    ? AnimatedBuilder(
                        animation: _progressCtrl,
                        builder: (_, __) => FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressCtrl.value,
                          child: Container(decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(2)))))
                    : const SizedBox.shrink(),
              ),
            ))),
          ),

          // ── Top bar: user info + close ────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 12, right: 12,
            child: Row(children: [
              _StoryRing(avatarUrl: user['avatar_url'] ?? '', hasUnviewed: false, size: 38),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user['name'] ?? '', style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                Text(_timeAgo(story['created_at']),
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ])),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () { widget.onDone(); Navigator.pop(context); }),
            ]),
          ),
        ]),
      ),
    );
  }

  String _timeAgo(dynamic raw) {
    if (raw == null) return '';
    final t = DateTime.tryParse(raw.toString());
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CREATE STORY SHEET
// ══════════════════════════════════════════════════════════════════════════════

class CreateStorySheet extends StatefulWidget {
  final VoidCallback onCreated;
  const CreateStorySheet({super.key, required this.onCreated});

  @override
  State<CreateStorySheet> createState() => _CreateStorySheetState();
}

class _CreateStorySheetState extends State<CreateStorySheet> {
  final _textCtrl   = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _posting     = false;
  String _mode      = 'text'; // 'text' or 'image'
  Uint8List? _imageBytes;
  String? _imageFilename;

  // Background color options for text stories
  final List<Color> _bgColors = [
    AppTheme.primary,
    const Color(0xFF00D4AA),
    const Color(0xFFFF6B6B),
    const Color(0xFF1A1A2E),
    const Color(0xFF16213E),
    const Color(0xFFE94560),
    const Color(0xFF0F3460),
    const Color(0xFF533483),
  ];
  int _selectedBg = 0;

  @override
  void dispose() { _textCtrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes    = bytes;
      _imageFilename = picked.name;
      _mode          = 'image';
    });
  }

  Future<void> _post() async {
    if (_mode == 'text' && _textCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Write something first!'),
        backgroundColor: AppTheme.accentWarm));
      return;
    }

    setState(() => _posting = true);
    try {
      if (_mode == 'image' && _imageBytes != null) {
        final url = await ApiService.uploadImageBytes(_imageBytes!, _imageFilename ?? 'story.jpg');
        await ApiService.createStory(type: 'image', mediaUrl: url);
      } else {
        final hex = '#${_bgColors[_selectedBg].value.toRadixString(16).substring(2).toUpperCase()}';
        await ApiService.createStory(
          type: 'text',
          content: _textCtrl.text.trim(),
          bgColor: hex,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Story posted! 🎉'),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message), backgroundColor: AppTheme.accentWarm));
    } finally {
      setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final cardBg  = isDark ? AppTheme.bgCard    : AppTheme.bgCardLight;
    final inputBg = isDark ? AppTheme.bgInput   : AppTheme.bgInputLight;
    final textPri = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final textMut = isDark ? AppTheme.textMuted   : AppTheme.textMutedLight;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: textMut, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          // Title + type toggle
          Row(children: [
            Text('New Story', style: TextStyle(
              color: textPri, fontSize: 20, fontWeight: FontWeight.w700)),
            const Spacer(),
            // Text/Image toggle
            Container(
              decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _TypeBtn(label: '✏️ Text',  selected: _mode == 'text',
                  onTap: () => setState(() => _mode = 'text')),
                _TypeBtn(label: '📷 Photo', selected: _mode == 'image',
                  onTap: _pickImage),
              ]),
            ),
          ]),

          const SizedBox(height: 20),

          // Preview / input
          if (_mode == 'image' && _imageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(_imageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.swap_horiz, color: AppTheme.primary),
              label: const Text('Change photo', style: TextStyle(color: AppTheme.primary))),
          ] else if (_mode == 'image') ...[
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: inputBg, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 2,
                    style: BorderStyle.solid)),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_photo_alternate_outlined,
                    color: AppTheme.primary, size: 40),
                  const SizedBox(height: 8),
                  Text('Tap to pick a photo',
                    style: TextStyle(color: textMut, fontSize: 14)),
                ]))),
            ),
          ] else ...[
            // Text story preview
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: _bgColors[_selectedBg],
                borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextField(
                  controller: _textCtrl,
                  onChanged: (_) => setState(() {}),
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: 'What\'s on your mind?',
                    hintStyle: TextStyle(color: Colors.white54, fontSize: 18),
                    border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Color picker
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _bgColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _selectedBg = i),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _bgColors[i],
                      shape: BoxShape.circle,
                      border: i == _selectedBg
                        ? Border.all(color: Colors.white, width: 3)
                        : null),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Post button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _posting ? null : _post,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _posting
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Post Story',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(
        color: selected ? Colors.white : AppTheme.textMuted,
        fontSize: 13, fontWeight: FontWeight.w600)),
    ),
  );
}
