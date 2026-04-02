import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/conversations_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/chats_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/stories_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ChatterApp());
}

class ChatterApp extends StatelessWidget {
  const ChatterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConversationsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) {
          return MaterialApp(
            title: 'Chatter',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const _AppGate(),
          );
        },
      ),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();
  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;

    // Update status bar icons to match theme
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    switch (auth.state) {
      case AuthState.unknown:
        return const Scaffold(
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
    final isDark = context.watch<ThemeProvider>().isDark;
    final borderColor = isDark ? AppTheme.divider : AppTheme.dividerLight;
    final bgColor     = isDark ? AppTheme.bgCard  : AppTheme.bgCardLight;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                (Icons.chat_bubble_outlined, Icons.chat_bubble, 'Chats'),
                (Icons.people_outline,       Icons.people,       'People'),
                (Icons.circle_outlined,      Icons.circle,       'Stories'),
                (Icons.person_outline,       Icons.person,       'Profile'),
              ].asMap().entries.map((e) {
                final i = e.key;
                final (outIcon, fillIcon, label) = e.value;
                final selected = i == _currentIndex;
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
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
      ),
    );
  }
}
