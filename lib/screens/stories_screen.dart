import 'package:flutter/material.dart';
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
    try { _stories = await ApiService.getStories(); } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isDark  = theme.brightness == Brightness.dark;
    final bg      = theme.scaffoldBackgroundColor;
    final textPri = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final textMut = isDark ? AppTheme.textMuted    : AppTheme.textMutedLight;

    final viewed   = _stories.where((s) => s['viewed'] == true).toList();
    final unviewed = _stories.where((s) => s['viewed'] != true).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Stories', style: TextStyle(color: textPri)),
        actions: [
          IconButton(icon: Icon(Icons.camera_alt_outlined, color: textPri), onPressed: () {}),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : RefreshIndicator(
            color: AppTheme.primary, backgroundColor: theme.cardColor, onRefresh: _load,
            child: ListView(physics: const BouncingScrollPhysics(), children: [
              _MyStoryTile(isDark: isDark),
              if (unviewed.isNotEmpty) ...[
                _header('Recent Updates', textMut),
                ...unviewed.map((s) => _StoryTile(story: Map<String, dynamic>.from(s as Map), viewed: false, isDark: isDark, onView: _load)),
              ],
              if (viewed.isNotEmpty) ...[
                _header('Viewed', textMut),
                ...viewed.map((s) => _StoryTile(story: Map<String, dynamic>.from(s as Map), viewed: true, isDark: isDark, onView: _load)),
              ],
              if (_stories.isEmpty)
                Padding(padding: const EdgeInsets.all(40),
                  child: Center(child: Text('No stories yet', style: TextStyle(color: textMut, fontSize: 16)))),
              const SizedBox(height: 80),
            ]),
          ),
    );
  }

  Widget _header(String label, Color textMut) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(label.toUpperCase(), style: TextStyle(
      color: textMut, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)));
}

class _MyStoryTile extends StatelessWidget {
  final bool isDark;
  const _MyStoryTile({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPri = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final textMut = isDark ? AppTheme.textMuted    : AppTheme.textMutedLight;
    final inputBg = isDark ? AppTheme.bgInput      : AppTheme.bgInputLight;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: inputBg, width: 2)),
          child: CircleAvatar(backgroundColor: inputBg, child: Icon(Icons.person, color: textMut))),
        Positioned(bottom: 0, right: 0, child: Container(width: 20, height: 20,
          decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
          child: const Icon(Icons.add, size: 14, color: Colors.white))),
      ]),
      title: Text('My Story', style: TextStyle(color: textPri, fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text('Add to your story', style: TextStyle(color: textMut, fontSize: 12)),
    );
  }
}

class _StoryTile extends StatelessWidget {
  final Map<String, dynamic> story;
  final bool viewed, isDark;
  final VoidCallback onView;
  const _StoryTile({required this.story, required this.viewed, required this.isDark, required this.onView});

  @override
  Widget build(BuildContext context) {
    final user    = story['user'] as Map<String, dynamic>? ?? {};
    final avatar  = user['avatar_url'] ?? '';
    final textPri = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final textMut = isDark ? AppTheme.textMuted    : AppTheme.textMutedLight;
    final inputBg = isDark ? AppTheme.bgInput      : AppTheme.bgInputLight;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () async {
        await ApiService.viewStory(int.parse(story['id'].toString())).catchError((_) {});
        onView();
      },
      leading: Container(width: 52, height: 52, padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: viewed ? null : const LinearGradient(
            colors: [AppTheme.primary, AppTheme.accent],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          color: viewed ? inputBg : null),
        child: Container(decoration: BoxDecoration(shape: BoxShape.circle,
          color: Theme.of(context).scaffoldBackgroundColor), padding: const EdgeInsets.all(2),
          child: CircleAvatar(backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            backgroundColor: inputBg,
            child: avatar.isEmpty ? Icon(Icons.person, color: textMut) : null))),
      title: Text(user['name'] ?? 'User', style: TextStyle(color: textPri, fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(story['content'] ?? '', style: TextStyle(color: textMut, fontSize: 12),
        maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Icon(Icons.more_vert, color: textMut, size: 20),
    );
  }
}
