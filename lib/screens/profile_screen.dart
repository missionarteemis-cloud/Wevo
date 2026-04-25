import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';

const _allInterests = [
  'Gaming', 'Viaggi', 'Musica', 'Cinema', 'Cucina', 'Sport',
  'Fotografia', 'Arte', 'Lettura', 'Yoga', 'Tecnologia', 'Anime',
  'Calcio', 'Running', 'Design', 'Natura', 'Moda', 'Podcast',
  'Arrampicata', 'Astronomia', 'Danza', 'Cucina etnica',
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = true;
  bool _editing = false;
  bool _saving  = false;

  final _bioCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  List<String> _selectedInterests = [];

  Uint8List? _pendingProfileBytes;
  String?    _pendingProfileExt;
  Uint8List? _pendingCoverBytes;
  String?    _pendingCoverExt;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    final user = await UserService.fetchCurrentUser();
    if (mounted) setState(() { _user = user; _loading = false; });
  }

  void _startEditing() {
    _bioCtrl.text = _user?.bio ?? '';
    _ageCtrl.text = (_user?.age ?? 0) > 0 ? '${_user!.age}' : '';
    _selectedInterests = List.from(_user?.interests ?? []);
    _pendingProfileBytes = null;
    _pendingCoverBytes   = null;
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    _pendingProfileBytes = null;
    _pendingCoverBytes   = null;
    setState(() => _editing = false);
  }

  Future<void> _pickPhoto({required bool isCover}) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext   = file.name.split('.').last.toLowerCase();
    setState(() {
      if (isCover) {
        _pendingCoverBytes   = bytes;
        _pendingCoverExt     = ext;
      } else {
        _pendingProfileBytes = bytes;
        _pendingProfileExt   = ext;
      }
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    bool success = false;

    try {
      final age = (int.tryParse(_ageCtrl.text.trim()) ?? _user?.age ?? 0).clamp(0, 120);

      String? newPhotoUrl;
      String? newCoverUrl;

      // Upload foto — se fallisce avvisa l'utente ma continua col resto
      if (_pendingProfileBytes != null) {
        newPhotoUrl = await StorageService.uploadProfilePhoto(
            _pendingProfileBytes!, _pendingProfileExt ?? 'jpg');
        if (newPhotoUrl == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload foto profilo fallito. Abilita Firebase Storage nella console.'),
              backgroundColor: WevoColors.coral,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
      if (_pendingCoverBytes != null) {
        newCoverUrl = await StorageService.uploadCoverPhoto(
            _pendingCoverBytes!, _pendingCoverExt ?? 'jpg');
        if (newCoverUrl == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload foto copertina fallito. Abilita Firebase Storage nella console.'),
              backgroundColor: WevoColors.coral,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }

      // Salva sempre i dati testuali (bio, interessi, età)
      final error = await UserService.updateProfile(
        bio      : _bioCtrl.text,
        interests: _selectedInterests,
        age      : age,
        photoUrl : newPhotoUrl,  // null se upload fallito → non sovrascrive
        coverUrl : newCoverUrl,
      );

      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: WevoColors.coral),
        );
      } else {
        success = true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore durante il salvataggio. Riprova.'),
              backgroundColor: WevoColors.coral),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          if (success) {
            _editing = false;
            _pendingProfileBytes = null;
            _pendingCoverBytes   = null;
          }
        });
        if (success) await _loadUser();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: WevoColors.pink)),
      );
    }

    final user = _user;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Profilo non trovato.'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadUser, child: const Text('Riprova')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Cover (SliverAppBar) ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _pendingCoverBytes != null
                      ? Image.memory(_pendingCoverBytes!, fit: BoxFit.cover)
                      : Image.network(
                          user.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, err, stack) {
                            debugPrint('[ProfileScreen] cover load error: $err');
                            return Container(color: WevoColors.dark);
                          },
                        ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black45],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                  if (_editing)
                    Positioned(
                      bottom: 12, right: 12,
                      child: _CameraBtn(onTap: () => _pickPhoto(isCover: true)),
                    ),
                ],
              ),
            ),
            actions: _editing
                ? [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _saving ? null : _cancelEditing,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _saving
                          ? const Center(
                              child: SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            )
                          : IconButton(
                              icon: const Icon(Icons.check, color: WevoColors.sage),
                              onPressed: _saveProfile,
                            ),
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: _startEditing,
                    ),
                  ],
          ),

          // ── Corpo ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar + nome/età ─────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar circolare
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: WevoColors.dark,
                              backgroundImage: _pendingProfileBytes != null
                                  ? MemoryImage(_pendingProfileBytes!) as ImageProvider
                                  : NetworkImage(user.photoUrl),
                            ),
                          ),
                          if (_editing)
                            Positioned(
                              bottom: 0, right: 0,
                              child: _CameraBtn(
                                onTap: () => _pickPhoto(isCover: false),
                                small: true,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(width: 16),

                      // Nome + età
                      Expanded(
                        child: _editing
                            ? _AgeField(controller: _ageCtrl)
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.name,
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                  Text(
                                    user.age > 0 ? '${user.age} anni' : 'Età non impostata',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Bio ───────────────────────────────────────────────────
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('Bio'),
                        const SizedBox(height: 8),
                        _editing
                            ? TextField(
                                controller: _bioCtrl,
                                maxLines: 4,
                                maxLength: 300,
                                decoration: _fieldDeco('Raccontati in poche righe...'),
                              )
                            : Text(
                                user.bio.isEmpty
                                    ? 'Nessuna bio. Tocca ✎ per aggiungerla.'
                                    : user.bio,
                                style: TextStyle(
                                  color: user.bio.isEmpty ? Colors.grey : Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Interessi ─────────────────────────────────────────────
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('Interessi'),
                        const SizedBox(height: 10),
                        _editing
                            ? Wrap(
                                spacing: 8, runSpacing: 6,
                                children: _allInterests.map((interest) {
                                  final sel = _selectedInterests.contains(interest);
                                  return FilterChip(
                                    label: Text(interest),
                                    selected: sel,
                                    onSelected: (v) => setState(() => v
                                        ? _selectedInterests.add(interest)
                                        : _selectedInterests.remove(interest)),
                                    selectedColor: WevoColors.pink.withOpacity(0.18),
                                    checkmarkColor: WevoColors.pink,
                                    labelStyle: TextStyle(
                                      color: sel ? WevoColors.pink : Colors.black54,
                                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                    side: BorderSide(
                                      color: sel
                                          ? WevoColors.pink.withOpacity(0.6)
                                          : Colors.black12,
                                    ),
                                  );
                                }).toList(),
                              )
                            : user.interests.isEmpty
                                ? Text('Nessun interesse. Tocca ✎ per aggiungerli.',
                                    style: TextStyle(color: Colors.grey[500]))
                                : Wrap(
                                    spacing: 8, runSpacing: 8,
                                    children: user.interests
                                        .map((i) => _InterestChip(label: i))
                                        .toList(),
                                  ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── App collegate ─────────────────────────────────────────
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('App collegate'),
                        const SizedBox(height: 12),
                        _AppRow(
                          icon: Icons.games, color: WevoColors.lightBlue,
                          label: 'Discord', value: user.discordTag ?? 'Non collegato',
                          onTap: () {},
                        ),
                        const Divider(height: 20),
                        _AppRow(
                          icon: Icons.tv, color: WevoColors.coral,
                          label: 'Netflix',
                          value: user.hasNetflix ? 'Collegato' : 'Non collegato',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Logout ────────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, color: WevoColors.coral),
                      label: const Text('Esci', style: TextStyle(color: WevoColors.coral)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: WevoColors.coral),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => AuthService.logout(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDeco(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(color: Colors.grey[400]),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: WevoColors.pink),
  ),
  counterText: '',
  contentPadding: const EdgeInsets.all(12),
);

// ── Widget interni ────────────────────────────────────────────────────────────

class _CameraBtn extends StatelessWidget {
  final VoidCallback onTap;
  final bool small;
  const _CameraBtn({required this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) {
    final s = small ? 28.0 : 36.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: s, height: s,
        decoration: const BoxDecoration(color: WevoColors.pink, shape: BoxShape.circle),
        child: Icon(Icons.camera_alt, color: Colors.white, size: small ? 14 : 18),
      ),
    );
  }
}

class _AgeField extends StatelessWidget {
  final TextEditingController controller;
  const _AgeField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Età',
          labelStyle: const TextStyle(color: WevoColors.pink),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: WevoColors.pink),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: WevoColors.dark.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: Colors.black38, letterSpacing: 1),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  const _InterestChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: WevoColors.pink.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WevoColors.pink.withOpacity(0.4)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: WevoColors.pink, fontWeight: FontWeight.w500, fontSize: 13)),
    );
  }
}

class _AppRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _AppRow({
    required this.icon, required this.color,
    required this.label, required this.value, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(value, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
