import 'package:flutter/material.dart';

import '../game/furniture_catalog.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';
import '../theme.dart';

/// Finestra inventario draggabile: oggetti posseduti, tocca per piazzare.
class InventoryWindow extends StatelessWidget {
  final void Function(Offset delta) onDrag;
  final VoidCallback onClose;
  final void Function(InventoryItem item) onPlaceItem;

  const InventoryWindow({
    super.key,
    required this.onDrag,
    required this.onClose,
    required this.onPlaceItem,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: WevoColors.surface.withOpacity(0.98),
          border: Border.all(color: WevoColors.teal.withOpacity(0.4)),
          boxShadow: [wevoGlow(WevoColors.teal, blur: 30)],
        ),
        child: Column(
          children: [
            GestureDetector(
              onPanUpdate: (d) => onDrag(d.delta),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                decoration: const BoxDecoration(
                  color: WevoColors.surfaceHi,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2, color: WevoColors.teal, size: 19),
                    const SizedBox(width: 8),
                    const Text(
                      'Inventario',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onClose,
                      child: const Icon(Icons.close, color: Colors.white54, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _grid(context)),
          ],
        ),
      ),
    );
  }

  Widget _grid(BuildContext context) {
    return StreamBuilder<List<InventoryItem>>(
      stream: InventoryService.stream(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: WevoColors.teal, strokeWidth: 2),
          );
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Inventario vuoto.\nCompra qualcosa dallo store!',
                textAlign: TextAlign.center,
                style: TextStyle(color: WevoColors.textMuted, height: 1.5),
              ),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _InvCard(
            item: items[i],
            onTap: () => onPlaceItem(items[i]),
          ),
        );
      },
    );
  }
}

class _InvCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;
  const _InvCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final def = furnitureDef(item.itemId);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: WevoColors.surfaceHi,
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: def.color.withOpacity(0.35),
              ),
              child: const Icon(Icons.chair_alt, color: Colors.white70, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              def.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: Colors.white70, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
