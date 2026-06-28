import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/match_service.dart';
import '../theme.dart';
import '../main.dart';
import '../widgets/wevo_buttons.dart';

// Icone per vibe — mappate dal nome del tag
IconData _vibeIcon(String label) {
  switch (label) {
    case 'Music': case 'FPS': return Icons.headphones;
    case 'Coffee': return Icons.coffee_outlined;
    case 'Travel': return Icons.flight_takeoff_outlined;
    case 'Books': return Icons.menu_book_outlined;
    case 'Gaming': case 'Arcade': case 'Fighting': case 'Retro':
      return Icons.sports_esports_outlined;
    case 'Movies': return Icons.movie_outlined;
    case 'MOBA': return Icons.sports_esports_outlined;
    case 'Co-op': case 'Cozy': return Icons.people_outline;
    case 'Anime': return Icons.auto_awesome;
    case 'Tech': return Icons.computer;
    case 'Design': return Icons.palette_outlined;
    case 'Community': return Icons.group_outlined;
    case 'Chill': return Icons.wb_sunny_outlined;
    case 'Chat': return Icons.chat_outlined;
    default: return Icons.auto_awesome;
  }
}

const _vibeColors = {
  'Music': Color(0xFF8EC5FF),
  'Coffee': Color(0xFFFFC76A),
  'Travel': Color(0xFF62E6FF),
  'Books': Color(0xFFB98AE6),
  'Gaming': Color(0xFFFF5FA2),
  'Movies': Color(0xFF9EDFA6),
  'FPS': Color(0xFFFF7D7D),
  'MOBA': Color(0xFFBE7CFF),
  'Co-op': Color(0xFFFFC76A),
  'Anime': Color(0xFFFFB6D4),
  'Tech': Color(0xFF8EC5FF),
  'Design': Color(0xFFB98AE6),
  'Community': Color(0xFF9EDFA6),
  'Chill': Color(0xFF62E6FF),
  'Chat': Color(0xFFFFB6D4),
};

