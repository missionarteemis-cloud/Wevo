import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../theme.dart';
import 'chat_detail_screen.dart';
import 'user_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  double _dragX = 0;
  List<UserModel> _users = [];
  bool _loadingUsers = true;
  late AnimationController _matchController;

  @override
  void initState() {
    super.initState();
    _matchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final realUsers = await UserService.fetchDiscoverUsers();
    // Utenti reali davanti, mock in fondo come fallback/demo
    final combined = [...realUsers, ...mockUsers];
    if (mounted) setState(() { _users = combined; _loadingUsers = false; });
  }

  @override
  void dispose() {
    _matchController.dispose();
    super.dispose();
  }

  void _onSwipe(bool liked) {
    if (_currentIndex >= _users.length) return;
    if (liked) _showMatchDialog(_users[_currentIndex]);
    setState(() {
      _dragX = 0;
      _currentIndex++;
    });
  }

  void _showMatchDialog(UserModel user) {
    showDialog(
      context: context,
      barrierColor: WevoColors.dark.withOpacity(0.85),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "È un Match! 🎉",
              style: TextStyle(
                color: WevoColors.pink,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tu e ${user.name} vi piaccete!",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(user.imageUrl),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text("Dopo"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(user: user),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WevoColors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text("Scrivi ora!"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/wevo scritta.PNG', height: 32),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: WevoColors.lightBlue),
            onPressed: () {},
            tooltip: 'Filtri',
          ),
        ],
      ),
      body: _loadingUsers
          ? const Center(child: CircularProgressIndicator(color: WevoColors.pink))
          : _currentIndex >= _users.length
              ? _buildEmptyState()
              : _buildCardStack(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 80, color: WevoColors.pink.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Hai visto tutti!\nRitorna più tardi.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Card successiva (in fondo, più piccola)
              if (_currentIndex + 1 < _users.length)
                Positioned(
                  top: 24,
                  child: _ProfileCard(
                    user: _users[_currentIndex + 1],
                    scale: 0.93,
                    opacity: 0.6,
                    dragX: 0,
                  ),
                ),
              // Card corrente (draggable + tappabile)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserDetailScreen(
                      user: _users[_currentIndex],
                      onDecision: _onSwipe,
                    ),
                  ),
                ),
                onHorizontalDragUpdate: (d) =>
                    setState(() => _dragX += d.delta.dx),
                onHorizontalDragEnd: (d) {
                  if (_dragX > 80) _onSwipe(true);
                  else if (_dragX < -80) _onSwipe(false);
                  else setState(() => _dragX = 0);
                },
                child: _ProfileCard(
                  user: _users[_currentIndex],
                  scale: 1.0,
                  opacity: 1.0,
                  dragX: _dragX,
                ),
              ),
            ],
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ActionButton(
            icon: Icons.close,
            color: WevoColors.coral,
            size: 52,
            onTap: () => _onSwipe(false),
          ),
          const SizedBox(width: 32),
          _ActionButton(
            icon: Icons.favorite,
            color: WevoColors.pink,
            size: 64,
            onTap: () => _onSwipe(true),
          ),
          const SizedBox(width: 32),
          _ActionButton(
            icon: Icons.star,
            color: WevoColors.lightBlue,
            size: 52,
            onTap: () => _onSwipe(true),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserModel user;
  final double scale;
  final double opacity;
  final double dragX;

  const _ProfileCard({
    required this.user,
    required this.scale,
    required this.opacity,
    required this.dragX,
  });

  @override
  Widget build(BuildContext context) {
    final angle = dragX / 800;
    return Transform(
      transform: Matrix4.identity()
        ..translate(dragX, 0)
        ..rotateZ(angle)
        ..scale(scale),
      alignment: Alignment.center,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          height: MediaQuery.of(context).size.height * 0.62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: WevoColors.dark.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(user.imageUrl, fit: BoxFit.cover),
                // Gradient overlay che si riempie dal lato dello swipe
                if (dragX != 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: dragX > 0 ? Alignment.centerLeft : Alignment.centerRight,
                          end: dragX > 0 ? Alignment.centerRight : Alignment.centerLeft,
                          colors: [
                            (dragX > 0 ? WevoColors.sage : WevoColors.coral)
                                .withOpacity((dragX.abs() / 180).clamp(0.0, 0.65)),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.7],
                        ),
                      ),
                    ),
                  ),
                // Icona fumetto ✓ / ✗
                if (dragX.abs() > 35)
                  Center(
                    child: Transform.rotate(
                      angle: dragX > 0 ? -0.25 : 0.25,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (dragX > 0 ? WevoColors.sage : WevoColors.coral)
                              .withOpacity(0.9),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                        ),
                        child: Icon(
                          dragX > 0 ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        color: WevoColors.dark.withOpacity(0.55),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${user.name}, ${user.age}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (user.discordTag != null)
                                  const Icon(Icons.games, color: WevoColors.lightBlue, size: 18),
                                if (user.hasNetflix)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.tv, color: WevoColors.coral, size: 18),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              user.bio,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: user.interests.take(3).map((interest) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: WevoColors.pink.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: WevoColors.pink.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    interest,
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.48),
      ),
    );
  }
}
