import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text('Stories'),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt_outlined), onPressed: () {}),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // My story
          _MyStoryTile(),
          const SizedBox(height: 8),
          _sectionHeader('Recent Updates'),
          ...sampleUsers.take(4).map((u) => _StoryTile(user: u)),
          _sectionHeader('Viewed'),
          ...sampleUsers.skip(4).map((u) => _StoryTile(user: u, viewed: true)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _MyStoryTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.bgInput, width: 2),
            ),
            child: CircleAvatar(
              backgroundImage: NetworkImage(currentUser.avatarUrl),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
      title: const Text(
        'My Story',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: const Text(
        'Add to your story',
        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
      ),
    );
  }
}

class _StoryTile extends StatelessWidget {
  final User user;
  final bool viewed;

  const _StoryTile({required this.user, this.viewed = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 52,
        height: 52,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: viewed
              ? null
              : const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: viewed ? AppTheme.bgInput : null,
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.bgDark,
          ),
          padding: const EdgeInsets.all(2),
          child: CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl)),
        ),
      ),
      title: Text(
        user.name,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        '${(DateTime.now().difference(user.lastSeen).inMinutes)} min ago',
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
      ),
      trailing: const Icon(Icons.more_vert, color: AppTheme.textMuted, size: 20),
    );
  }
}
