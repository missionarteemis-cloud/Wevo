class UserModel {
  final String id;
  final String name;
  final String username;
  final int age;
  final String bio;
  final String photoUrl;
  final String coverUrl;
  final List<String> interests;
  final List<String> favoriteGames;
  final List<String> platforms;
  final List<String> lookingFor;
  final String? discordTag;
  final String? steamId;
  final String? spotifyArtist;
  final String? riotId;
  final String timezone;
  final String country;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.age,
    required this.bio,
    required this.photoUrl,
    this.coverUrl = '',
    required this.interests,
    this.favoriteGames = const [],
    this.platforms = const [],
    this.lookingFor = const [],
    this.discordTag,
    this.steamId,
    this.spotifyArtist,
    this.riotId,
    this.timezone = '',
    this.country = '',
  });

  String get imageUrl => coverUrl.isNotEmpty ? coverUrl : photoUrl;

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    final photo = (data['photoUrl'] as String?) ?? '';
    final cover = (data['coverUrl'] as String?) ?? '';
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      username: data['username'] ?? data['name'] ?? '',
      age: ((data['age'] as num?)?.toInt() ?? 0).clamp(0, 120),
      bio: data['bio'] ?? '',
      photoUrl: photo.isNotEmpty ? photo : 'https://picsum.photos/seed/${id}p/200/200',
      coverUrl: cover.isNotEmpty ? cover : 'https://picsum.photos/seed/${id}c/600/400',
      interests: List<String>.from(data['interests'] ?? []),
      favoriteGames: List<String>.from(data['favoriteGames'] ?? []),
      platforms: List<String>.from(data['platforms'] ?? []),
      lookingFor: List<String>.from(data['lookingFor'] ?? []),
      discordTag: data['discordTag'] as String?,
      steamId: data['steamId'] as String?,
      spotifyArtist: data['spotifyArtist'] as String?,
      riotId: data['riotId'] as String?,
      timezone: data['timezone'] ?? '',
      country: data['country'] ?? '',
    );
  }
}

final mockUsers = [
  UserModel(
    id: 'm1',
    name: 'Giulia',
    username: 'giuplays',
    age: 24,
    bio: 'FPS, co-op e sessioni chill la sera.',
    photoUrl: 'https://picsum.photos/seed/giulia24p/200/200',
    coverUrl: 'https://picsum.photos/seed/giulia24c/600/900',
    interests: ['FPS', 'Co-op', 'Anime'],
    favoriteGames: ['Valorant', 'Overwatch 2', 'Phasmophobia'],
    platforms: ['PC'],
    lookingFor: ['Duo', 'Friendship'],
    discordTag: 'giuplays',
    spotifyArtist: 'The Japanese House',
    country: 'Italia',
    timezone: 'CET',
  ),
  UserModel(
    id: 'm2',
    name: 'Marco',
    username: 'marcojungler',
    age: 27,
    bio: 'Main jungle, ranked ma senza drama.',
    photoUrl: 'https://picsum.photos/seed/marco27p/200/200',
    coverUrl: 'https://picsum.photos/seed/marco27c/600/900',
    interests: ['MOBA', 'Competitive', 'Tech'],
    favoriteGames: ['League of Legends', 'TFT'],
    platforms: ['PC'],
    lookingFor: ['Ranked', 'Community'],
    discordTag: 'marcojungler',
    riotId: 'Marco#EUW',
    steamId: 'marco27',
    country: 'Italia',
    timezone: 'CET',
  ),
  UserModel(
    id: 'm3',
    name: 'Sofia',
    username: 'sofiacozy',
    age: 22,
    bio: 'Indie cozy, design e late night Discord.',
    photoUrl: 'https://picsum.photos/seed/sofia22p/200/200',
    coverUrl: 'https://picsum.photos/seed/sofia22c/600/900',
    interests: ['Cozy', 'Design', 'Community'],
    favoriteGames: ['Stardew Valley', 'It Takes Two'],
    platforms: ['PC', 'Switch'],
    lookingFor: ['Chill', 'Friendship'],
    discordTag: 'sofiacozy',
    spotifyArtist: 'Clairo',
    country: 'Italia',
    timezone: 'CET',
  ),
  UserModel(
    id: 'm4',
    name: 'Alex',
    username: 'alexvibes',
    age: 25,
    bio: 'Cerco duo, match e gente con vibe pulita.',
    photoUrl: 'https://picsum.photos/seed/alex25p/200/200',
    coverUrl: 'https://picsum.photos/seed/alex25c/600/900',
    interests: ['Music', 'Gaming', 'Movies'],
    favoriteGames: ['Fortnite', 'Minecraft', 'Party Animals'],
    platforms: ['PC', 'PlayStation'],
    lookingFor: ['Friendship', 'Community'],
    discordTag: 'alexvibes',
    country: 'Italia',
    timezone: 'CET',
  ),
  UserModel(
    id: 'm5',
    name: 'Noemi',
    username: 'n0eheart',
    age: 23,
    bio: 'Late night chat, co-op e un po’ di chaos.',
    photoUrl: 'https://picsum.photos/seed/noemi23p/200/200',
    coverUrl: 'https://picsum.photos/seed/noemi23c/600/900',
    interests: ['Chat', 'Co-op', 'Music'],
    favoriteGames: ['Overcooked', 'The Sims 4', 'Roblox'],
    platforms: ['PC', 'Mobile'],
    lookingFor: ['Chill', 'Duo'],
    discordTag: 'n0eheart',
    spotifyArtist: 'PinkPantheress',
    country: 'Italia',
    timezone: 'CET',
  ),
  UserModel(
    id: 'm6',
    name: 'Luca',
    username: 'padmaster',
    age: 26,
    bio: 'Controller god, arcade lover, zero tilt.',
    photoUrl: 'https://picsum.photos/seed/luca26p/200/200',
    coverUrl: 'https://picsum.photos/seed/luca26c/600/900',
    interests: ['Arcade', 'Fighting', 'Retro'],
    favoriteGames: ['Rocket League', 'Tekken 8', 'EA FC'],
    platforms: ['PlayStation', 'PC'],
    lookingFor: ['Ranked', 'Duo'],
    discordTag: 'padmaster',
    riotId: 'Pad#777',
    country: 'Italia',
    timezone: 'CET',
  ),
];

final mockMatches = [mockUsers[0], mockUsers[1], mockUsers[3], mockUsers[4]];

final mockMessages = {
  'm1': [
    {'sender': 'them', 'text': 'Ti va una duo stasera?', 'time': '10:30'},
    {'sender': 'me', 'text': 'Sì, dopo le 21 ci sono', 'time': '10:32'},
  ],
  'm2': [
    {'sender': 'them', 'text': 'Ranked o chill?', 'time': 'Ieri'},
    {'sender': 'me', 'text': 'Una ranked e poi chill', 'time': 'Ieri'},
  ],
  'm4': [
    {'sender': 'them', 'text': 'Stessa vibe, stesso caos', 'time': '18:20'},
  ],
  'm5': [
    {'sender': 'them', 'text': 'Facciamo un game e poi chat?', 'time': '17:02'},
  ],
};
