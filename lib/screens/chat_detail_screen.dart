import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../theme.dart';

/// Stato consegna messaggio (stile WhatsApp).
/// pending = orologino (non ancora partito), sent = spunta singola,
/// delivered = doppia grigia, read = doppia blu (questi ultimi due via
/// read-receipt lato backend — prossimo step).
enum _MsgStatus { pending, sent, delivered, read }

/// Messaggio inviato localmente, in attesa di conferma dallo stream.
class _Optimistic {
  final String text;
  final DateTime createdAt;
  _Optimistic(this.text) : createdAt = DateTime.now();
}

class ChatDetailScreen extends StatefulWidget {
  final UserModel user;
  const ChatDetailScreen({super.key, required this.user});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String? _sendError;
  final List<_Optimistic> _optimistic = [];

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Optimistic: il messaggio "parte" subito (orologino), input libero.
    _controller.clear();
    final opt = _Optimistic(text);
    setState(() {
      _optimistic.add(opt);
      _sendError = null;
    });
    _scrollToBottomSoon();

    final result = await ChatService.sendMessage(otherUserId: widget.user.id, text: text);
    if (!mounted) return;

    if (result.ok) {
      // il messaggio reale arriva dallo stream con la spunta → ripulisci l'ottimistico
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _optimistic.remove(opt));
      });
    } else {
      setState(() {
        _optimistic.remove(opt);
        _sendError = _messageForSendError(result.error);
        _controller.text = text; // ripristina per ritentare
      });
    }
  }

  void _scrollToBottomSoon() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chips = [
      ...widget.user.favoriteGames.take(1),
      ...widget.user.platforms.take(1),
      ...widget.user.lookingFor.take(1),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E0718), Color(0xFF12091F), Color(0xFF1A102B)],
            stops: [0, .45, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(top: -90, right: -40, child: _AmbientOrb(size: 220, color: Color(0x22FA61A6))),
            const Positioned(top: 120, left: -70, child: _AmbientOrb(size: 180, color: Color(0x16A4A8F3))),
            const Positioned(bottom: 70, right: -60, child: _AmbientOrb(size: 200, color: Color(0x126DD7D7))),
            SafeArea(
              child: Column(
                children: [
                  _ChatHeader(user: widget.user, onDiscord: _showDiscordDialog, onRiot: _showRiotDialog),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...chips.map((c) => _InfoChip(label: c)),
                          _SignalChip(label: 'Online now'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: ChatService.messagesStream(otherUserId: widget.user.id),
                      builder: (context, snapshot) {
                        final messages = snapshot.data ?? const [];
                        if (snapshot.connectionState == ConnectionState.waiting &&
                            messages.isEmpty &&
                            _optimistic.isEmpty) {
                          return const Center(child: CircularProgressIndicator(color: WevoColors.pink));
                        }
                        // Ottimistici non ancora confermati nello stream (dedup per testo).
                        final myTexts = messages
                            .where((m) => m['senderId'] == ChatService.currentUid)
                            .map((m) => (m['text'] ?? '') as String)
                            .toSet();
                        final shownOpt = _optimistic.where((o) => !myTexts.contains(o.text)).toList();

                        if (messages.isEmpty && shownOpt.isEmpty) {
                          return _ChatEmptyState(name: widget.user.name);
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 22),
                          itemCount: messages.length + shownOpt.length,
                          itemBuilder: (context, index) {
                            // Coda: messaggi ottimistici (orologino).
                            if (index >= messages.length) {
                              final o = shownOpt[index - messages.length];
                              return _MessageBubble(
                                text: o.text,
                                time: _formatTime(o.createdAt),
                                isMe: true,
                                isAutomated: false,
                                status: _MsgStatus.pending,
                              );
                            }
                            final msg = messages[index];
                            final isMe = msg['senderId'] == ChatService.currentUid;
                            final createdAt = msg['createdAt'];
                            final time = createdAt is Timestamp ? _formatTime(createdAt.toDate()) : 'Ora';
                            final prev = index > 0 ? messages[index - 1] : null;
                            final showDayLabel = _shouldShowDayLabel(prev?['createdAt'], createdAt);
                            final dayLabel = createdAt is Timestamp ? _formatDayLabel(createdAt.toDate()) : null;

                            return Column(
                              children: [
                                if (showDayLabel && dayLabel != null) _TimeDivider(label: dayLabel),
                                _MessageBubble(
                                  text: (msg['text'] ?? '') as String,
                                  time: time,
                                  isMe: isMe,
                                  isAutomated: msg['automated'] == true,
                                  status: _MsgStatus.sent,
                                ),
                              ],
                            );
                          },
                        );
                      },
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
                  _buildInputBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x66FFFFFF), Color(0x22FFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 14)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(right: 10, bottom: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: const Icon(Icons.add, color: WevoColors.textMuted, size: 18),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.35),
                    decoration: const InputDecoration(
                      hintText: 'Scrivi qualcosa di bello...',
                      hintStyle: TextStyle(color: WevoColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Opacity(
                    opacity: 1,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFA61A6), Color(0xFFA4A8F3), Color(0xFF6DD7D7)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [wevoGlow(WevoColors.pink, blur: 22)],
                      ),
                      child: const Icon(Icons.north_rounded, color: Colors.white, size: 20),
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

  void _showDiscordDialog() {
    showDialog(
      context: context,
      builder: (_) => _InfoDialog(
        title: 'Aggiungi su Discord',
        icon: Icons.games,
        iconColor: WevoColors.lightBlue,
        content: 'Tag Discord di ${widget.user.name}:\n\n${widget.user.discordTag}',
      ),
    );
  }

  void _showRiotDialog() {
    showDialog(
      context: context,
      builder: (_) => _InfoDialog(
        title: 'Riot ID',
        icon: Icons.sports_esports,
        iconColor: WevoColors.pink,
        content: 'Riot ID di ${widget.user.name}:\n\n${widget.user.riotId}',
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _formatDayLabel(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Oggi';
  if (diff == 1) return 'Ieri';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
}

bool _shouldShowDayLabel(dynamic previous, dynamic current) {
  if (current is! Timestamp) return false;
  if (previous is! Timestamp) return true;
  final a = previous.toDate();
  final b = current.toDate();
  return a.year != b.year || a.month != b.month || a.day != b.day;
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

class _ChatHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback onDiscord;
  final VoidCallback onRiot;

  const _ChatHeader({required this.user, required this.onDiscord, required this.onRiot});

  @override
  Widget build(BuildContext context) {
    final subtitle = user.favoriteGames.isNotEmpty ? user.favoriteGames.first : 'Qui e ora';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x33FFFFFF), Color(0x12FFFFFF)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, 16)),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                ),
                _GlowAvatar(url: user.imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          const _PresenceDot(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('@${user.username}', style: const TextStyle(color: WevoColors.pink, fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'Attivo ora • $subtitle',
                        style: const TextStyle(color: WevoColors.textMuted, fontSize: 12, height: 1.2),
                      ),
                    ],
                  ),
                ),
                if (user.discordTag != null)
                  _HeaderIconButton(icon: Icons.games, color: WevoColors.lightBlue, onTap: onDiscord),
                if (user.riotId != null)
                  _HeaderIconButton(icon: Icons.sports_esports, color: WevoColors.pink, onTap: onRiot),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PresenceDot extends StatelessWidget {
  const _PresenceDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF9EDFA6),
        boxShadow: [BoxShadow(color: Color(0x889EDFA6), blurRadius: 10, spreadRadius: 1)],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [wevoGlow(color, blur: 16)],
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _GlowAvatar extends StatelessWidget {
  final String url;
  const _GlowAvatar({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [WevoColors.pink, WevoColors.periwinkle, WevoColors.teal]),
        boxShadow: [wevoGlow(WevoColors.pink, blur: 20)],
      ),
      child: CircleAvatar(radius: 25, backgroundImage: NetworkImage(url)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _SignalChip extends StatelessWidget {
  final String label;
  const _SignalChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0x22FA61A6), Color(0x126DD7D7)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PresenceDot(),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  final String name;
  const _ChatEmptyState({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x22FA61A6), Color(0x12FFFFFF)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 26, offset: const Offset(0, 16))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [WevoColors.pink, WevoColors.periwinkle]),
                boxShadow: [wevoGlow(WevoColors.pink, blur: 18)],
              ),
              child: const Icon(Icons.forum_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              'Apri bene la conversazione con $name',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Niente placeholder mosci. Qui parte una chat vera, con un primo messaggio che conta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: WevoColors.textMuted, fontSize: 14, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeDivider extends StatelessWidget {
  final String label;
  const _TimeDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.06), thickness: 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Text(label, style: const TextStyle(color: WevoColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.06), thickness: 1)),
        ],
      ),
    );
  }
}

