import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';

const _allInterests = [
  'Gaming', 'FPS', 'MOBA', 'Co-op', 'Anime', 'Tech', 'Design', 'Music', 'Community', 'Chill',
];
const _allPlatforms = ['PC', 'PlayStation', 'Xbox', 'Switch', 'Mobile'];
const _allLookingFor = ['Ranked', 'Duo', 'Chill', 'Friendship', 'Community'];

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

  final _bioCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _gamesCtrl = TextEditingController();
  final _discordCtrl = TextEditingController();
  final _steamCtrl = TextEditingController();
  final _spotifyCtrl = TextEditingController();
  final _riotCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _timezoneCtrl = TextEditingController();

  List<String> _selectedInterests = [];
  List<String> _selectedPlatforms = [];
  List<String> _selectedLookingFor = [];

  Uint8List? _pendingProfileBytes;
  String? _pendingProfileExt;
  Uint8List? _pendingCoverBytes;
  String? _pendingCoverExt;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _ageCtrl.dispose();
    _gamesCtrl.dispose();
    _discordCtrl.dispose();
    _steamCtrl.dispose();
    _spotifyCtrl.dispose();
    _riotCtrl.dispose();
    _countryCtrl.dispose();
    _timezoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    final user = await UserService.fetchCurrentUser();
    if (mounted) setState(() { _user = user; _loading = false; });
  }

  void _startEditing() {
    final u = _user;
    if (u == null) return;
    _bioCtrl.text = u.bio;
    _ageCtrl.text = u.age > 0 ? '${u.age}' : '';
    _gamesCtrl.text = u.favoriteGames.join(', ');
    _discordCtrl.text = u.discordTag ?? '';
    _steamCtrl.text = u.steamId ?? '';
    _spotifyCtrl.text = u.spotifyArtist ?? '';
    _riotCtrl.text = u.riotId ?? '';
    _countryCtrl.text = u.country;
    _timezoneCtrl.text = u.timezone;
    _selectedInterests = List.from(u.interests);
    _selectedPlatforms = List.from(u.platforms);
    _selectedLookingFor = List.from(u.lookingFor);
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    setState(() { _editing = false; _pendingProfileBytes = null; _pendingCoverBytes = null; });
  }

  Future<void> _pickPhoto({required bool isCover}) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    setState(() {
      if (isCover) { _pendingCoverBytes = bytes; _pendingCoverExt = ext; }
      else { _pendingProfileBytes = bytes; _pendingProfileExt = ext; }
    });
  }

  List<String> _parseCsv(String raw) => raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Future<void> _saveProfile() async {
    final u = _user;
    if (u == null) return;
    setState(() => _saving = true);
    bool success = false;
    try {
      final age = (int.tryParse(_ageCtrl.text.trim()) ?? u.age).clamp(0, 120);
      String? newPhoto, newCover;
      if (_pendingProfileBytes != null) newPhoto = await StorageService.uploadProfilePhoto(_pendingProfileBytes!, _pendingProfileExt ?? 'jpg');
      if (_pendingCoverBytes != null) newCover = await StorageService.uploadCoverPhoto(_pendingCoverBytes!, _pendingCoverExt ?? 'jpg');
      final err = await UserService.updateProfile(
        bio: _bioCtrl.text, interests: _selectedInterests, favoriteGames: _parseCsv(_gamesCtrl.text),
        platforms: _selectedPlatforms, lookingFor: _selectedLookingFor, age: age,
        discordTag: _discordCtrl.text, steamId: _steamCtrl.text, spotifyArtist: _spotifyCtrl.text,
        riotId: _riotCtrl.text, country: _countryCtrl.text, timezone: _timezoneCtrl.text,
        photoUrl: newPhoto, coverUrl: newCover,
      );
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.message), backgroundColor: WevoColors.coral));
      } else { success = true; }
    } finally {
      if (mounted) {
        setState(() { _saving = false; if (success) { _editing = false; _pendingProfileBytes = null; _pendingCoverBytes = null; } });
      }
      if (success && mounted) await _loadUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: WevoColors.pink)));
    }
    final u = _user;
    if (u == null) {
      return Scaffold(body: Center(child: ElevatedButton(onPressed: _loadUser, child: const Text('Riprova'))));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [WevoColors.bg, WevoColors.dark, WevoColors.darkSoft],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 768;
              return Center(
                child: SizedBox(
                  width: isDesktop ? 400 : double.infinity,
                  child: _ProfileContent(
                    user: u, editing: _editing, saving: _saving,
                    startEditing: _startEditing,
                    cancelEditing: _cancelEditing,
                    saveProfile: _saveProfile,
                    pickPhoto: _pickPhoto,
                    pendingProfileBytes: _pendingProfileBytes,
                    pendingCoverBytes: _pendingCoverBytes,
                    bioCtrl: _bioCtrl,
                    gamesCtrl: _gamesCtrl,
                    discordCtrl: _discordCtrl,
                    steamCtrl: _steamCtrl,
                    spotifyCtrl: _spotifyCtrl,
                    riotCtrl: _riotCtrl,
                    countryCtrl: _countryCtrl,
                    timezoneCtrl: _timezoneCtrl,
                    selectedInterests: _selectedInterests,
                    selectedPlatforms: _selectedPlatforms,
                    selectedLookingFor: _selectedLookingFor,
                    toggleInterest: (item) {
                      setState(() {
                        _selectedInterests.contains(item)
                            ? _selectedInterests.remove(item)
                            : _selectedInterests.add(item);
                      });
                    },
                    togglePlatform: (item) {
                      setState(() {
                        _selectedPlatforms.contains(item)
                            ? _selectedPlatforms.remove(item)
                            : _selectedPlatforms.add(item);
                      });
                    },
                    toggleLookingFor: (item) {
                      setState(() {
                        _selectedLookingFor.contains(item)
                            ? _selectedLookingFor.remove(item)
                            : _selectedLookingFor.add(item);
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── ProfileContent (split to keep the stateful widget manageable) ───────────

class _ProfileContent extends StatelessWidget {
  final UserModel user;
  final bool editing;
  final bool saving;
  final VoidCallback startEditing;
  final VoidCallback cancelEditing;
  final VoidCallback saveProfile;
  final Future<void> Function({required bool isCover}) pickPhoto;
  final Uint8List? pendingProfileBytes;
  final Uint8List? pendingCoverBytes;
  final TextEditingController bioCtrl;
  final TextEditingController gamesCtrl;
  final TextEditingController discordCtrl;
  final TextEditingController steamCtrl;
  final TextEditingController spotifyCtrl;
  final TextEditingController riotCtrl;
  final TextEditingController countryCtrl;
  final TextEditingController timezoneCtrl;
  final List<String> selectedInterests;
  final List<String> selectedPlatforms;
  final List<String> selectedLookingFor;
  final void Function(String item) toggleInterest;
  final void Function(String item) togglePlatform;
  final void Function(String item) toggleLookingFor;

  const _ProfileContent({
    required this.user,
    required this.editing,
    required this.saving,
    required this.startEditing,
    required this.cancelEditing,
    required this.saveProfile,
    required this.pickPhoto,
    this.pendingProfileBytes,
    this.pendingCoverBytes,
    required this.bioCtrl,
    required this.gamesCtrl,
    required this.discordCtrl,
    required this.steamCtrl,
    required this.spotifyCtrl,
    required this.riotCtrl,
    required this.countryCtrl,
    required this.timezoneCtrl,
    required this.selectedInterests,
    required this.selectedPlatforms,
    required this.selectedLookingFor,
    required this.toggleInterest,
    required this.togglePlatform,
    required this.toggleLookingFor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Cover ──
        Positioned(
          top: 0, left: 0, right: 0, height: 120,
          child: GestureDetector(
            onTap: editing ? () => pickPhoto(isCover: true) : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                pendingCoverBytes != null
                    ? Image.memory(pendingCoverBytes!, fit: BoxFit.cover)
                    : (user.coverUrl.isNotEmpty
                        ? Image.network(user.coverUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _coverPlaceholder())
                        : _coverPlaceholder()),
                if (editing)
                  Positioned(right: 12, top: 12, child: _CameraBtn(onTap: () => pickPhoto(isCover: true))),
              ],
            ),
          ),
        ),
        // ── Avatar ──
        Positioned(
          top: 80, left: 20,
          child: GestureDetector(
            onTap: editing ? () => pickPhoto(isCover: false) : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: pendingProfileBytes != null
                      ? MemoryImage(pendingProfileBytes!)
                      : (user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null),
                  child: (user.photoUrl.isEmpty && pendingProfileBytes == null)
                      ? const Icon(Icons.person, size: 40, color: Colors.white54)
                      : null,
                ),
                if (editing)
                  Positioned(right: -2, bottom: -2, child: _CameraBtn(onTap: () => pickPhoto(isCover: false), small: true)),
              ],
            ),
          ),
        ),
        // ── Edit / logout buttons ──
        Positioned(
          top: 8, right: 12,
          child: editing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(onPressed: saving ? null : cancelEditing, icon: const Icon(Icons.close, color: Colors.white70)),
                    if (saving)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    else
                      IconButton(onPressed: saveProfile, icon: const Icon(Icons.check, color: WevoColors.sage)),
                  ],
                )
              : IconButton(onPressed: startEditing, icon: const Icon(Icons.edit, color: Colors.white70)),
        ),
        // ── Scroll content ──
        Positioned(
          top: 0, left: 0, right: 0, bottom: 0,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 140, 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(user.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('@${user.username}', style: const TextStyle(color: WevoColors.pink, fontWeight: FontWeight.w700, fontSize: 15)),
                if (user.age > 0 || user.country.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${user.age > 0 ? '${user.age} anni' : ''}${user.age > 0 && user.country.isNotEmpty ? ' · ' : ''}${user.country.isNotEmpty ? user.country : ''}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 18),
                // ── Bio ──
                if (!editing && user.bio.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Text(user.bio, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                  ),
                if (editing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _capsuleField(controller: bioCtrl, hint: 'Bio', maxLines: 3),
                  ),
                // ── Platforms chips ──
                if (user.platforms.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Wrap(spacing: 8, runSpacing: 8, children: user.platforms.map((p) => _neonChip(p)).toList()),
                  ),
                // ── Favorite Games ──
                _card(
                  title: 'Favorite Games',
                  child: editing
                      ? _capsuleField(controller: gamesCtrl, hint: 'Valorant, LoL, Fortnite...')
                      : (user.favoriteGames.isEmpty
                          ? const Text('Nessun gioco ancora', style: TextStyle(color: Colors.white38))
                          : Wrap(spacing: 8, runSpacing: 8, children: user.favoriteGames.map((g) => _neonChip(g, color: WevoColors.cyan)).toList())),
                ),
                const SizedBox(height: 14),
                // ── Interests ──
                _card(
                  title: 'Interests',
                  child: editing
                      ? Wrap(spacing: 8, runSpacing: 8, children: _allInterests.map((item) => _editChip(item, selectedInterests.contains(item), toggleInterest)).toList())
                      : (user.interests.isEmpty
                          ? const Text('Nessun interesse', style: TextStyle(color: Colors.white38))
                          : Wrap(spacing: 8, runSpacing: 8, children: user.interests.map((i) => _neonChip(i)).toList())),
                ),
                const SizedBox(height: 14),
                // ── Social & Gaming Links ──
                _card(
                  title: 'Social & Gaming Links',
                  child: Column(
                    children: editing
                        ? [
                            _capsuleField(controller: discordCtrl, hint: 'Discord tag'),
                            const SizedBox(height: 10),
                            _capsuleField(controller: steamCtrl, hint: 'Steam ID'),
                            const SizedBox(height: 10),
                            _capsuleField(controller: riotCtrl, hint: 'Riot ID'),
                            const SizedBox(height: 10),
                            _capsuleField(controller: spotifyCtrl, hint: 'Spotify artist'),
                            const SizedBox(height: 10),
                            _capsuleField(controller: countryCtrl, hint: 'Paese'),
                            const SizedBox(height: 10),
                            _capsuleField(controller: timezoneCtrl, hint: 'Timezone'),
                          ]
                        : [
                            _linkRow('Discord', user.discordTag),
                            _linkRow('Steam', user.steamId),
                            _linkRow('Riot', user.riotId),
                            _linkRow('Spotify', user.spotifyArtist),
                            _linkRow('Paese', user.country),
                            _linkRow('Timezone', user.timezone),
                          ],
                  ),
                ),
                const SizedBox(height: 28),
                // ── Logout ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => AuthService.logout(),
                    icon: const Icon(Icons.logout, color: WevoColors.coral),
                    label: const Text('Esci', style: TextStyle(color: WevoColors.coral)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: WevoColors.coral.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _linkRow(String label, String? value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(width: 72, child: Text(label, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600))),
            Expanded(child: Text(value != null && value.isNotEmpty ? value : '--', style: const TextStyle(color: Colors.white70))),
          ],
        ),
      );

  Widget _editChip(String item, bool selected, void Function(String) onToggle) {
    return FilterChip(
      label: Text(item),
      selected: selected,
      onSelected: (_) => onToggle(item),
      selectedColor: WevoColors.pink.withOpacity(0.15),
      checkmarkColor: WevoColors.pink,
      labelStyle: TextStyle(color: selected ? WevoColors.pink : Colors.white70),
      backgroundColor: Colors.white.withOpacity(0.06),
      side: BorderSide(color: Colors.white.withOpacity(0.10)),
    );
  }
}

// ── Standalone helpers ──────────────────────────────────────────────────────

Widget _coverPlaceholder() => Container(color: const Color(0xFF1A1525));

Widget _capsuleField({
  required TextEditingController controller,
  required String hint,
  int maxLines = 1,
}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: WevoColors.pink, width: 1.0),
      ),
    ),
  );
}

Widget _card({required String title, required Widget child}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1525).withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: child,
      ),
    ],
  );
}

Widget _neonChip(String label, {Color color = WevoColors.pink}) {
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

class _CameraBtn extends StatelessWidget {
  final VoidCallback onTap;
  final bool small;
  const _CameraBtn({required this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) {
    final size = small ? 28.0 : 34.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: const BoxDecoration(color: WevoColors.pink, shape: BoxShape.circle),
        child: Icon(Icons.camera_alt, color: Colors.white, size: small ? 14 : 18),
      ),
    );
  }
}
