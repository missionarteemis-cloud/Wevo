import 'package:flutter/material.dart';

import '../screens/room_screen.dart';
import '../services/presence_service.dart';
import '../theme.dart';

/// "Entra nella stanza" di un utente — visibile solo se l'utente è online.
/// Mostra la casetta + (se è davvero nella sua stanza) il pallino "in room".
class EnterRoomButton extends StatelessWidget {
  final String uid;
  final String name;
  const EnterRoomButton({super.key, required this.uid, required this.name});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: PresenceService.instance.onlineStream(uid),
      builder: (_, onlineSnap) {
        if (onlineSnap.data != true) return const SizedBox.shrink();
        return StreamBuilder<bool>(
          stream: PresenceService.instance.inOwnRoomStream(uid),
          builder: (_, roomSnap) {
            final inRoom = roomSnap.data == true;
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RoomScreen(ownerUid: uid, ownerName: name),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: WevoColors.teal.withValues(alpha: 0.14),
                  border: Border.all(color: WevoColors.teal.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_rounded, color: WevoColors.teal, size: 15),
                    if (inRoom) ...[
                      const SizedBox(width: 5),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: WevoColors.sage),
                      ),
                      const SizedBox(width: 4),
                      const Text('in room',
                          style: TextStyle(color: WevoColors.sage, fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
