import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

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
    final viewed   = _stories.where((s) => s['viewed'] == true).toList();
    final unviewed = _stories.where((s) => s['viewed'] != true).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(backgroundColor: AppTheme.bgDark, title: const Text('Stories'),
        actions: [IconButton(icon: const Icon(Icons.camera_alt_outlined), onPressed: () {}), const SizedBox(width: 4)]),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : RefreshIndicator(
            color: AppTheme.primary, backgroundColor: AppTheme.bgCard, onRefresh: _load,
            child: ListView(physics: const BouncingScrollPhysics(), children: [
              _MyStoryTile(),
              if (unviewed.isNotEmpty) ...[
                _header('Recent Updates'),
                ...unviewed.map((s) => _StoryTile(story: s, viewed: false, onView: _load)),
              ],
              if (viewed.isNotEmpty) ...[
                _header('Viewed'),
                ...viewed.map((s) => _StoryTile(story: s, viewed: true, onView: _load)),
              ],
              if (_stories.isEmpty)
                const Padding(padding: EdgeInsets.all(40),
                  child: Center(child: Text('No stories yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)))),
              const SizedBox(height: 80),
            ]),
          ),
    );
  }

  Widget _header(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(label.toUpperCase(), style: const TextStyle(
      color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)));
}

class _MyStoryTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    leading: Stack(children: [
      Container(width: 52, height: 52,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.bgInput, width: 2)),
        child: const CircleAvatar(backgroundColor: AppTheme.bgInput,
          child: Icon(Icons.person, color: AppTheme.textMuted))),
      Positioned(bottom: 0, right: 0, child: Container(width: 20, height: 20,
        decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
        child: const Icon(Icons.add, size: 14, color: Colors.white))),
    ]),
    title: const Text('My Story', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
    subtitle: const Text('Add to your story', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
  );
}

class _StoryTile extends StatelessWidget {
  final Map<String, dynamic> story;
  final bool viewed;
  final VoidCallback onView;
  const _StoryTile({required this.story, required this.viewed, required this.onView});

  @override
  Widget build(BuildContext context) {
    final user = story['user'] as Map<String, dynamic>? ?? {};
    final avatar = user['avatar_url'] ?? '';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () async {
        await ApiService.viewStory(story['id']).catchError((_) {});
        onView();
      },
      leading: Container(width: 52, height: 52, padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: viewed ? null : const LinearGradient(
            colors: [AppTheme.primary, AppTheme.accent],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          color: viewed ? AppTheme.bgInput : null),
        child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.bgDark), padding: const EdgeInsets.all(2),
          child: CircleAvatar(backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            backgroundColor: AppTheme.bgInput,
            child: avatar.isEmpty ? const Icon(Icons.person, color: AppTheme.textMuted) : null))),
      title: Text(user['name'] ?? 'User', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(story['content'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.more_vert, color: AppTheme.textMuted, size: 20),
    );
  }
}