class _InfoDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String content;
  const _InfoDialog({required this.title, required this.icon, required this.iconColor, required this.content});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: WevoColors.darkSoft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white)),
        ],
      ),
      content: Text(content, style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi')),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final bool isAutomated;
  final _MsgStatus status;

  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.isAutomated,
    this.status = _MsgStatus.sent,
  });

  Widget _statusIcon() {
    switch (status) {
      case _MsgStatus.pending:
        return Icon(Icons.access_time_rounded, size: 12, color: Colors.white.withValues(alpha: 0.7));
      case _MsgStatus.sent:
        return Icon(Icons.done_rounded, size: 13, color: Colors.white.withValues(alpha: 0.78));
      case _MsgStatus.delivered:
        return Icon(Icons.done_all_rounded, size: 13, color: Colors.white.withValues(alpha: 0.78));
      case _MsgStatus.read:
        return const Icon(Icons.done_all_rounded, size: 13, color: Color(0xFF6DD7D7));
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.74;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isAutomated)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x149EDFA6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x339EDFA6)),
                  ),
                  child: const Text('Auto reply', style: TextStyle(color: Color(0xFF9EDFA6), fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFA61A6), Color(0xFFA4A8F3), Color(0xFF6DD7D7)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF221638), Color(0xFF1B132D)],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isMe ? 22 : 8),
                  bottomRight: Radius.circular(isMe ? 8 : 22),
                ),
                border: Border.all(color: isMe ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.06)),
                boxShadow: [
                  if (isMe) wevoGlow(WevoColors.pink, blur: 18),
                  if (!isMe) BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 18, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(text, style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.38)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: isMe ? Colors.white.withValues(alpha: 0.72) : WevoColors.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        _statusIcon(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
