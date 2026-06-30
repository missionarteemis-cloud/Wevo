import 'package:flutter/material.dart';

import '../services/presence_service.dart';
import '../theme.dart';

/// Pallino verde "online" per un utente, alimentato da [PresenceService].
/// Mostrato solo quando l'utente è online (altrimenti niente).
class OnlineDot extends StatelessWidget {
  final String uid;
  final double size;
  const OnlineDot({super.key, required this.uid, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: PresenceService.instance.onlineStream(uid),
      builder: (_, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: WevoColors.sage,
            border: Border.all(color: WevoColors.ink, width: 2),
            boxShadow: [
              BoxShadow(color: WevoColors.sage.withValues(alpha: 0.6), blurRadius: 6),
            ],
          ),
        );
      },
    );
  }
}
