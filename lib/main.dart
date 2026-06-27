import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/profile_screen.dart';

/// Global navigator key for switching tabs from child screens.
final mainShellKey = GlobalKey<MainShellState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const WevoApp());
}

class WevoApp extends StatelessWidget {
  const WevoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wevo',
      debugShowCheckedModeBanner: false,
      theme: WevoTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }
          if (snapshot.hasData) return MainShell(shellKey: mainShellKey);
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WevoColors.dark,
      body: Center(
        child: Image.asset(
          'assets/images/wevo scritta.PNG',
          height: 80,
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final GlobalKey<MainShellState> shellKey;
  const MainShell({super.key, required this.shellKey});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentTab = 0;

  static MainShellState? _instance;

  MainShellState() { _instance = this; }

  @override
  void initState() {
    super.initState();
  }

  static void switchTab(int tab) {
    _instance?.setState(() => _instance!._currentTab = tab);
  }

  final _screens = const [
    DiscoverScreen(),
    MatchesScreen(),
    ProfileScreen(),
  ];

  // Vibe tags globali condivisi
  static const vibes = {
    'music':  {'label': 'Music',   'color': Color(0xFF8EC5FF)},
    'coffee': {'label': 'Coffee',  'color': Color(0xFFFFC76A)},
    'travel': {'label': 'Travel',  'color': Color(0xFF62E6FF)},
    'books':  {'label': 'Books',   'color': Color(0xFFB98AE6)},
    'gaming': {'label': 'Gaming',  'color': Color(0xFFFF5FA2)},
    'movies': {'label': 'Movies',  'color': Color(0xFF9EDFA6)},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WevoColors.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 768;
          if (isDesktop) {
            return _desktopLayout();
          }
          // Mobile: bottom nav
          return _mobileLayout();
        },
      ),
    );
  }

  Widget _desktopLayout() {
    return Row(
      children: [
        // ── Rail nav (sinistra) ──
        _buildRail(),
        // ── Content with tab transition ──
        Expanded(child: _tabSwitcher()),
      ],
    );
  }

  Widget _mobileLayout() {
    return Scaffold(
      backgroundColor: WevoColors.bg,
      body: _tabSwitcher(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        backgroundColor: WevoColors.darkSoft,
        selectedItemColor: WevoColors.pink,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), activeIcon: Icon(Icons.favorite), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  /// Tab switcher — IndexedStack (nessuna transizione pagine)
  Widget _tabSwitcher() {
    return IndexedStack(index: _currentTab, children: _screens);
  }

  Widget _buildRail() {
    return Container(
      width: 96,
      padding: const EdgeInsets.only(top: 22),
      decoration: BoxDecoration(
        color: WevoColors.darkSoft.withOpacity(0.55),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Column(
        children: [
          // W logo
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [
                Color(0xFFFF5FA2), Color(0xFFB98AE6), Color(0xFF8EC5FF), Color(0xFF5FE0C5),
              ]),
              boxShadow: [BoxShadow(color: WevoColors.pink.withOpacity(0.5), blurRadius: 22)],
            ),
            margin: const EdgeInsets.only(bottom: 34),
            child: const Center(child: Text('w', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white))),
          ),
          // ── Nav buttons con AnimatedContainer ──
          _navBtn(Icons.explore_outlined, Icons.explore, 0, 'Discover'),
          const SizedBox(height: 14),
          _navBtn(Icons.favorite_outline, Icons.favorite, 1, 'Matches'),
          const SizedBox(height: 14),
          _navBtn(Icons.person_outline, Icons.person, 2, 'Profile'),
          const Spacer(),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: WevoColors.textMuted, size: 22),
            onPressed: () {},
          ),
          const SizedBox(height: 14),
          // Avatar
          Container(
            width: 44, height: 44,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [WevoColors.pink, WevoColors.lightBlue]),
            ),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF1A1128),
              child: Text(
                (FirebaseAuth.instance.currentUser?.email ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600, color: Color(0xFFFFB6D4), fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navBtn(IconData inactive, IconData active, int index, String tooltip) {
    final isActive = _currentTab == index;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: 56,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isActive ? WevoColors.pink.withOpacity(0.14) : Colors.transparent,
            boxShadow: isActive
                ? [BoxShadow(color: WevoColors.pink.withOpacity(0.35), blurRadius: 20, spreadRadius: 1)]
                : null,
          ),
          child: Icon(
            isActive ? active : inactive,
            color: isActive ? WevoColors.pink : WevoColors.textMuted,
            size: 24,
          ),
        ),
      ),
    );
  }


}

