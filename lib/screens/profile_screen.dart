import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../services/seed_service.dart';
import '../theme.dart';
import 'room_screen.dart';

const _allInterests = [
  'Gaming', 'FPS', 'MOBA', 'Co-op', 'Anime', 'Tech', 'Design', 'Music', 'Community', 'Chill',
];
const _allPlatforms = ['PC', 'PlayStation', 'Xbox', 'Switch', 'Mobile'];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  bool _seeding = false;

  final _bioCtrl = TextEditingController();
  final _discordCtrl = TextEditingController();
  List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await UserService.fetchCurrentUser();
      if (mounted) setState(() {
        _user = user;
        _bioCtrl.text = user?.bio ?? '';
        _selectedInterests = user?.interests ?? [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _user = null;
          _loading = false;
        });
      }
    }
  }

  // ── EDIT: cambia foto profilo o cover ──
  Future<void> _pickPhoto(bool isCover) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (img == null) return;
    setState(() => _saving = true);
    try {
      final bytes = await img.readAsBytes();
      final ext = img.path.split('.').last.toLowerCase();
      final url = await StorageService.uploadProfilePhoto(bytes, ext);
      if (isCover) {
        _user = _user != null
          ? UserModel(id: _user!.id, name: _user!.name, username: _user!.username, age: _user!.age, bio: _user!.bio,
              photoUrl: url ?? _user!.photoUrl, coverUrl: _user!.coverUrl, interests: _user!.interests,
              favoriteGames: _user!.favoriteGames, platforms: _user!.platforms,
              lookingFor: _user!.lookingFor, discordTag: _user!.discordTag)
          : null;
      } else {
        _user = _user != null
          ? UserModel(id: _user!.id, name: _user!.name, username: _user!.username, age: _user!.age, bio: _user!.bio,
              photoUrl: url ?? _user!.photoUrl, coverUrl: _user!.coverUrl, interests: _user!.interests,
              favoriteGames: _user!.favoriteGames, platforms: _user!.platforms,
              lookingFor: _user!.lookingFor, discordTag: _user!.discordTag)
          : null;
      }
      setState(() => _saving = false);
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      if (_user != null) {
        await UserService.updateProfile(
          bio: _bioCtrl.text,
          interests: _selectedInterests,
          favoriteGames: _user?.favoriteGames ?? [],
          platforms: _user?.platforms ?? [],
          lookingFor: _user?.lookingFor ?? [],
          age: _user?.age ?? 0,
          discordTag: _discordCtrl.text,
        );
      }
      if (mounted) setState(() => _editing = false);
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _seedDemoData() async {
    setState(() => _seeding = true);
    try {
      final log = await SeedService.seedDemoData();
      debugPrint(log);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Seeding complete! 5 mock users created with matches & messages.'),
            backgroundColor: Color(0xFF1A1128),
          ),
        );
        _loadUser();
      }
    } catch (e) {
      debugPrint('Seed error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Seeding failed: $e'),
            backgroundColor: Color(0xFFFF7D7D).withOpacity(0.2),
          ),
        );
      }
    }
    if (mounted) setState(() => _seeding = false);
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: WevoColors.pink));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 40, bottom: 60),
          child: Center(
            child: SizedBox(
              width: isDesktop ? 400 : double.infinity,
              child: _buildContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Header: wevo + Profile ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShaderMask(
              shaderCallback: (r) => const LinearGradient(colors: [
                WevoColors.pink, Color(0xFFB98AE6), Color(0xFF8EC5FF), Color(0xFF5FE0C5),
              ]).createShader(r),
              child: const Text('wevo', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 30, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
            Text('Profile', style: TextStyle(color: WevoColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          ],
        ),

        const SizedBox(height: 36),

        // ── Avatar con gradient glow ──
        Stack(
          alignment: Alignment.center,
          children: [
            // Anelli glow
            for (int i = 0; i < 3; i++)
              Container(
                width: 130 + i * 28,
                height: 130 + i * 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: [WevoColors.pink, const Color(0xFFB98AE6), const Color(0xFF62E6FF)][i].withOpacity(0.18 - i * 0.04),
                      blurRadius: (30 + i * 16).toDouble(),
                      spreadRadius: (-2 - i).toDouble(),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.04 - i * 0.01), width: 1),
                ),
              ),
            // Avatar vero
            Container(
              width: 130, height: 130,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [WevoColors.pink, Color(0xFFB98AE6)]),
                boxShadow: [BoxShadow(color: WevoColors.hotPink.withOpacity(0.45), blurRadius: 30)],
              ),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF1A1128),
                backgroundImage: _user?.photoUrl.isNotEmpty == true ? NetworkImage(_user!.photoUrl) : null,
                child: _user?.photoUrl.isEmpty ?? true
                  ? const Icon(Icons.person, color: Color(0xFFFFB6D4), size: 52)
                  : null,
              ),
            ),
            // Camera button
            if (_editing)
              Positioned(
                bottom: 6, right: 6,
                child: GestureDetector(
                  onTap: () => _pickPhoto(false),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: WevoColors.primaryGradient,
                      boxShadow: [BoxShadow(color: WevoColors.hotPink.withOpacity(0.5), blurRadius: 16)],
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Nome e username ──
        Text(_user?.name ?? 'Il tuo nome', style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 4),
        Text('@${_user?.username ?? 'username'}', style: const TextStyle(color: WevoColors.textMuted, fontSize: 15)),

        const SizedBox(height: 24),

        // ── Bio ──
        if (!_editing)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF201233),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Text(
              _user?.bio.isNotEmpty == true ? _user!.bio : 'Nessuna bio ancora.',
              style: const TextStyle(color: Color(0xFFE4E0EF), fontSize: 15, height: 1.5),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: const Color(0xFF201233),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: TextField(
              controller: _bioCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Scrivi una bio...',
                hintStyle: TextStyle(color: Color(0xFF6B6178)),
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),

        const SizedBox(height: 18),

        // ── Entra nella tua stanza (game layer) ──
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RoomScreen()),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: WevoColors.brand,
              boxShadow: [wevoGlow(WevoColors.pink, blur: 24)],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Entra nella tua stanza',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),

        // ── Vibe toggle ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Le tue vibe', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: WevoColors.textMuted)),
            if (!_editing)
              GestureDetector(
                onTap: () => setState(() => _editing = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: WevoColors.pink.withOpacity(0.1),
                    border: Border.all(color: WevoColors.pink.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, color: WevoColors.pink, size: 13),
                      const SizedBox(width: 4),
                      Text('Modifica', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: WevoColors.pink)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        Wrap(
          spacing: 10, runSpacing: 10,
          children: _allInterests.map((interest) {
            final active = _selectedInterests.contains(interest);
            return GestureDetector(
              onTap: _editing ? () => _toggleInterest(interest) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: active ? _vibeColor(interest).withOpacity(0.12) : Colors.white.withOpacity(0.03),
                  border: Border.all(
                    color: active ? _vibeColor(interest).withOpacity(0.5) : Colors.white.withOpacity(0.08),
                  ),
                  boxShadow: active ? [BoxShadow(color: _vibeColor(interest).withOpacity(0.15), blurRadius: 14)] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_vibeIcon(interest), size: 15, color: active ? _vibeColor(interest) : WevoColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      interest,
                      style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13,
                        color: active ? _vibeColor(interest) : WevoColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 30),

        // ── Giochi preferiti ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Giochi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: WevoColors.textMuted)),
            if (_editing) ...[
              // input per game
            ],
          ],
        ),
        const SizedBox(height: 14),

        if (_user != null && _user!.favoriteGames.isNotEmpty && !_editing)
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _user!.favoriteGames.map((g) => _gameChip(g, muted: true)).toList(),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF201233),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Text(
              _editing ? 'Aggiungi giochi nel campo sopra' : 'Nessun gioco ancora.',
              style: const TextStyle(color: WevoColors.textMuted, fontSize: 14),
            ),
          ),

        const SizedBox(height: 30),

        // ── Piattaforme ──
        if (_user != null && _user!.platforms.isNotEmpty && !_editing) ...[
          Text('Piattaforme', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: WevoColors.textMuted)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: (_user?.platforms ?? []).map((p) => _platformChip(p)).toList(),
          ),
          const SizedBox(height: 30),
        ],

        // ── Piattaforme edit ──
        if (_editing) ...[
          Text('Piattaforme', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: WevoColors.textMuted)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _allPlatforms.map((p) {
              final active = (_user?.platforms ?? []).contains(p);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    final list = List<String>.from(_user?.platforms ?? []);
                    if (list.contains(p)) list.remove(p); else list.add(p);
                    _user = _user != null
                      ? UserModel(id: _user!.id, name: _user!.name, username: _user!.username, age: _user!.age,
                          bio: _user!.bio, photoUrl: _user!.photoUrl, coverUrl: _user!.coverUrl,
                          interests: _user!.interests, favoriteGames: _user!.favoriteGames,
                          platforms: list, lookingFor: _user!.lookingFor, discordTag: _user!.discordTag)
                      : null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: active ? WevoColors.pink.withOpacity(0.12) : Colors.white.withOpacity(0.03),
                    border: Border.all(color: active ? WevoColors.pink.withOpacity(0.5) : Colors.white.withOpacity(0.08)),
                  ),
                  child: Text(p, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: active ? WevoColors.pink : WevoColors.textMuted)),
                ),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 30),

        // ── Social links ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Social', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: WevoColors.textMuted)),
            if (!_editing)
              GestureDetector(
                onTap: () => setState(() => _editing = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: WevoColors.pink.withOpacity(0.1),
                    border: Border.all(color: WevoColors.pink.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, color: WevoColors.pink, size: 13),
                      const SizedBox(width: 4),
                      Text('Modifica', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: WevoColors.pink)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF201233),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: [
              _socialRow(Icons.discord, 'Discord', _user?.discordTag, (val) => _discordCtrl.text = val),
              const SizedBox(height: 12),
              _socialRow(Icons.gamepad_outlined, 'Steam', _user?.steamId, null, readonly: true),
              const SizedBox(height: 12),
              _socialRow(Icons.music_note, 'Spotify', _user?.spotifyArtist, null, readonly: true),
            ],
          ),
        ),

        // ── Galleria placeholder ──
        const SizedBox(height: 36),
        Text('Galleria', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: WevoColors.textMuted)),
        const SizedBox(height: 14),
        Row(
          children: [
            for (int i = 0; i < 4; i++)
              Padding(
                padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 80.0) / 4,
                  height: (MediaQuery.of(context).size.width - 80.0) / 4 * 1.3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(colors: _galleryColors(i), begin: Alignment.topLeft, end: Alignment.bottomRight),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white.withOpacity(0.12), size: 32),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),

        // ── Pulsanti azione ──
        const SizedBox(height: 36),
        if (_editing) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _editing = false);
                  _loadUser();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Text('Annulla', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: WevoColors.textMuted)),
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: _saving ? null : _saveProfile,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: WevoColors.primaryGradient,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: WevoColors.hotPink.withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Salva profilo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                ),
              ),
            ],
          ),
        ] else ...[
          // Seed button (dev only — visible only for wevo demo user)
          GestureDetector(
            onTap: _seedDemoData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: WevoColors.primaryGradient,
                boxShadow: [BoxShadow(color: WevoColors.hotPink.withOpacity(0.3), blurRadius: 18)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(_seeding ? 'Seeding…' : 'Seed Demo', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => AuthService.logout(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFFF7D7D).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, color: const Color(0xFFFF7D7D), size: 16),
                  const SizedBox(width: 6),
                  const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFFFF7D7D))),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _socialRow(IconData icon, String label, String? value, Function(String)? onEdit, {bool readonly = false}) {
    return Row(
      children: [
        Icon(icon, color: WevoColors.textMuted, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: WevoColors.textMuted, fontSize: 14)),
        const Spacer(),
        Text(value ?? '—', style: const TextStyle(color: Color(0xFFE4E0EF), fontSize: 14)),
      ],
    );
  }

  Widget _gameChip(String game, {bool muted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: WevoColors.pink.withOpacity(0.07),
        border: Border.all(color: WevoColors.pink.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_esports_outlined, size: 14, color: const Color(0xFFFFB6D4)),
          const SizedBox(width: 5),
          Text(game, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFFFB6D4))),
        ],
      ),
    );
  }

  Widget _platformChip(String platform) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF62E6FF).withOpacity(0.07),
        border: Border.all(color: const Color(0xFF62E6FF).withOpacity(0.22)),
      ),
      child: Text(platform, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFB8F0FF))),
    );
  }

  Color _vibeColor(String label) {
    switch (label) {
      case 'Music': return const Color(0xFF8EC5FF);
      case 'Coffee': return const Color(0xFFFFC76A);
      case 'Travel': return const Color(0xFF62E6FF);
      case 'Books': return const Color(0xFFB98AE6);
      case 'Gaming': return const Color(0xFFFF5FA2);
      case 'Movies': return const Color(0xFF9EDFA6);
      case 'FPS': return const Color(0xFFFF7D7D);
      case 'MOBA': return const Color(0xFFBE7CFF);
      case 'Co-op': return const Color(0xFFFFC76A);
      case 'Anime': return const Color(0xFFFFB6D4);
      case 'Tech': return const Color(0xFF8EC5FF);
      case 'Design': return const Color(0xFFB98AE6);
      case 'Community': return const Color(0xFF9EDFA6);
      case 'Chill': return const Color(0xFF62E6FF);
      case 'Chat': return const Color(0xFFFFB6D4);
      default: return WevoColors.pink;
    }
  }

  IconData _vibeIcon(String label) {
    switch (label) {
      case 'Music': case 'FPS': return Icons.headphones;
      case 'Coffee': return Icons.coffee_outlined;
      case 'Travel': return Icons.flight_takeoff_outlined;
      case 'Books': case 'Design': return Icons.palette_outlined;
      case 'Gaming': case 'MOBA': return Icons.sports_esports_outlined;
      case 'Movies': return Icons.movie_outlined;
      case 'Co-op': case 'Community': return Icons.people_outline;
      case 'Anime': return Icons.auto_awesome;
      case 'Tech': return Icons.computer;
      case 'Chill': return Icons.wb_sunny_outlined;
      case 'Chat': return Icons.chat_outlined;
      default: return Icons.auto_awesome;
    }
  }

  List<Color> _galleryColors(int i) {
    return [
      [const Color(0xFF3A2150), const Color(0xFF241433)],
      [const Color(0xFF1F2F50), const Color(0xFF13203A)],
      [const Color(0xFF50213A), const Color(0xFF331425)],
      [const Color(0xFF214A3A), const Color(0xFF142E25)],
    ][i % 4];
  }
}
