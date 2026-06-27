import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../theme.dart';
import '../../main.dart';

const _onboardingInterests = [
  'FPS', 'MOBA', 'Co-op', 'Anime', 'Tech', 'Music', 'Movies', 'Community', 'Chill', 'Design'
];
const _onboardingPlatforms = ['PC', 'PlayStation', 'Xbox', 'Switch', 'Mobile'];
const _onboardingLookingFor = ['Ranked', 'Duo', 'Chill', 'Friendship', 'Community'];

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _bioCtrl = TextEditingController();
  final _gamesCtrl = TextEditingController();
  final _discordCtrl = TextEditingController();

  final List<String> _interests = [];
  final List<String> _platforms = [];
  final List<String> _lookingFor = [];
  bool _saving = false;
  String? _error;

  List<String> _csv(String raw) => raw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _finish() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final err = await UserService.updateProfile(
      bio: _bioCtrl.text,
      interests: _interests,
      favoriteGames: _csv(_gamesCtrl.text),
      platforms: _platforms,
      lookingFor: _lookingFor,
      age: 18,
      discordTag: _discordCtrl.text,
      country: 'Italia',
      timezone: 'CET',
    );

    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err.message;
      });
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => MainShell(shellKey: mainShellKey)),
      (_) => false,
    );
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            children: [
              const Text(
                'Complete your profile',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Facciamo in modo che il tuo feed abbia davvero senso.',
                style: TextStyle(color: WevoColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 22),
              _SectionCard(
                title: 'Bio',
                child: TextField(
                  controller: _bioCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: _input('Racconta la tua vibe gaming/social'),
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Top games',
                child: TextField(
                  controller: _gamesCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _input('Valorant, LoL, Fortnite...'),
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Discord',
                child: TextField(
                  controller: _discordCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _input('Il tuo tag Discord'),
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Interests',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _onboardingInterests.map((item) => _selectChip(item, _interests)).toList(),
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Platforms',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _onboardingPlatforms.map((item) => _selectChip(item, _platforms)).toList(),
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Looking for',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _onboardingLookingFor.map((item) => _selectChip(item, _lookingFor)).toList(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: WevoColors.coral)),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: WevoColors.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [wevoGlow(WevoColors.pink, blur: 22)],
                  ),
                  child: ElevatedButton(
                    onPressed: _saving ? null : _finish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Finish setup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectChip(String item, List<String> bucket) {
    final selected = bucket.contains(item);
    return FilterChip(
      label: Text(item),
      selected: selected,
      onSelected: (_) => setState(() {
        selected ? bucket.remove(item) : bucket.add(item);
      }),
      selectedColor: WevoColors.pink.withOpacity(0.18),
      checkmarkColor: WevoColors.pink,
      labelStyle: TextStyle(color: selected ? WevoColors.pink : Colors.white),
      backgroundColor: Colors.white.withOpacity(0.06),
      side: BorderSide(color: Colors.white.withOpacity(0.08)),
    );
  }
}

InputDecoration _input(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: WevoColors.textMuted),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: WevoColors.pink),
      ),
    );

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WevoColors.darkSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