Color _vibeColor(String label) => _vibeColors[label] ?? WevoColors.pink;

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with TickerProviderStateMixin {
  int _index = 0;
  double _dragX = 0;
  bool _swiping = false;
  List<UserModel> _users = [];
  bool _loading = true;
  bool _showMatch = false;
  UserModel? _matchedUser;

  // Swipe animation
  late final AnimationController _swipeCtrl;
  late final Animation<double> _swipeAnim;
  bool _swipeLiked = false;

  // Match overlay controllers
  late final AnimationController _matchCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _sparkleCtrl;

  late final Animation<double> _avatarSlide;
  late final Animation<double> _heartScale;
  late final Animation<double> _rippleScale;
  late final Animation<double> _rippleOpa;
  late final Animation<double> _titleOpa;
  late final Animation<double> _titleY;
  late final Animation<double> _subOpa;
  late final Animation<double> _subY;
  late final Animation<double> _chipsOpa;
  late final Animation<double> _ctaOpa;
  late final Animation<double> _ctaY;

  @override
  void initState() {
    super.initState();

    _swipeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..addListener(() => setState(() {}));

    _swipeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _swipeCtrl, curve: Curves.easeInOutCubic),
    );

    _swipeCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _index++;
          _dragX = 0;
          _swiping = false;
          _swipeCtrl.reset();
        });
      }
    });

    _matchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addListener(_onMatchAnim);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _avatarSlide = Tween<double>(begin: -110, end: 0).animate(
      CurvedAnimation(
        parent: _matchCtrl,
        curve: const Interval(0.0, 0.34, curve: Curves.easeOutCubic),
      ),
    );

    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.15, end: 1.22)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.22, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _matchCtrl,
        curve: const Interval(0.24, 0.56),
      ),
    );

    _rippleScale = Tween<double>(begin: 0.3, end: 2.15).animate(
      CurvedAnimation(
        parent: _matchCtrl,
        curve: const Interval(0.26, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    _rippleOpa = Tween<double>(begin: 0.55, end: 0).animate(
      CurvedAnimation(
        parent: _matchCtrl,
        curve: const Interval(0.26, 0.62, curve: Curves.easeOut),
      ),
    );

    _titleOpa = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _matchCtrl,
        curve: const Interval(0.42, 0.67, curve: Curves.easeOut),
      ),
    );

    _titleY = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _matchCtrl,
        curve: const Interval(0.42, 0.67, curve: Curves.easeOutCubic),
      ),
    );

    _subOpa = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _matchCtrl,
        curve: const Interval(0.60, 0.80, curve: Curves.easeOut),
      ),
    );

    _subY = Tween<double>(begin: 12, end: 0).animate(
      CurvedAnimation(
        parent: _matchCtrl,
        curve: const Interval(0.60, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    _chipsOpa = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _matchCtrl,
        curve: const Interval(0.70, 0.90, curve: Curves.easeOut),
      ),
    );

    _ctaOpa = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _matchCtrl,
        curve: const Interval(0.64, 1.0, curve: Curves.easeOut),
      ),
    );

    _ctaY = Tween<double>(begin: 34, end: 0).animate(
      CurvedAnimation(
        parent: _matchCtrl,
        curve: const Interval(0.64, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _load();
  }

  void _onMatchAnim() {
    if (_showMatch) setState(() {});
  }

  Future<void> _load() async {
    try {
      final users = await MatchService.fetchDiscoverFeed().timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _users = const [];
        _loading = false;
      });
    }
  }

  Future<void> _swipe(bool liked) async {
    if (_index >= _users.length || _swiping) return;
    final user = _users[_index];
    setState(() {
      _swiping = true;
      _swipeLiked = liked;
    });

    bool isMatch = false;
    try {
      isMatch = await MatchService.swipeUser(targetUserId: user.id, liked: liked);
    } catch (_) {
      isMatch = false;
    }

    if (!mounted) return;

    if (isMatch) {
      setState(() {
        _matchedUser = user;
        _showMatch = true;
        _swiping = false;
        _dragX = 0;
      });
      _matchCtrl.forward(from: 0);
      return;
    }

    setState(() {
      _dragX = liked ? 400 : -400;
    });
    _swipeCtrl.forward(from: 0);
  }

  void _closeMatchAndContinue() {
    setState(() { _showMatch = false; _index++; _matchedUser = null; _dragX = 0; });
  }

  void _closeMatchKeepCurrent() {
    setState(() { _showMatch = false; _matchedUser = null; });
  }

  UserModel? get _current => _index < _users.length ? _users[_index] : null;
  UserModel? get _next => _index + 1 < _users.length ? _users[_index + 1] : null;

  double get _matchPct {
    final u = _current;
    if (u == null) return 0;
    final shared = u.interests.where((i) => _allInterests.contains(i)).length;
    return (72 + shared * 8).clamp(0, 98).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: WevoColors.pink));
    }

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 768;
            if (isDesktop) return _desktopLayout();
            return _mobileLayout();
          },
        ),
        // Match overlay
        if (_showMatch && _matchedUser != null) IgnorePointer(
          ignoring: false,
          child: _matchOverlay(),
        ),
      ],
    );
  }

  // ── MOBILE: deck full width ──
  Widget _mobileLayout() {
    if (_index >= _users.length) return _emptyState();
    return Column(
      children: [
        _header(),
        Expanded(child: _deck()),
        _actionButtons(),
      ],
    );
  }

  // ── DESKTOP: deck a sinistra + dettaglio a destra ──
  Widget _desktopLayout() {
    if (_index >= _users.length) {
      // Tutto esaurito: empty state al centro
      return Center(
        child: SizedBox(
          width: 480,
          child: _emptyState(),
        ),
      );
    }
    return Row(
      children: [
        // Deck column
        SizedBox(
          width: 480,
          child: Column(
            children: [
              _header(),
              Expanded(child: _deck()),
              _actionButtons(),
              const SizedBox(height: 26),
            ],
          ),
        ),
        // Detail column
        Container(width: 1, color: Colors.white.withOpacity(0.06)),
        Expanded(child: _current != null ? _detailPanel() : _emptyState()),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => MainShellState.switchTab(0),
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(colors: [
                WevoColors.pink, Color(0xFFB98AE6), Color(0xFF8EC5FF), Color(0xFF5FE0C5),
              ]).createShader(r),
              child: const Text('wevo', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 30, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          Text('Discover', style: TextStyle(color: WevoColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84, height: 84,
            decoration: BoxDecoration(shape: BoxShape.circle, color: WevoColors.pink.withOpacity(0.12)),
            child: const Icon(Icons.favorite, color: WevoColors.pink, size: 38),
          ),
          const SizedBox(height: 22),
          const Text("Per ora è tutto!", style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          const Text("Torna più tardi per nuove vibe vicino a te.", style: TextStyle(color: WevoColors.textMuted, fontSize: 14)),
          const SizedBox(height: 18),
          WevoGradientButton(
            label: 'Ricomincia',
            size: WevoSize.m,
            onPressed: () {
              setState(() {
                _index = 0;
                _loading = true;
              });
              _load();
            },
          ),
        ],
      ),
    );
  }

  Widget _deck() {
    final useDrag = _swiping ? _swipeAnim.value * (_swipeLiked ? 400 : -400) : _dragX;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_next != null) _profileCard(_next!, 0.92, 0.35, 0, isBack: true),
        GestureDetector(
          onTap: () {},
          onHorizontalDragUpdate: _swiping
            ? null
            : (d) => setState(() => _dragX += d.delta.dx),
          onHorizontalDragEnd: _swiping
            ? null
            : (d) {
                if (_dragX > 100) _swipe(true);
                else if (_dragX < -100) _swipe(false);
                else setState(() => _dragX = 0);
              },
          child: _profileCard(_current!, 1.0, 1.0, useDrag, isBack: false),
        ),
      ],
    );
  }

  Widget _profileCard(UserModel user, double scale, double opacity, double dragX, {bool isBack = false}) {
    final angle = dragX / 800;
    return Transform(
      transform: Matrix4.identity()..translate(dragX, 0)..rotateZ(angle)..scale(scale),
      alignment: Alignment.center,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 380,
          height: 520,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 60, offset: const Offset(0, 24)),
              BoxShadow(color: WevoColors.pink.withOpacity(isBack ? 0 : 0.3), blurRadius: 40),
            ],
            gradient: LinearGradient(
              colors: [
                Color(0xFF2A1A3E), Color(0xFF1A0F2A),
              ],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Cover
                if (user.coverUrl.isNotEmpty)
                  Image.network(user.coverUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                // Overlay gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
                // Online badge
                Positioned(
                  top: 18, left: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E0718).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF9EDFA6), boxShadow: [BoxShadow(color: Color(0xFF9EDFA6), blurRadius: 8)])),
                        const SizedBox(width: 6),
                        const Text('Online', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9EDFA6))),
                      ],
                    ),
                  ),
                ),
                // Match % badge
                Positioned(
                  top: 18, right: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E0718).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, color: WevoColors.pink, size: 13),
                        const SizedBox(width: 4),
                        Text('${_matchPct.toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                // Like/Nope stamp
                if (dragX > 50)
                  Positioned(
                    top: 46, left: 30,
                    child: Transform.rotate(
                      angle: -0.3,
                      child: Opacity(
                        opacity: ((dragX - 50) / 80).clamp(0, 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF5FE0C5), width: 4),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: const Color(0xFF5FE0C5).withOpacity(0.4), blurRadius: 22)],
                          ),
                          child: const Text('LIKE', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 34, fontWeight: FontWeight.w700, color: Color(0xFF5FE0C5))),
                        ),
                      ),
                    ),
                  ),
                if (dragX < -50)
                  Positioned(
                    top: 46, right: 30,
                    child: Transform.rotate(
                      angle: 0.3,
                      child: Opacity(
                        opacity: ((-dragX - 50) / 80).clamp(0, 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFFF7D7D), width: 4),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: const Color(0xFFFF7D7D).withOpacity(0.4), blurRadius: 22)],
                          ),
                          child: const Text('NOPE', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 34, fontWeight: FontWeight.w700, color: Color(0xFFFF7D7D))),
                        ),
                      ),
                    ),
                  ),
                // Bottom info
                Positioned(
                  left: 22, right: 22, bottom: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text('${user.name}, ${user.age}', style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 30, fontWeight: FontWeight.w600, color: Colors.white)),
                          const SizedBox(width: 8),
                          Icon(Icons.verified, color: const Color(0xFF62E6FF), size: 22),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: const Color(0xFFB98AE6), size: 15),
                          const SizedBox(width: 4),
                          Text(user.country.isNotEmpty ? user.country : 'Unknown', style: const TextStyle(color: Color(0xFFC9C3DE), fontSize: 14)),
                        ],
                      ),
                      if (user.interests.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: user.interests.take(3).map((i) => _vibeChip(i)).toList(),
                        ),
                      ],
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

  Widget _actionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Nope
          WevoIconButton(
            icon: Icons.close,
            accent: const Color(0xFFFF7D7D),
            size: 62,
            onPressed: () => _swipe(false),
          ),
          const SizedBox(width: 20),
          // Super like
          WevoIconButton(
            icon: Icons.star,
            accent: const Color(0xFF8EC5FF),
            size: 52,
            onPressed: () => _swipe(true),
          ),
          const SizedBox(width: 20),
          // Like (gradient, big)
          WevoIconButton(
            icon: Icons.favorite,
            gradient: true,
            size: 72,
            onPressed: () => _swipe(true),
          ),
        ],
      ),
    );
  }

  // ── Detail panel (desktop right column) ──
  Widget _detailPanel() {
    final u = _current!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 34, 40, 60),
      child: SizedBox(
        width: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${u.name}, ${u.age}', style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 34, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: const Color(0xFFB98AE6), size: 16),
                        const SizedBox(width: 4),
                        Text('${u.country.isNotEmpty ? u.country : 'Unknown'} · ${_distance()}',
                          style: const TextStyle(color: WevoColors.textMuted, fontSize: 15)),
                      ],
                    ),
                  ],
                ),
                // Match %
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: WevoColors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: WevoColors.pink.withOpacity(0.35)),
                    boxShadow: [BoxShadow(color: WevoColors.pink.withOpacity(0.18), blurRadius: 26)],
                  ),
                  child: Column(
                    children: [
                      Text('${_matchPct.toInt()}%', style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 30, fontWeight: FontWeight.w600, color: Color(0xFFFF8FC0))),
                      const SizedBox(height: 2),
                      Text('VIBE MATCH', style: TextStyle(fontSize: 11, color: const Color(0xFFC9C3DE), letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),

            // Bio
            const SizedBox(height: 24),
            Text(u.bio, style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFFE4E0EF))),

            // Vibe in comune
            if (u.interests.isNotEmpty) ...[
              const SizedBox(height: 30),
              _sectionLabel('Vibe in comune'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: u.interests.where((i) => _allInterests.contains(i)).map((i) =>
                  _vibeChip(i, glow: true)
                ).toList(),
              ),
            ],

            // Tutte le vibe
            const SizedBox(height: 28),
            _sectionLabel('Tutte le vibe', muted: true),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: u.interests.map((i) => _vibeChip(i, muted: true)).toList(),
            ),

            // Giochi preferiti
            if (u.favoriteGames.isNotEmpty) ...[
              const SizedBox(height: 28),
              _sectionLabel('Giochi preferiti', muted: true),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: u.favoriteGames.map((g) => _gameChip(g)).toList(),
              ),
            ],

            // Galleria
            const SizedBox(height: 30),
            _sectionLabel('Galleria', muted: true),
            const SizedBox(height: 14),
            Row(
              children: [
                for (int i = 0; i < 4; i++)
                  Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
                    child: Container(
                      width: 120, height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(colors: _galleryColors(i), begin: Alignment.topLeft, end: Alignment.bottomRight),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image_outlined, color: Colors.white.withOpacity(0.18), size: 46),
                            const SizedBox(height: 4),
                            Text('// foto ${i + 1}', style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.white.withOpacity(0.5))),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, {bool muted = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.6,
        color: muted ? WevoColors.textMuted : WevoColors.pink,
      ),
    );
  }

  Widget _vibeChip(String label, {bool glow = false, bool muted = false}) {
    final color = _vibeColor(label);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: glow ? 17 : 15, vertical: glow ? 11 : 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: glow ? color.withOpacity(0.1) : (muted ? Colors.white.withOpacity(0.04) : color.withOpacity(0.1)),
        border: Border.all(color: glow ? color.withOpacity(0.6) : (muted ? Colors.white.withOpacity(0.1) : color.withOpacity(0.5))),
        boxShadow: glow ? [BoxShadow(color: color.withOpacity(0.18), blurRadius: 18)] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_vibeIcon(label), size: glow ? 17 : 15, color: color),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: glow ? 14 : 13, color: glow ? color : (muted ? const Color(0xFFC9C3DE) : color))),
        ],
      ),
    );
  }

  // Nuovo: MatchChip dal demo
  Widget _MatchChip({required String label}) {
    final c = _vibeColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.withOpacity(.35)),
        boxShadow: [BoxShadow(color: c.withOpacity(.15), blurRadius: 16)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_vibeIcon(label), size: 18, color: c),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _gameChip(String game) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: WevoColors.pink.withOpacity(0.07),
        border: Border.all(color: WevoColors.pink.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_esports_outlined, size: 15, color: const Color(0xFFFFB6D4)),
          const SizedBox(width: 6),
          Text(game, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFFFB6D4))),
        ],
      ),
    );
  }

  String _distance() {
    final dist = ['2 km', '5 km', '8 km', '3 km', '12 km'];
    return dist[_index % dist.length];
  }

  List<Color> _galleryColors(int i) {
    return [
      [const Color(0xFF3A2150), const Color(0xFF241433)],
      [const Color(0xFF1F2F50), const Color(0xFF13203A)],
      [const Color(0xFF50213A), const Color(0xFF331425)],
      [const Color(0xFF214A3A), const Color(0xFF142E25)],
    ][i % 4];
  }

  // ── Match Overlay (animazione dal demo, layout Wevo) ──
  Widget _matchOverlay() {
    final u = _matchedUser!;
    final pulse = 1 + (_pulseCtrl.value * 0.085);
    final rightSlide = -_avatarSlide.value;

    return SizedBox.expand(
      child: Stack(
        children: [
          // Backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                color: const Color(0xFF080410).withOpacity(0.92),
                child: Stack(
                  children: [
                    const Positioned.fill(child: _MatchBackgroundGlow()),
                    BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(color: Colors.transparent),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _NeonSparklePainter(_sparkleCtrl.value),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Contenuto
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Titolo
                Transform.translate(
                  offset: Offset(0, _titleY.value),
                  child: Opacity(
                    opacity: _titleOpa.value,
                    child: ShaderMask(
                      shaderCallback: (r) => const LinearGradient(colors: [
                        Color(0xFFFF8FC0), Color(0xFFFF5FA2), Color(0xFFB98AE6),
                      ]).createShader(r),
                      child: const Text(
                        "it's a match!",
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 68, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Sottotitolo
                Transform.translate(
                  offset: Offset(0, _subY.value),
                  child: Opacity(
                    opacity: _subOpa.value,
                    child: RichText(
                      text: TextSpan(
                        text: 'Tu e ',
                        style: const TextStyle(color: Color(0xFFE4E0EF), fontSize: 17),
                        children: [
                          TextSpan(
                            text: u.name,
                            style: const TextStyle(color: Color(0xFFFF8FC0), fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' avete le stesse vibe'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Avatar + cuore
                SizedBox(
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple
                      Transform.scale(
                        scale: _rippleScale.value,
                        child: Opacity(
                          opacity: _rippleOpa.value,
                          child: Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(.7), width: 2),
                              boxShadow: [BoxShadow(color: const Color(0xFFFF4D96).withOpacity(.28), blurRadius: 30, spreadRadius: 10)],
                            ),
                          ),
                        ),
                      ),
                      // Left avatar (iniziale S)
                      Transform.translate(
                        offset: Offset(_avatarSlide.value, 0),
                        child: _matchAvatar('S', scale: _avatarSlide),
                      ),
                      // Right avatar
                      Transform.translate(
                        offset: Offset(rightSlide, 0),
                        child: _matchAvatar(u.name[0].toUpperCase(), scale: _avatarSlide),
                      ),
                      // Cuore
                      Transform.scale(
                        scale: _heartScale.value * pulse,
                        child: Opacity(
                          opacity: 1,
                          child: Container(
                            width: 88, height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF4D96), Color(0xFFFF76C8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [BoxShadow(color: const Color(0xFFFF4D96).withOpacity(.6), blurRadius: 36, spreadRadius: 8)],
                            ),
                            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 56),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Vibe chips
                Opacity(
                  opacity: _chipsOpa.value,
                  child: Wrap(
                    spacing: 10, runSpacing: 10,
                    children: u.interests.take(4).map((l) => _vibeChip(l, glow: true)).toList(),
                  ),
                ),
                const SizedBox(height: 28),
                // Bottoni
                Transform.translate(
                  offset: Offset(0, _ctaY.value),
                  child: Opacity(
                    opacity: _ctaOpa.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WevoGradientButton(
                          label: 'Inizia a chattare',
                          icon: Icons.chat_bubble_rounded,
                          size: WevoSize.l,
                          onPressed: () { _closeMatchAndContinue(); MainShellState.switchTab(1); },
                        ),
                        const SizedBox(height: 12),
                        WevoNeonButton(
                          label: 'Proponi un\'attività',
                          icon: Icons.bolt,
                          size: WevoSize.m,
                          onPressed: _closeMatchKeepCurrent,
                        ),
                        const SizedBox(height: 10),
                        WevoButton(
                          label: 'Continua a swippare',
                          variant: WevoVariant.ghost,
                          color: WevoColors.pink,
                          onPressed: _closeMatchAndContinue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchAvatar(String initial, {required Animation<double> scale}) {
    final s = 0.6 + 0.4 * (scale.value / 110).clamp(0, 1);
    return Transform.scale(
      scale: s,
      child: Container(
        width: 140, height: 140,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [Color(0xFFFF5FA2), Color(0xFFFF3E8D)]),
          boxShadow: [BoxShadow(color: const Color(0xFFFF5FA2).withOpacity(0.6), blurRadius: 44)],
        ),
        child: Container(
          width: double.infinity, height: double.infinity,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF150C24),
          ),
          child: Center(
            child: Text(initial, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 58, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _matchCtrl.removeListener(_onMatchAnim);
    _matchCtrl.dispose();
    _pulseCtrl.dispose();
    _sparkleCtrl.dispose();
    _swipeCtrl.dispose();
    super.dispose();
  }
}

// ── Background glow per overlay match ──
class _MatchBackgroundGlow extends StatelessWidget {
  const _MatchBackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120, left: -80,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF4FD8).withOpacity(.10),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFF4FD8).withOpacity(.22), blurRadius: 120, spreadRadius: 40),
                ],
              ),
            ),
          ),
          Positioned(
            right: -80, top: 140,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF63E6FF).withOpacity(.08),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF63E6FF).withOpacity(.20), blurRadius: 110, spreadRadius: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sparkle Painter (stile neon dal demo) ──
class _NeonSparklePainter extends CustomPainter {
  final double progress;
  _NeonSparklePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final stars = [
      const Offset(0.18, 0.14), const Offset(0.72, 0.17),
      const Offset(0.84, 0.28), const Offset(0.12, 0.62),
      const Offset(0.28, 0.86), const Offset(0.78, 0.84),
      const Offset(0.58, 0.12), const Offset(0.42, 0.72),
    ];

    for (var i = 0; i < stars.length; i++) {
      final p = stars[i];
      final x = p.dx * size.width;
      final y = p.dy * size.height;
      final phase = (progress * 2 * math.pi) + i;
      final opacity = 0.35 + (math.sin(phase) + 1) * 0.25;
      final radius = 1.4 + ((math.cos(phase) + 1) * 1.0);
      final color = i.isEven
          ? const Color(0xFFFF7AD9).withOpacity(opacity)
          : const Color(0xFF7EDFFF).withOpacity(opacity);

      final paint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(Offset(x, y), radius, paint);
      canvas.drawLine(
        Offset(x - radius * 3, y), Offset(x + radius * 3, y),
        Paint()..color = color.withOpacity(opacity * .8)..strokeWidth = 1,
      );
      canvas.drawLine(
        Offset(x, y - radius * 3), Offset(x, y + radius * 3),
        Paint()..color = color.withOpacity(opacity * .8)..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NeonSparklePainter old) => old.progress != progress;
}

// ── Avatar Bubble (match overlay) ──
class _MatchAvatarBubble extends StatelessWidget {
  final String imageUrl;
  final Color glowColor;
  const _MatchAvatarBubble({required this.imageUrl, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156, height: 156,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: glowColor.withOpacity(.65), blurRadius: 34, spreadRadius: 4),
        ],
        border: Border.all(color: glowColor, width: 3),
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [glowColor, Colors.white.withOpacity(.28)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipOval(
          child: Image.network(imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

// ── Icon button circolare ──
class _IconCircleBtn extends StatelessWidget {
  final IconData icon;
  const _IconCircleBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(.05),
        border: Border.all(color: Colors.white.withOpacity(.08)),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF4FD8).withOpacity(.16), blurRadius: 18),
        ],
      ),
      child: IconButton(
        onPressed: () => MainShellState.switchTab(0),
        icon: Icon(icon, color: Colors.white.withOpacity(.9), size: 18),
      ),
    );
  }
}

// ── Neon Button (primary e secondary) ──
class _NeonButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  const _NeonButton({required this.label, required this.icon, required this.onTap, required this.primary});

  @override
  Widget build(BuildContext context) {
    final gradient = primary
        ? const [Color(0xFFFF4FD8), Color(0xFFFF79C6)]
        : const [Color(0x332D1B45), Color(0x222A163F)];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(colors: gradient),
        border: Border.all(
          color: primary ? Colors.transparent : const Color(0x66FF4FD8),
        ),
        boxShadow: primary
            ? [BoxShadow(color: const Color(0x66FF4FD8), blurRadius: 26, offset: const Offset(0, 10))]
            : [BoxShadow(color: const Color(0x225CE1FF), blurRadius: 16)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Icon(icon, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Interessi globali per match pct ──
const _allInterests = {
  'Music', 'Coffee', 'Travel', 'Books', 'Gaming', 'Movies',
  'FPS', 'MOBA', 'Co-op', 'Anime', 'Tech', 'Design', 'Community', 'Chill', 'Chat',
};

