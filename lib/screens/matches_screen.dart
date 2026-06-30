import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/match_service.dart';
import '../theme.dart';
import '../widgets/online_dot.dart';

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
  List<Map<String, dynamic>> _messages = const [];
  String _groupFilter = 'Tutte';
  String? _sendError;
  final List<Map<String, dynamic>> _optimistic = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final real = await MatchService.fetchMatchUsers().timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _matches = real;
        _loading = false;
        if (_selected == null && _matches.isNotEmpty) {
          _selected = _matches.first;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _matches = const [];
        _loading = false;
      });
    }
  }

  void _selectChat(UserModel user) {
    setState(() {
      _selected = user;
      _sendError = null;
    });
  }

  Future<void> _sendMsg() async {
    final user = _selected;
    final text = _msgCtrl.text.trim();
    if (user == null || text.isEmpty) return;

    // Optimistic: il messaggio parte subito, il campo si svuota all'istante.
    _msgCtrl.clear();
    final opt = <String, dynamic>{
      'senderId': ChatService.currentUid,
      'text': text,
      'createdAt': null,
      '_pending': true,
    };
    setState(() {
      _optimistic.add(opt);
      _sendError = null;
    });
    _scrollToBottom();

    final result = await ChatService.sendMessage(otherUserId: user.id, text: text);
    if (!mounted) return;

    if (result.ok) {
      // ripulito quando lo stream conferma (vedi builder); safety net a 6s.
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted && _optimistic.contains(opt)) {
          setState(() => _optimistic.remove(opt));
        }
      });
    } else {
      setState(() {
        _optimistic.remove(opt);
        _sendError = _messageForSendError(result.error);
        _msgCtrl.text = text;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
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
        if (isDesktop) return _desktopLayout();
        return _mobileLayout();
      },
    );
  }

  Widget _mobileLayout() {
    if (_selected != null) {
      return _chatThread(mobile: true);
    }
    return _matchList();
  }

  Widget _desktopLayout() {
    return Stack(
      children: [
        const Positioned(top: -80, left: -50, child: _AmbientOrb(size: 180, color: Color(0x14FA61A6))),
        const Positioned(bottom: 60, right: -40, child: _AmbientOrb(size: 220, color: Color(0x106DD7D7))),
        Row(
          children: [
            SizedBox(width: 400, child: _matchList()),
            Container(width: 1, color: Colors.white.withValues(alpha: 0.06)),
            Expanded(child: _selected != null ? _chatThread(mobile: false) : _emptyChat()),
          ],
        ),
      ],
    );
  }

  Widget _matchList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x22FFFFFF), Color(0x10FFFFFF)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 26, offset: const Offset(0, 14)),
                  ],
                ),
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
                    const Text('Matches', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 23, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 5),
                    const Text(
                      'Le conversazioni migliori non sembrano una inbox. Sembrano un posto dove tornare.',
                      style: TextStyle(color: WevoColors.textMuted, fontSize: 13.5, height: 1.35),
                    ),
                    const SizedBox(height: 16),
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
                                borderRadius: BorderRadius.circular(999),
                                gradient: active
                                    ? const LinearGradient(colors: [Color(0x22FA61A6), Color(0x166DD7D7)])
                                    : null,
                                color: active ? null : Colors.white.withValues(alpha: 0.04),
                                border: Border.all(color: active ? WevoColors.pink.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Text(f, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: active ? Colors.white : WevoColors.textMuted)),
                            ),
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
        Expanded(
          child: _matches.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Nessun match reale disponibile ancora.\nFai un match vero in Discover e la chat comparirà qui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: WevoColors.textMuted, fontSize: 14, height: 1.45),
                    ),
                  ),
                )
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: ChatService.chatPreviewsStream(),
                  builder: (context, snapshot) {
                    final previews = _previewMap(snapshot.data ?? const []);
                    final visibleMatches = _filteredMatches(previews);
                    if (visibleMatches.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _groupFilter == 'Nuove' ? 'Nessuna chat nuova al momento.' : 'Nessun match visibile con questo filtro.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: WevoColors.textMuted, fontSize: 14),
                          ),
                        ),
                      );
                    }

                    if (_selected != null && !visibleMatches.any((u) => u.id == _selected!.id)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() => _selected = visibleMatches.first);
                      });
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      itemCount: visibleMatches.length,
                      itemBuilder: (_, i) => _matchTile(visibleMatches[i], previews[visibleMatches[i].id]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Map<String, Map<String, dynamic>> _previewMap(List<Map<String, dynamic>> previews) {
    final map = <String, Map<String, dynamic>>{};
    for (final preview in previews) {
      final users = List<String>.from(preview['users'] ?? const []);
      final otherId = users.where((id) => id != ChatService.currentUid).cast<String?>().firstWhere((id) => id != null, orElse: () => null);
      if (otherId != null) {
        map[otherId] = preview;
      }
    }
    return map;
  }

  List<UserModel> _filteredMatches(Map<String, Map<String, dynamic>> previews) {
    final now = DateTime.now();
    final sorted = [..._matches]
      ..sort((a, b) {
        final aTs = previews[a.id]?['lastMessageAt'];
        final bTs = previews[b.id]?['lastMessageAt'];
        final aDate = aTs is Timestamp ? aTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = bTs is Timestamp ? bTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return sorted.where((user) {
      final preview = previews[user.id];
      switch (_groupFilter) {
        case 'Online':
          return true;
        case 'Nuove':
          final ts = preview?['lastMessageAt'];
          if (ts is! Timestamp) return false;
          return now.difference(ts.toDate()).inHours < 24;
        default:
          return true;
      }
    }).toList();
  }

  Widget _matchTile(UserModel user, Map<String, dynamic>? preview) {
    final isActive = _selected?.id == user.id;
    final lastMsg = preview?['lastMessage'] as String?;
    final lastTime = _previewTime(preview?['lastMessageAt']);
    final variant = _variantFor(user);
    final isUnread = preview != null && preview['lastSenderId'] != null && preview['lastSenderId'] != ChatService.currentUid;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(colors: [Color(0x22FA61A6), Color(0x126DD7D7)])
                  : const LinearGradient(colors: [Color(0x12FFFFFF), Color(0x08FFFFFF)]),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: isActive ? WevoColors.pink.withValues(alpha: 0.32) : Colors.white.withValues(alpha: 0.06)),
              boxShadow: [
                if (isActive) wevoGlow(WevoColors.pink, blur: 20),
                if (!isActive) BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 10)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () => _selectChat(user),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [WevoColors.pink, Color(0xFFB98AE6), Color(0xFF8EC5FF)]),
                              boxShadow: [wevoGlow(WevoColors.pink, blur: 16)],
                            ),
                            child: CircleAvatar(
                              backgroundColor: const Color(0xFF1A1128),
                              backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                              child: user.photoUrl.isEmpty ? Text(user.name[0].toUpperCase(), style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600, color: Color(0xFFFFB6D4), fontSize: 18)) : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: OnlineDot(uid: user.id, size: 14),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                                ),
                                if (lastTime != null) Text(lastTime, style: const TextStyle(color: WevoColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: variant.color.withValues(alpha: 0.12),
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
                                const SizedBox(width: 8),
                                if (isUnread)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: const Color(0x22FA61A6),
                                      border: Border.all(color: const Color(0x44FA61A6)),
                                    ),
                                    child: const Text('Nuovo', style: TextStyle(color: Color(0xFFFFB6D4), fontSize: 10, fontWeight: FontWeight.w700)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              lastMsg ?? 'Ditevi qualcosa.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: WevoColors.textMuted, fontSize: 13.5, height: 1.25),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chatThread({required bool mobile}) {
    final u = _selected!;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ChatService.messagesStream(otherUserId: u.id),
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const [];
        final myTexts = messages
            .where((m) => m['senderId'] == ChatService.currentUid)
            .map((m) => (m['text'] ?? '') as String)
            .toSet();
        final shownOpt = _optimistic.where((o) => !myTexts.contains(o['text'])).toList();
        if (shownOpt.length != _optimistic.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _optimistic.removeWhere((o) => myTexts.contains(o['text'])));
          });
        }
        final all = [...messages, ...shownOpt];
        if (_messages.length != all.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_scrollCtrl.hasClients) return;
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            );
          });
        }
        _messages = all;

        return Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(mobile ? 16 : 22, 22, mobile ? 16 : 22, 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
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
                  Container(
                    width: 44,
                    height: 44,
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
                  Icon(Icons.phone_outlined, color: WevoColors.textMuted, size: 20),
                  const SizedBox(width: 14),
                  Icon(Icons.more_horiz, color: WevoColors.textMuted, size: 22),
                ],
              ),
            ),
            Expanded(
              child: all.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: WevoColors.pink.withValues(alpha: 0.08)),
                            child: const Icon(Icons.chat, color: WevoColors.pink, size: 28),
                          ),
                          const SizedBox(height: 14),
                          Text('Ditevi qualcosa per iniziare!', style: TextStyle(color: WevoColors.textMuted, fontSize: 14)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                      itemCount: all.length,
                      itemBuilder: (_, i) => _msgBubble(all[i]),
                    ),
            ),
            if (_sendError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _sendError!,
                    style: const TextStyle(color: Color(0xFFFF8AA8), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF201233),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: WevoColors.textMuted, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
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
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMsg,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: WevoColors.primaryGradient,
                        boxShadow: [BoxShadow(color: WevoColors.hotPink.withValues(alpha: 0.5), blurRadius: 20)],
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _msgBubble(Map<String, dynamic> msg) {
    final isMe = msg['senderId'] == ChatService.currentUid;
    final createdAt = msg['createdAt'];
    final time = createdAt is Timestamp ? _formatTime(createdAt.toDate()) : 'Ora';
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
          gradient: isMe ? WevoColors.primaryGradient : const LinearGradient(colors: [Color(0xFF201233), Color(0xFF2A1C40)]),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text((msg['text'] ?? '') as String, style: TextStyle(color: isMe ? Colors.white : const Color(0xFFE4E0EF), fontSize: 15, height: 1.4)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time, style: TextStyle(color: isMe ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6B6178), fontSize: 11)),
                if (isMe) ...[
                  const SizedBox(width: 5),
                  Icon(
                    msg['_pending'] == true ? Icons.access_time_rounded : Icons.done_rounded,
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, color: WevoColors.pink.withValues(alpha: 0.1)),
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

class _AmbientOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _AmbientOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: size * 0.42, spreadRadius: size * 0.04)],
        ),
      ),
    );
  }
}

String? _previewTime(dynamic value) {
  if (value is! Timestamp) return null;
  final dt = value.toDate();
  final now = DateTime.now();
  if (now.year == dt.year && now.month == dt.month && now.day == dt.day) {
    return _formatTime(dt);
  }
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _messageForSendError(String? code) {
  switch (code) {
    case 'not-matched':
      return 'Puoi scrivere solo a utenti con cui hai un match reale.';
    case 'recipient-not-found':
      return 'Utente non disponibile.';
    case 'permission-denied':
      return 'Permesso negato dal backend.';
    case 'unavailable':
      return 'Backend non raggiungibile, riprova tra poco.';
    default:
      return 'Invio non riuscito. Riprova.';
  }
}

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
