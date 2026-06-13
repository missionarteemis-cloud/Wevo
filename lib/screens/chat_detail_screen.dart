import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../theme.dart';

class ChatDetailScreen extends StatefulWidget {
  final UserModel user;
  const ChatDetailScreen({super.key, required this.user});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    ChatService.ensureChat(otherUserId: widget.user.id);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await ChatService.sendMessage(otherUserId: widget.user.id, text: text);
    _controller.clear();
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [WevoColors.bg, WevoColors.dark, WevoColors.darkSoft],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _ChatHeader(user: widget.user, onDiscord: _showDiscordDialog, onRiot: _showRiotDialog),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chips.map((c) => _InfoChip(label: c)).toList(),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: ChatService.messagesStream(otherUserId: widget.user.id),
                  builder: (context, snapshot) {
                    final messages = snapshot.data ?? const [];
                    if (snapshot.connectionState == ConnectionState.waiting && messages.isEmpty) {
                      return const Center(child: CircularProgressIndicator(color: WevoColors.pink));
                    }
                    if (messages.isEmpty) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: WevoColors.darkSoft,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Text(
                            'Di\' ciao a ${widget.user.name}.\nLa vostra chat inizia qui ✨',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['senderId'] == ChatService.currentUid;
                        final createdAt = msg['createdAt'];
                        final time = createdAt is Timestamp
                            ? _formatTime(createdAt.toDate())
                            : 'Ora';
                        return _MessageBubble(
                          text: (msg['text'] ?? '') as String,
                          time: time,
                          isMe: isMe,
                        );
                      },
                    );
                  },
                ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Scrivi un messaggio...',
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
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: WevoColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [wevoGlow(WevoColors.pink, blur: 18)],
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
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

class _ChatHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback onDiscord;
  final VoidCallback onRiot;

  const _ChatHeader({required this.user, required this.onDiscord, required this.onRiot});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: WevoColors.darkSoft,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [wevoGlow(WevoColors.pink, blur: 20)],
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
                  Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('@${user.username}', style: const TextStyle(color: WevoColors.pink, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    user.favoriteGames.isNotEmpty ? user.favoriteGames.first : 'Online',
                    style: const TextStyle(color: WevoColors.textMuted, fontSize: 12),
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
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          shape: BoxShape.circle,
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
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: WevoColors.pink, width: 2),
        boxShadow: [wevoGlow(WevoColors.pink, blur: 18)],
      ),
      child: CircleAvatar(radius: 24, backgroundImage: NetworkImage(url)),
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
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
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

  const _MessageBubble({required this.text, required this.time, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        decoration: BoxDecoration(
          gradient: isMe ? WevoColors.primaryGradient : null,
          color: isMe ? null : WevoColors.darkSoft,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 20),
          ),
          border: Border.all(color: isMe ? Colors.transparent : Colors.white.withOpacity(0.08)),
          boxShadow: [
            if (isMe) wevoGlow(WevoColors.pink, blur: 16),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35)),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMe ? Colors.white70 : WevoColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
