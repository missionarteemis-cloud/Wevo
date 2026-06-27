/// Oggetto posseduto non piazzato, da `users/{uid}/inventory/{instanceId}`.
class InventoryItem {
  final String instanceId;
  final String itemId;

  const InventoryItem({required this.instanceId, required this.itemId});

  factory InventoryItem.fromDoc(String id, Map<String, dynamic> d) {
    return InventoryItem(
      instanceId: id,
      itemId: d['itemId'] as String? ?? '',
    );
  }
}
