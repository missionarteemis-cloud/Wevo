import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/match_service.dart';
import '../theme.dart';
import 'chat_detail_screen.dart';
import 'user_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int _currentIndex = 0;
  double _dragX = 0;
  List<UserModel> _users = [];
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final real = await MatchService.fetchDiscoverFeed();
      final combined = [
        ...real,
        ...mockUsers.where((u) => real.every((r) => r.id != u.id)),
      ];
      if (mounted) setState(() { _users = combined; _loadingUsers = false; });
    } catch (_) {
      if (mounted) setState(() { _users = mockUsers; _loadingUsers = false; });
    }
  }

  void _onSwipe(bool liked) async {
    if (_currentIndex >= _users.length) return;
    final user = _users[_currentIndex];
    bool isMatch = false;
    try {
      isMatch = await MatchService.swipeUser(targetUserId: user.id, liked: liked);
      if (!isMatch && liked) isMatch = await MatchService.ensureMatchIfReciprocal(targetUserId: user.id);
      if (!isMatch && liked) isMatch = await MatchService.alreadyMatchedWith(user.id);
    } catch (_) {}
    if (liked && isMatch && mounted) _showMatchDialog(user);
    if (mounted) setState(() { _dragX = 0; _currentIndex++; });
  }

  void _showMatchDialog(UserModel user) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0A17),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFF6B9D).withOpacity(0.3), blurRadius: 40, spreadRadius: 4),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text("it's a match!", style: TextStyle(color: Color(0xFFFFA1C8), fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: Stack(alignment: Alignment.center, children: [
                Positioned(left: 8, child: _neonAvatar(user.photoUrl, const Color(0xFFFF6B9D), size: 110)),
                Positioned(right: 8, child: _neonAvatar(user.coverUrl, const Color(0xFF5BC0FF), size: 110)),
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: WevoColors.primaryGradient, border: Border.all(color: Colors.white, width: 3)),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 34),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            Text('Tu e ${user.name} avete la stessa vibe 💗', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: WevoColors.primaryGradient, borderRadius: BorderRadius.circular(28)),
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(user: user))); },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Start Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe later', style: TextStyle(color: Colors.white54))),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset('assets/images/wevo_scritta_nobg.png', height: 28),
        actions: [
          IconButton(icon: const Icon(Icons.tune, color: Color(0xFFFF6B9D)), onPressed: () {}),
        ],
      ),
      body: _loadingUsers
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B9D)))
          : _currentIndex >= _users.length
              ? _emptyState()
              : _cardStack(),
    );
  }

  Widget _emptyState() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.auto_awesome, size: 80, color: const Color(0xFFFF6B9D).withOpacity(0.6)),
      const SizedBox(height: 16),
      const Text('Hai visto tutti.\nRicarichiamo presto nuove vibe.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white70)),
    ]));
  }

  Widget _cardStack() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_currentIndex + 1 < _users.length)
                Positioned(
                  top: 0,
                  child: _ProfileCard(user: _users[_currentIndex + 1], scale: 0.92, opacity: 0.35, dragX: 0, isBack: true),
                ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserDetailScreen(user: _users[_currentIndex], onDecision: _onSwipe)),
                ),
                onHorizontalDragUpdate: (d) => setState(() => _dragX += d.delta.dx),
                onHorizontalDragEnd: (d) {
                  if (_dragX > 80) _onSwipe(true);
                  else if (_dragX < -80) _onSwipe(false);
                  else setState(() => _dragX = 0);
                },
                child: _ProfileCard(user: _users[_currentIndex], scale: 1.0, opacity: 1.0, dragX: _dragX, isBack: false),
              ),
            ],
          ),
        ),
        _actionButtons(),
      ],
    );
  }

  Widget _actionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _actionBtn(Icons.close, const Color(0xFFFF5E7D), 56, () => _onSwipe(false)),
          const SizedBox(width: 24),
          _actionBtn(Icons.favorite, const Color(0xFFFF6B9D), 72, () => _onSwipe(true)),
          const SizedBox(width: 24),
          _actionBtn(Icons.flash_on, const Color(0xFFFFC107), 56, () => _onSwipe(true)),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, double size, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1525),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.45)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 16)],
        ),
        child: Icon(icon, color: color, size: size * 0.46),
      ),
    );
  }

  Widget _neonAvatar(String url, Color glow, {double size = 110}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: glow, width: 3),
        boxShadow: [BoxShadow(color: glow.withOpacity(0.5), blurRadius: 26)],
      ),
      child: CircleAvatar(radius: size / 2, backgroundImage: NetworkImage(url)),
    );
  }
}

