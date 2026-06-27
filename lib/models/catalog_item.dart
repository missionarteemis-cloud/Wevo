/// Articolo dello store, da `catalog/{itemId}` (vedi docs/game-layer.md §18).
class CatalogItem {
  final String id;
  final String name;
  final String description;
  final String type; // arredi | crediti | vestiti | evento
  final int price;

  const CatalogItem({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.price,
  });

  factory CatalogItem.fromDoc(String id, Map<String, dynamic> d) {
    return CatalogItem(
      id: id,
      name: d['name'] as String? ?? id,
      description: d['description'] as String? ?? '',
      type: d['type'] as String? ?? 'arredi',
      price: (d['price'] as num? ?? 0).toInt(),
    );
  }
}

/// Tipi (tab) dello store, in ordine di visualizzazione.
const storeTypes = <({String id, String label})>[
  (id: 'arredi', label: 'Arredi'),
  (id: 'crediti', label: 'Crediti'),
  (id: 'vestiti', label: 'Vestiti'),
  (id: 'evento', label: 'Evento'),
];
