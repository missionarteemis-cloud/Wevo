import 'package:flutter/material.dart';

import '../models/catalog_item.dart';
import '../services/store_service.dart';
import '../theme.dart';

/// Finestra store draggabile (vedi docs/game-layer.md §18).
///
/// Mostra il catalogo per Tipo (tab) + saldo coins. Il bottone Compra si
/// aggancia alla Cloud Function `buyItem` appena è deployata (per ora avvisa).
class StoreWindow extends StatefulWidget {
  final void Function(Offset delta) onDrag;
  final VoidCallback onClose;
  const StoreWindow({super.key, required this.onDrag, required this.onClose});

  @override
  State<StoreWindow> createState() => _StoreWindowState();
}

class _StoreWindowState extends State<StoreWindow> {
  late final Future<List<CatalogItem>> _catalog;
  String _type = storeTypes.first.id;

  @override
  void initState() {
    super.initState();
    _catalog = StoreService.loadCatalog();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        height: 440,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: WevoColors.surface.withOpacity(0.98),
          border: Border.all(color: WevoColors.periwinkle.withOpacity(0.4)),
          boxShadow: [wevoGlow(WevoColors.periwinkle, blur: 30)],
        ),
        child: Column(
          children: [
            _header(),
            _tabs(),
            const Divider(height: 1, color: Colors.white12),
            Expanded(child: _list()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return GestureDetector(
      onPanUpdate: (d) => widget.onDrag(d.delta),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        decoration: const BoxDecoration(
          gradient: WevoColors.brand,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            const Icon(Icons.storefront, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Store',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            _coins(),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onClose,
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coins() {
    return StreamBuilder<int>(
      stream: StoreService.coinsStream(),
      builder: (_, snap) {
        final coins = snap.data ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.black.withOpacity(0.25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: WevoColors.gold, size: 16),
              const SizedBox(width: 4),
              Text(
                '$coins',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tabs() {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        children: storeTypes.map((t) {
          final active = t.id == _type;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _type = t.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: active ? WevoColors.pink.withOpacity(0.16) : Colors.transparent,
                  border: Border.all(
                    color: active ? WevoColors.pink.withOpacity(0.5) : Colors.white12,
                  ),
                ),
                child: Text(
                  t.label,
                  style: TextStyle(
                    color: active ? WevoColors.pink : Colors.white60,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _list() {
    return FutureBuilder<List<CatalogItem>>(
      future: _catalog,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: WevoColors.pink, strokeWidth: 2),
          );
        }
        if (snap.hasError) {
          return const Center(
            child: Text('Errore caricamento store', style: TextStyle(color: WevoColors.coral)),
          );
        }
        final items = (snap.data ?? []).where((i) => i.type == _type).toList();
        if (items.isEmpty) {
          return Center(
            child: Text('Niente qui per ora', style: TextStyle(color: WevoColors.textMuted)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _StoreCard(item: items[i]),
        );
      },
    );
  }
}

class _StoreCard extends StatelessWidget {
  final CatalogItem item;
  const _StoreCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: WevoColors.surfaceHi,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Anteprima placeholder (lo sprite arriva col manifest pixel-art)
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [WevoColors.periwinkle.withOpacity(0.5), WevoColors.teal.withOpacity(0.4)],
              ),
            ),
            child: const Icon(Icons.chair_alt, color: Colors.white70, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, height: 1.3, color: WevoColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _BuyButton(item: item),
        ],
      ),
    );
  }
}

class _BuyButton extends StatefulWidget {
  final CatalogItem item;
  const _BuyButton({required this.item});

  @override
  State<_BuyButton> createState() => _BuyButtonState();
}

class _BuyButtonState extends State<_BuyButton> {
  bool _busy = false;

  Future<void> _buy() async {
    if (_busy) return;
    setState(() => _busy = true);
    String msg;
    try {
      final r = await StoreService.buyItem(widget.item.id);
      if (r.ok) {
        msg = '${widget.item.name} aggiunto all\'inventario';
      } else if (r.error == 'insufficient') {
        msg = 'Coins insufficienti';
      } else {
        msg = 'Acquisto non riuscito';
      }
    } catch (_) {
      msg = 'Errore durante l\'acquisto';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _busy ? null : _buy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: WevoColors.pink.withOpacity(0.15),
          border: Border.all(color: WevoColors.pink.withOpacity(0.4)),
        ),
        child: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: WevoColors.pink),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: WevoColors.gold, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.item.price}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
