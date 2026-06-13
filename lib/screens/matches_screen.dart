import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/match_service.dart';
import '../theme.dart';
import 'chat_detail_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  bool _loading = true;
  List<UserModel> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final realMatches = await MatchService.fetchMatchUsers();
      if (mounted) {
        setState(() {
          _matches = realMatches.isNotEmpty ? realMatches : mockMatches;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _matches = mockMatches;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [WevoColors.bg, WevoColors.dark],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: WevoColors.pink))
              : RefreshIndicator(
                  color: WevoColors.pink,
                  onRefresh: _loadMatches,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                    children: [
                      const _MatchesHeader(),
                      const SizedBox(height: 20),
                      if (_matches.isNotEmpty) _FeaturedMatchCard(user: _matches.first),
                      const SizedBox(height: 18),
                      const _SectionTitle('match variants'),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _matches.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.95,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          final user = _matches[index];
                          return _VariantMatchCard(user: user);
                        },
                      ),
                      const SizedBox(height: 20),
                      const _SectionTitle('conversations'),
                      const SizedBox(height: 12),
                      ..._matches.map((user) => _ConversationTile(user: user)).toList(),
                      const SizedBox(height: 18),
                      const _LegendCard(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _MatchesHeader extends StatelessWidget {
  const _MatchesHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your matches',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Le connessioni con più vibe e potenziale.',
                style: TextStyle(color: WevoColors.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: WevoColors.panel,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [BoxShadow(color: Color(0x33FF5FA2), blurRadius: 18)],
          ),
          child: const Icon(Icons.auto_awesome, color: WevoColors.pink),
        ),
      ],
    );
  }
}

class _FeaturedMatchCard extends StatelessWidget {
  final UserModel user;
  const _FeaturedMatchCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final variant = _variantFor(user);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: WevoColors.darkSoft,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [wevoGlow(variant.color, blur: 28)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "it's a match!",
              style: TextStyle(
                color: Color(0xFFFFA1C8),
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Tu e ${user.name} condividete la stessa energy 💗',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(left: 6, child: _NeonCircleAvatar(url: user.photoUrl, color: WevoColors.pink)),
                Positioned(right: 6, child: _NeonCircleAvatar(url: user.coverUrl, color: WevoColors.lightBlue)),
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WevoColors.panel,
                    border: Border.all(color: variant.color, width: 3),
                    boxShadow: [wevoGlow(variant.color, blur: 26)],
                  ),
                  child: Icon(variant.icon, color: variant.color, size: 38),
                ),
              ],
            ),
          ),
          const Text('You have in common:', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...user.interests.take(1),
              ...user.favoriteGames.take(1),
              ...user.platforms.take(1),
            ].map((e) => _TagChip(label: e)).toList(),
          ),
          const SizedBox(height: 20),
          _GradientButton(
            label: 'Start Chat',
            icon: Icons.chat_bubble_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatDetailScreen(user: user)),
            ),
          ),
          const SizedBox(height: 12),
          _GhostButton(label: 'Start an Activity', icon: Icons.flash_on, onTap: () {}),
          const SizedBox(height: 12),
          const Center(
            child: Text('Maybe later', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

class _VariantMatchCard extends StatelessWidget {
  final UserModel user;
  const _VariantMatchCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final variant = _variantFor(user);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatDetailScreen(user: user)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: WevoColors.darkSoft,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [wevoGlow(variant.color, blur: 18)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(left: 0, child: _SmallGlowAvatar(url: user.photoUrl, color: WevoColors.pink)),
                  Positioned(right: 0, child: _SmallGlowAvatar(url: user.coverUrl, color: WevoColors.lightBlue)),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: WevoColors.panel,
                      border: Border.all(color: variant.color, width: 2.5),
                      boxShadow: [wevoGlow(variant.color, blur: 20)],
                    ),
                    child: Icon(variant.icon, color: variant.color, size: 26),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "it's a match!",
              style: TextStyle(color: Color(0xFFFFA1C8), fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(variant.label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final UserModel user;
  const _ConversationTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ChatService.fetchChatPreview(otherUserId: user.id),
      builder: (context, snapshot) {
        final preview = snapshot.data;
        final lastMessage = (preview?['lastMessage'] as String?) ?? (mockMessages[user.id]?.last['text'] ?? 'Hai un match. Scrivigli.');
        final rawTime = preview?['lastMessageAt'];
        final time = rawTime is Timestamp ? _formatTime(rawTime.toDate()) : (mockMessages[user.id]?.last['time'] ?? '');

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatDetailScreen(user: user)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WevoColors.darkSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                _SmallGlowAvatar(url: user.imageUrl, color: WevoColors.pink, size: 54),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage,
                        style: const TextStyle(color: WevoColors.textMuted, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(time, style: const TextStyle(color: WevoColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LegendCard extends StatelessWidget {
  const _LegendCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WevoColors.darkSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Why different match icons?', style: TextStyle(color: Color(0xFFFFA1C8), fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text(
            'Ogni match rappresenta una vibe o connessione diversa. L’icona racconta cosa vi ha avvicinati.',
            style: TextStyle(color: WevoColors.textMuted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFFFA1C8),
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _NeonCircleAvatar extends StatelessWidget {
  final String url;
  final Color color;
  const _NeonCircleAvatar({required this.url, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 122,
      height: 122,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: [wevoGlow(color, blur: 26)],
      ),
      child: CircleAvatar(radius: 58, backgroundImage: NetworkImage(url)),
    );
  }
}

class _SmallGlowAvatar extends StatelessWidget {
  final String url;
  final Color color;
  final double size;
  const _SmallGlowAvatar({required this.url, required this.color, this.size = 62});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [wevoGlow(color, blur: 18)],
      ),
      child: CircleAvatar(radius: (size / 2) - 4, backgroundImage: NetworkImage(url)),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: WevoColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [wevoGlow(WevoColors.pink, blur: 22)],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          icon: Icon(icon, color: Colors.white.withOpacity(0.95), size: 18),
          label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GhostButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.14)),
          backgroundColor: Colors.white.withOpacity(0.04),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        icon: Icon(icon, color: WevoColors.gold),
        label: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _MatchVariant {
  final IconData icon;
  final Color color;
  final String label;
  const _MatchVariant({required this.icon, required this.color, required this.label});
}

_MatchVariant _variantFor(UserModel user) {
  final haystack = [
    ...user.interests,
    ...user.favoriteGames,
    ...user.platforms,
    ...user.lookingFor,
  ].join(' ').toLowerCase();

  if (haystack.contains('music')) {
    return const _MatchVariant(icon: Icons.headphones, color: WevoColors.lightBlue, label: 'Music');
  }
  if (haystack.contains('movie') || haystack.contains('cinema')) {
    return const _MatchVariant(icon: Icons.movie_creation_outlined, color: WevoColors.coral, label: 'Movie');
  }
  if (haystack.contains('pc') || haystack.contains('playstation') || haystack.contains('xbox')) {
    return const _MatchVariant(icon: Icons.computer, color: WevoColors.cyan, label: 'PC');
  }
  if (haystack.contains('community') || haystack.contains('friend')) {
    return const _MatchVariant(icon: Icons.favorite, color: WevoColors.pink, label: 'Heart');
  }
  if (haystack.contains('chat')) {
    return const _MatchVariant(icon: Icons.chat_bubble_outline, color: WevoColors.gold, label: 'Chat');
  }
  return const _MatchVariant(icon: Icons.sports_esports, color: WevoColors.sage, label: 'Gaming');
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