// ── Card swipe semplice: foto full + nome/età in overlay ──────────────────

class _ProfileCard extends StatelessWidget {
  final UserModel user;
  final double scale;
  final double opacity;
  final double dragX;
  final bool isBack;

  const _ProfileCard({
    required this.user,
    required this.scale,
    required this.opacity,
    required this.dragX,
    this.isBack = false,
  });

  @override
  Widget build(BuildContext context) {
    final angle = dragX / 900;
    final screenW = MediaQuery.of(context).size.width;
    final cardW = screenW > 600 ? 400.0 : screenW * 0.88;
    final cardH = MediaQuery.of(context).size.height * 0.64;

    return Transform(
      transform: Matrix4.identity()
        ..translate(dragX, 0)
        ..rotateZ(angle)
        ..scale(scale),
      alignment: Alignment.center,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: cardW,
          height: cardH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 28, offset: const Offset(0, 14)),
              BoxShadow(color: const Color(0xFFFF6B9D).withOpacity(isBack ? 0 : 0.25), blurRadius: 22),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Cover image ──
                if (user.coverUrl.isNotEmpty)
                  Image.network(user.coverUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultBg())
                else if (user.photoUrl.isNotEmpty)
                  Image.network(user.photoUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultBg())
                else
                  _defaultBg(),

                // ── Gradient overlay from bottom ──
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),

                // ── Name + age + info in basso ──
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${user.name}, ${user.age}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (user.country.isNotEmpty) ...[
                            Icon(Icons.location_on, color: Colors.white54, size: 14),
                            const SizedBox(width: 4),
                            Text(user.country, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                          if (user.favoriteGames.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.sports_esports, color: Colors.white54, size: 14),
                            const SizedBox(width: 4),
                            Text(user.favoriteGames.take(2).join(', '), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultBg() => Container(color: const Color(0xFF1A1525));
}

// ── Mock users (fallback) ───────────────────────────────────────────────────

final List<UserModel> mockUsers = [
  UserModel(
    id: 'mock_sofia',
    name: 'Sofia',
    username: 'sofia_music',
    photoUrl: '',
    coverUrl: '',
    bio: 'Music lover, coffee addict, movie nights & spontaneous trips. ❤️',
    age: 24,
    country: 'Los Angeles, CA',
    interests: ['Music', 'Coffee', 'Travel', 'Books', 'Gaming'],
    favoriteGames: ['Valorant', 'LoL'],
    platforms: ['PC', 'PlayStation'],
    lookingFor: ['Friendship', 'Chill'],
  ),
  UserModel(
    id: 'mock_alex',
    name: 'Alex',
    username: 'alex_gaming',
    photoUrl: '',
    coverUrl: '',
    bio: 'Ranked grinder by night, coffee brewer by day. Let\'s duo.',
    age: 22,
    country: 'Rome, Italy',
    interests: ['Gaming', 'Coffee', 'Music'],
    favoriteGames: ['Apex', 'Fortnite'],
    platforms: ['PC', 'Xbox'],
    lookingFor: ['Ranked', 'Duo'],
  ),
  UserModel(
    id: 'mock_kira',
    name: 'Kira',
    username: 'kira_books',
    photoUrl: '',
    coverUrl: '',
    bio: 'Books, cats, and co-op games. Simple life.',
    age: 21,
    country: 'Tokyo, Japan',
    interests: ['Books', 'Gaming', 'Design'],
    favoriteGames: ['Stardew Valley', 'It Takes Two'],
    platforms: ['Switch', 'Mobile'],
    lookingFor: ['Friendship', 'Chill'],
  ),
];
