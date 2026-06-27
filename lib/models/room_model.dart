class RoomTheme {
  final String floor;
  final String wallpaper;

  const RoomTheme({
    required this.floor,
    required this.wallpaper,
  });

  factory RoomTheme.fromMap(Map<String, dynamic>? data) {
    return RoomTheme(
      floor: data?['floor'] as String? ?? 'neon-grid',
      wallpaper: data?['wallpaper'] as String? ?? 'violet-lounge',
    );
  }

  Map<String, dynamic> toMap() => {
        'floor': floor,
        'wallpaper': wallpaper,
      };
}

class RoomFurnitureItem {
  final String instanceId;
  final String itemId;
  final int x;
  final int y;
  final int rot;

  const RoomFurnitureItem({
    required this.instanceId,
    required this.itemId,
    required this.x,
    required this.y,
    required this.rot,
  });

  factory RoomFurnitureItem.fromMap(Map<String, dynamic> data) {
    return RoomFurnitureItem(
      instanceId: data['instanceId'] as String? ?? '',
      itemId: data['itemId'] as String? ?? '',
      x: (data['x'] as num? ?? 0).toInt(),
      y: (data['y'] as num? ?? 0).toInt(),
      rot: (data['rot'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'instanceId': instanceId,
        'itemId': itemId,
        'x': x,
        'y': y,
        'rot': rot,
      };

  RoomFurnitureItem copyWith({
    String? instanceId,
    String? itemId,
    int? x,
    int? y,
    int? rot,
  }) {
    return RoomFurnitureItem(
      instanceId: instanceId ?? this.instanceId,
      itemId: itemId ?? this.itemId,
      x: x ?? this.x,
      y: y ?? this.y,
      rot: rot ?? this.rot,
    );
  }
}

class RoomModel {
  final String ownerUid;
  final String name;
  final RoomTheme theme;
  final List<RoomFurnitureItem> furniture;

  const RoomModel({
    required this.ownerUid,
    required this.name,
    required this.theme,
    required this.furniture,
  });

  factory RoomModel.fromMap(Map<String, dynamic> data, String ownerUid) {
    return RoomModel(
      ownerUid: data['ownerUid'] as String? ?? ownerUid,
      name: data['name'] as String? ?? 'My Room',
      theme: RoomTheme.fromMap(data['theme'] as Map<String, dynamic>?),
      furniture: ((data['furniture'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => RoomFurnitureItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        'name': name,
        'theme': theme.toMap(),
        'furniture': furniture.map((item) => item.toMap()).toList(),
      };

  RoomModel copyWith({
    String? ownerUid,
    String? name,
    RoomTheme? theme,
    List<RoomFurnitureItem>? furniture,
  }) {
    return RoomModel(
      ownerUid: ownerUid ?? this.ownerUid,
      name: name ?? this.name,
      theme: theme ?? this.theme,
      furniture: furniture ?? this.furniture,
    );
  }
}
