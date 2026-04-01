import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/conversations_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/chats_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/stories_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ChatterApp());
}

class ChatterApp extends StatelessWidget {
  const ChatterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConversationsProvider()),
      ],
      child: MaterialApp(
        title: 'Chatter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _AppGate(),
      ),
    );
  }
}

// Decides whether to show login or main shell based on auth state
class _AppGate extends StatefulWidget {
  const _AppGate();
  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  @override
  void initState() {
    super.initState();
    // Load tokens & check session on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.state) {
      case AuthState.unknown:
        return const Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        );
      case AuthState.unauthenticated:
        return const LoginScreen();
      case AuthState.authenticated:
        return const MainShell();
    }
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ChatsScreen(),
    ContactsScreen(),
    StoriesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.chat_bubble_outlined, Icons.chat_bubble, 'Chats'),
      (Icons.people_outline, Icons.people, 'People'),
      (Icons.circle_outlined, Icons.circle, 'Stories'),
      (Icons.person_outline, Icons.person, 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(top: BorderSide(color: AppTheme.divider, width: 0.5))),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final (outIcon, fillIcon, label) = e.value;
              final selected = i == currentIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(selected ? fillIcon : outIcon,
                      color: selected ? AppTheme.primary : AppTheme.textMuted, size: 24),
                    const SizedBox(height: 2),
                    Text(label, style: TextStyle(
                      color: selected ? AppTheme.primary : AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
