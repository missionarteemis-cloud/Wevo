import 'package:flutter/material.dart';
import '../models/user_model.dart';
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
  late List<Map<String, String>> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List.from(mockMessages[widget.user.id] ?? []);
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'sender': 'me', 'text': text, 'time': 'Ora'});
    });
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.user.imageUrl),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.user.name, style: const TextStyle(fontSize: 16)),
                const Text('Online', style: TextStyle(fontSize: 11, color: WevoColors.sage)),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.user.discordTag != null)
            IconButton(
              icon: const Icon(Icons.games, color: WevoColors.lightBlue),
              tooltip: 'Discord: ${widget.user.discordTag}',
              onPressed: () => _showDiscordDialog(),
            ),
          if (widget.user.hasNetflix)
            IconButton(
              icon: const Icon(Icons.tv, color: WevoColors.coral),
              tooltip: 'Guarda insieme su Netflix',
              onPressed: () => _showNetflixDialog(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Di\' ciao a ${widget.user.name}! 👋',
                      style: const TextStyle(color: Colors.black38, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender'] == 'me';
                      return _MessageBubble(
                        text: msg['text']!,
                        time: msg['time']!,
                        isMe: isMe,
                      );
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Scrivi un messaggio...',
                hintStyle: const TextStyle(color: Colors.black38),
                filled: true,
                fillColor: WevoColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: WevoColors.pink,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showDiscordDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.games, color: WevoColors.lightBlue),
            SizedBox(width: 8),
            Text('Aggiungi su Discord'),
          ],
        ),
        content: Text('Tag Discord di ${widget.user.name}:\n\n${widget.user.discordTag}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: WevoColors.lightBlue),
            onPressed: () => Navigator.pop(context),
            child: const Text('Copia tag', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNetflixDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.tv, color: WevoColors.coral),
            SizedBox(width: 8),
            Text('Guarda insieme'),
          ],
        ),
        content: Text(
          '${widget.user.name} ha Netflix!\nPuoi avviare una sessione di visione condivisa.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dopo')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: WevoColors.coral),
            onPressed: () => Navigator.pop(context),
            child: const Text('Avvia sessione', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? WevoColors.pink : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14)),
            const SizedBox(height: 2),
            Text(time, style: TextStyle(color: isMe ? Colors.white54 : Colors.black38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
