import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/match_service.dart';
import '../theme.dart';
import '../main.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  bool _loading = true;
  List<UserModel> _matches = [];
  UserModel? _selected;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, String>> _messages = [];
  String _groupFilter = 'Tutte'; // Tutte | Online | Nuove

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final real = await MatchService.fetchMatchUsers().timeout(const Duration(seconds: 5));
      if (mounted) setState(() {
        _matches = real.isNotEmpty ? real : [...mockMatches];
        _loading = false;
        if (_selected == null && _matches.isNotEmpty) _selectChat(_matches[0]);
      });
    } catch (_) {
      if (mounted) setState(() {
        _matches = [...mockMatches];
        _loading = false;
        if (_selected == null && _matches.isNotEmpty) _selectChat(_matches[0]);
      });
    }
  }

  void _selectChat(UserModel user) {
    setState(() {
      _selected = user;
      _messages = mockMessages[user.id] ?? [];
    });
  }

  void _sendMsg() {
    final t = _msgCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _messages.add({'sender': 'me', 'text': t, 'time': DateTime.now().toString().substring(11, 16)});
      _msgCtrl.clear();
    });
    Future.delayed(const Duration(milliseconds: 600), () => _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: WevoColors.pink));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        if (isDesktop) return _desktopLayout();
        return _mobileLayout();
      },
    );
  }

  // ── MOBILE: lista chat full con navigazione a thread ──
  Widget _mobileLayout() {
    if (_selected != null) {
      return _chatThread(mobile: true);
    }
    return _matchList();
  }

  // ── DESKTOP: lista a sinistra + thread a destra ──
  Widget _desktopLayout() {
    return Row(
      children: [
        SizedBox(width: 380, child: _matchList()),
        Container(width: 1, color: Colors.white.withOpacity(0.06)),
        Expanded(child: _selected != null ? _chatThread(mobile: false) : _emptyChat()),
      ],
    );
  }

  // ── Lista match (sinistra) ──
  Widget _matchList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 12),
              const Text('Matches', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 16),
              // Filtri
              Row(
                children: ['Tutte', 'Online', 'Nuove'].map((f) {
                  final active = _groupFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _groupFilter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: active ? WevoColors.pink.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                          border: Border.all(color: active ? WevoColors.pink.withOpacity(0.5) : Colors.white.withOpacity(0.08)),
                        ),
                        child: Text(f, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: active ? WevoColors.pink : WevoColors.textMuted)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        // Lista
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _matches.length,
            itemBuilder: (_, i) => _matchTile(_matches[i]),
          ),
        ),
      ],
    );
  }

  Widget _matchTile(UserModel user) {
    final isActive = _selected?.id == user.id;
    final msg = mockMessages[user.id];
    final lastMsg = msg != null && msg.isNotEmpty ? msg.last['text'] : null;
    final lastTime = msg != null && msg.isNotEmpty ? msg.last['time'] : null;
    final variant = _variantFor(user);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isActive ? WevoColors.pink.withOpacity(0.1) : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _selectChat(user),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 52, height: 52,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [WevoColors.pink, Color(0xFFB98AE6)]),
                      ),
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFF1A1128),
                        backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                        child: user.photoUrl.isEmpty ? Text(user.name[0].toUpperCase(), style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600, color: Color(0xFFFFB6D4), fontSize: 18)) : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF9EDFA6),
                          border: Border.all(color: const Color(0xFF0E0718), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: WevoColors.sage.withOpacity(0.12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(variant.icon, size: 11, color: variant.color),
                                const SizedBox(width: 4),
                                Text(variant.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: variant.color)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (lastTime != null) Text(lastTime, style: const TextStyle(color: WevoColors.textMuted, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMsg ?? 'Ditevi qualcosa!',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: WevoColors.textMuted, fontSize: 14),
                            ),
                          ),
                          if (i(int.tryParse(user.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) % 3 == 0)
                            Container(
                              width: 8, height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: WevoColors.pink),
                            ),
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

  // ── Thread chat (destra) ──
  Widget _chatThread({required bool mobile}) {
    final u = _selected!;
    return Column(
      children: [
        // Header chat
        Container(
          padding: EdgeInsets.fromLTRB(mobile ? 16 : 22, 22, mobile ? 16 : 22, 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
          ),
          child: Row(
            children: [
              if (mobile) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFFB6D4), size: 22),
                  onPressed: () => setState(() => _selected = null),
                ),
                const SizedBox(width: 4),
              ],
              // Avatar
              Container(
                width: 44, height: 44,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [WevoColors.pink, Color(0xFFB98AE6)]),
                ),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF1A1128),
                  backgroundImage: u.photoUrl.isNotEmpty ? NetworkImage(u.photoUrl) : null,
                  child: u.photoUrl.isEmpty ? Text(u.name[0].toUpperCase(), style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600, color: Color(0xFFFFB6D4), fontSize: 16)) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Color(0xFF62E6FF), size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF9EDFA6), boxShadow: [BoxShadow(color: Color(0xFF9EDFA6), blurRadius: 6)])),
                        const SizedBox(width: 4),
                        const Text('Online', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9EDFA6))),
                      ],
                    ),
                  ],
                ),
              ),
              // Azioni
              Icon(Icons.phone_outlined, color: WevoColors.textMuted, size: 20),
              const SizedBox(width: 14),
              Icon(Icons.more_horiz, color: WevoColors.textMuted, size: 22),
            ],
          ),
        ),
        // Messaggi
        Expanded(
          child: _messages.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: WevoColors.pink.withOpacity(0.08)),
                      child: const Icon(Icons.chat, color: WevoColors.pink, size: 28),
                    ),
                    const SizedBox(height: 14),
                    Text("Ditevi qualcosa per iniziare!", style: TextStyle(color: WevoColors.textMuted, fontSize: 14)),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _msgBubble(_messages[i]),
              ),
        ),
        // Composer
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.only(left: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF201233),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, color: WevoColors.textMuted, size: 22),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: mobile ? 200 : 360,
                      child: TextField(
                        controller: _msgCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Scrivi un messaggio...',
                          hintStyle: TextStyle(color: Color(0xFF6B6178)),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        onSubmitted: (_) => _sendMsg(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sendMsg,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: WevoColors.primaryGradient,
                    boxShadow: [BoxShadow(color: WevoColors.hotPink.withOpacity(0.5), blurRadius: 20)],
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _msgBubble(Map<String, String> msg) {
    final isMe = msg['sender'] == 'me';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        constraints: BoxConstraints(maxWidth: isMe ? 340 : 360),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isMe ? 22 : 5),
            bottomRight: Radius.circular(isMe ? 5 : 22),
          ),
          gradient: isMe
            ? WevoColors.primaryGradient
            : LinearGradient(colors: [const Color(0xFF201233), const Color(0xFF2A1C40)]),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg['text'] ?? '', style: TextStyle(color: isMe ? Colors.white : const Color(0xFFE4E0EF), fontSize: 15, height: 1.4)),
            const SizedBox(height: 4),
            Text(msg['time'] ?? '', style: TextStyle(color: isMe ? Colors.white.withOpacity(0.6) : const Color(0xFF6B6178), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _emptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, color: WevoColors.pink.withOpacity(0.1)),
            child: const Icon(Icons.chat_bubble_outline, color: WevoColors.pink, size: 36),
          ),
          const SizedBox(height: 18),
          const Text('Seleziona un match', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 6),
          Text('per iniziare a chattare', style: TextStyle(color: WevoColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}

// Helper
int i(int? v) => v ?? 0;

// Variant per match tile
class _MatchVariant {
  final IconData icon;
  final Color color;
  final String label;
  const _MatchVariant({required this.icon, required this.color, required this.label});
}

_MatchVariant _variantFor(UserModel user) {
  final haystack = [...user.interests, ...user.favoriteGames, ...user.platforms, ...user.lookingFor].join(' ').toLowerCase();
  if (haystack.contains('music')) return const _MatchVariant(icon: Icons.headphones, color: Color(0xFF8EC5FF), label: 'Music');
  if (haystack.contains('movie') || haystack.contains('cinema')) return const _MatchVariant(icon: Icons.movie_creation_outlined, color: Color(0xFFFF7D7D), label: 'Movie');
  if (haystack.contains('pc') || haystack.contains('playstation') || haystack.contains('xbox')) return const _MatchVariant(icon: Icons.computer, color: Color(0xFF62E6FF), label: 'PC');
  if (haystack.contains('design')) return const _MatchVariant(icon: Icons.palette_outlined, color: Color(0xFFB98AE6), label: 'Design');
  if (haystack.contains('gaming') || haystack.contains('fps') || haystack.contains('moba')) return const _MatchVariant(icon: Icons.sports_esports_outlined, color: Color(0xFFFF5FA2), label: 'Gaming');
  return const _MatchVariant(icon: Icons.wb_sunny_outlined, color: Color(0xFFFFC76A), label: 'Chill');
}

// Mock data
final List<UserModel> mockMatches = [
  UserModel(id: 'm1', name: 'Giulia', username: 'giuplays', age: 24, bio: 'FPS, co-op e sessioni chill.', photoUrl: 'https://picsum.photos/seed/giulia24p/200/200', coverUrl: 'https://picsum.photos/seed/giulia24c/600/900', interests: ['FPS', 'Co-op'], favoriteGames: ['Valorant'], platforms: ['PC'], lookingFor: ['Duo'], discordTag: 'giuplays', country: 'Roma, IT'),
  UserModel(id: 'm2', name: 'Marco', username: 'marcojungler', age: 27, bio: 'Main jungle, ranked senza drama.', photoUrl: 'https://picsum.photos/seed/marco27p/200/200', coverUrl: 'https://picsum.photos/seed/marco27c/600/900', interests: ['MOBA'], favoriteGames: ['LoL'], platforms: ['PC'], lookingFor: ['Ranked'], discordTag: 'marcojungler', country: 'Torino, IT'),
  UserModel(id: 'm4', name: 'Alex', username: 'alexvibes', age: 25, bio: 'Cerco duo, match e vibe pulita.', photoUrl: 'https://picsum.photos/seed/alex25p/200/200', coverUrl: 'https://picsum.photos/seed/alex25c/600/900', interests: ['Music', 'Gaming'], favoriteGames: ['Fortnite'], platforms: ['PC', 'PlayStation'], lookingFor: ['Friendship'], discordTag: 'alexvibes', country: 'Milano, IT'),
  UserModel(id: 'm5', name: 'Noemi', username: 'n0eheart', age: 23, bio: 'Late night chat e co-op.', photoUrl: 'https://picsum.photos/seed/noemi23p/200/200', coverUrl: 'https://picsum.photos/seed/noemi23c/600/900', interests: ['Chat', 'Music'], favoriteGames: ['Overcooked'], platforms: ['PC', 'Mobile'], lookingFor: ['Chill'], discordTag: 'n0eheart', country: 'Firenze, IT'),
];

final Map<String, List<Map<String, String>>> mockMessages = {
  'm1': [
    {'sender': 'them', 'text': 'Ti va una duo stasera?', 'time': '10:30'},
    {'sender': 'me', 'text': 'Sì, dopo le 21 ci sono', 'time': '10:32'},
    {'sender': 'them', 'text': 'Perfetto! Ti mando invito', 'time': '10:33'},
  ],
  'm2': [
    {'sender': 'them', 'text': 'Ranked o chill?', 'time': 'Ieri'},
    {'sender': 'me', 'text': 'Una ranked e poi chill', 'time': 'Ieri'},
    {'sender': 'them', 'text': 'Let\'s go 🔥', 'time': 'Ieri'},
  ],
  'm4': [
    {'sender': 'them', 'text': 'Stessa vibe, stesso caos', 'time': '18:20'},
    {'sender': 'me', 'text': 'Ahah esatto, ci beccamo?', 'time': '18:22'},
    {'sender': 'them', 'text': 'Certamente! 🚀', 'time': '18:23'},
  ],
  'm5': [
    {'sender': 'them', 'text': 'Facciamo un game e poi chat?', 'time': '17:02'},
    {'sender': 'me', 'text': 'Let\'s go, quale giochiamo?', 'time': '17:04'},
  ],
};
