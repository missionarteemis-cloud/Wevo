import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme.dart';

const _vibeTags = {
  'Music': Icons.headphones,
  'Coffee': Icons.coffee_outlined,
  'Travel': Icons.flight_takeoff_outlined,
  'Books': Icons.menu_book_outlined,
  'Gaming': Icons.sports_esports_outlined,
};

const _vibeColors = {
  'Music': Color(0xFF5BC0FF),
  'Coffee': Color(0xFFFF8C42),
  'Travel': Color(0xFF44E5E7),
  'Books': Color(0xFFBE7CFF),
  'Gaming': Color(0xFFFF6B9D),
};

class UserDetailScreen extends StatelessWidget {
  final UserModel user;

  /// Callback chiamato quando l'utente preme ♥ (like) o ✕ (passa).
  final void Function(bool liked)? onDecision;

  const UserDetailScreen({
    super.key,
    required this.user,
    this.onDecision,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            return Center(
              child: SizedBox(
                width: isDesktop ? 420 : double.infinity,
                child: _buildContent(context),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Stack(
      children: [
        // ── Scroll content ──
        Positioned.fill(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80), // space for top buttons
                // ── Avatar ──
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const SweepGradient(
                          colors: [
                            Color(0xFF5BC0FF),
                            Color(0xFFBE7CFF),
                            Color(0xFFFF6B9D),
                            Color(0xFF5BC0FF),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFF6B9D).withOpacity(0.4), blurRadius: 28, spreadRadius: 2),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: CircleAvatar(
                        radius: 57,
                        backgroundColor: const Color(0xFF0E0A17),
                        backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                        child: user.photoUrl.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.white38) : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF6B9D),
                          border: Border.all(color: const Color(0xFF000000), width: 2),
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Name + age ──
                Text(
                  '${user.name}, ${user.age}',
                  style: const TextStyle(color: Color(0xFFFF6B9D), fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                // ── Location ──
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(user.country.isNotEmpty ? user.country : 'Unknown', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 14),
                // ── Bio ──
                if (user.bio.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      user.bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                    ),
                  ),
                const SizedBox(height: 24),

                // ── Vibes ──
                if (user.interests.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Vibes', style: TextStyle(color: const Color(0xFFFF6B9D).withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      spacing: 10, runSpacing: 10,
                      children: user.interests.map((interest) {
                        final icon = _vibeTags[interest] ?? Icons.auto_awesome;
                        final color = _vibeColors[interest] ?? const Color(0xFFFF6B9D);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withOpacity(0.5)),
                            color: color.withOpacity(0.06),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 14, color: color),
                              const SizedBox(width: 6),
                              Text(interest, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Gallery ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Gallery', style: TextStyle(color: const Color(0xFFFF6B9D).withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return Container(
                        width: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFF6B9D).withOpacity(0.20)),
                          image: user.coverUrl.isNotEmpty
                              ? DecorationImage(image: NetworkImage(user.coverUrl), fit: BoxFit.cover)
                              : null,
                          color: const Color(0xFF1A1525),
                        ),
                        child: user.coverUrl.isEmpty
                            ? const Center(child: Icon(Icons.image_outlined, color: Colors.white24, size: 28))
                            : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── Favorite Games ──
                if (user.favoriteGames.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Favorite Games', style: TextStyle(color: const Color(0xFFFF6B9D).withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: user.favoriteGames.map((g) => _neonChip(g, WevoColors.cyan)).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Social links ──
                if (user.discordTag != null || user.riotId != null || user.steamId != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Social & Gaming Links', style: TextStyle(color: const Color(0xFFFF6B9D).withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        if (user.discordTag != null) _linkRow('Discord', user.discordTag!),
                        if (user.riotId != null) _linkRow('Riot', user.riotId!),
                        if (user.steamId != null) _linkRow('Steam', user.steamId!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Platforms ──
                if (user.platforms.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Platforms', style: TextStyle(color: const Color(0xFFFF6B9D).withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: user.platforms.map((p) => _neonChip(p, WevoColors.pink)).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Buttons ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    children: [
                      if (onDecision != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _decisionBtn(context, Icons.close, const Color(0xFFFF5E7D), 56, () {
                              onDecision!(false);
                              Navigator.pop(context);
                            }),
                            const SizedBox(width: 40),
                            _decisionBtn(context, Icons.favorite, const Color(0xFFFF6B9D), 68, () {
                              onDecision!(true);
                              Navigator.pop(context);
                            }),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),

        // ── Top bar ──
        Positioned(
          top: 0, left: 0, right: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _linkRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(width: 72, child: Text(label, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600))),
            Expanded(child: Text(value, style: const TextStyle(color: Colors.white70))),
          ],
        ),
      );

  Widget _decisionBtn(BuildContext context, IconData icon, Color color, double size, VoidCallback onTap) {
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
}

Widget _neonChip(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withOpacity(0.30)),
    ),
    child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
  );
}
