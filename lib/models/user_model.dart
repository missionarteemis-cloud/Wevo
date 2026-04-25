class UserModel {
  final String id;
  final String name;
  final int age;
  final String bio;
  final String photoUrl;   // foto profilo (cerchio)
  final String coverUrl;   // immagine di copertina (banner)
  final List<String> interests;
  final String? discordTag;
  final bool hasNetflix;

  const UserModel({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.photoUrl,
    this.coverUrl = '',
    required this.interests,
    this.discordTag,
    this.hasNetflix = false,
  });

  // Compatibilità con il vecchio campo imageUrl usato nelle card discover
  String get imageUrl => coverUrl.isNotEmpty ? coverUrl : photoUrl;

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    final photo = (data['photoUrl'] as String?) ?? '';
    final cover = (data['coverUrl'] as String?) ?? '';
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      age: ((data['age'] as num?)?.toInt() ?? 0).clamp(0, 120),
      bio: data['bio'] ?? '',
      photoUrl: photo.isNotEmpty ? photo : 'https://picsum.photos/seed/${id}p/200/200',
      coverUrl: cover.isNotEmpty ? cover : 'https://picsum.photos/seed/${id}c/600/400',
      interests: List<String>.from(data['interests'] ?? []),
      discordTag: data['discordTag'] as String?,
      hasNetflix: data['hasNetflix'] ?? false,
    );
  }
}

// Profili mock (demo — usati come fallback se Firestore è vuoto)
final mockUsers = [
  UserModel(id: 'm1', name: 'Giulia', age: 24, bio: 'Appassionata di fotografia e viaggi.', photoUrl: 'https://picsum.photos/seed/giulia24p/200/200', coverUrl: 'https://picsum.photos/seed/giulia24c/600/900', interests: ['Fotografia', 'Viaggi', 'Cucina', 'Yoga'], hasNetflix: true),
  UserModel(id: 'm2', name: 'Marco', age: 27, bio: 'Gamer nel tempo libero, sviluppatore di giorno.', photoUrl: 'https://picsum.photos/seed/marco27p/200/200', coverUrl: 'https://picsum.photos/seed/marco27c/600/900', interests: ['Gaming', 'Tecnologia', 'Anime', 'Musica'], discordTag: 'marco#1234', hasNetflix: true),
  UserModel(id: 'm3', name: 'Sofia', age: 22, bio: 'Studentessa di architettura. Amo l\'arte e il design.', photoUrl: 'https://picsum.photos/seed/sofia22p/200/200', coverUrl: 'https://picsum.photos/seed/sofia22c/600/900', interests: ['Arte', 'Design', 'Cinema', 'Lettura']),
  UserModel(id: 'm4', name: 'Luca', age: 29, bio: 'Chef amatoriale e appassionato di sport.', photoUrl: 'https://picsum.photos/seed/luca29p/200/200', coverUrl: 'https://picsum.photos/seed/luca29c/600/900', interests: ['Cucina', 'Calcio', 'Running', 'Viaggi'], discordTag: 'luca_chef#5678', hasNetflix: true),
  UserModel(id: 'm5', name: 'Elena', age: 25, bio: 'Musicista e insegnante.', photoUrl: 'https://picsum.photos/seed/elena25p/200/200', coverUrl: 'https://picsum.photos/seed/elena25c/600/900', interests: ['Musica', 'Yoga', 'Lettura']),
  UserModel(id: 'm6', name: 'Alessio', age: 26, bio: 'Appassionato di arrampicata e outdoor.', photoUrl: 'https://picsum.photos/seed/alessi26p/200/200', coverUrl: 'https://picsum.photos/seed/alessi26c/600/900', interests: ['Arrampicata', 'Natura', 'Running', 'Fotografia'], hasNetflix: true),
  UserModel(id: 'm7', name: 'Chiara', age: 23, bio: 'Illustratrice freelance.', photoUrl: 'https://picsum.photos/seed/chiara23p/200/200', coverUrl: 'https://picsum.photos/seed/chiara23c/600/900', interests: ['Arte', 'Podcast', 'Design', 'Anime'], discordTag: 'chiara_art#9012'),
  UserModel(id: 'm8', name: 'Matteo', age: 28, bio: 'Appassionato di astronomia e sci-fi.', photoUrl: 'https://picsum.photos/seed/matteo28p/200/200', coverUrl: 'https://picsum.photos/seed/matteo28c/600/900', interests: ['Astronomia', 'Lettura', 'Cinema', 'Tecnologia'], hasNetflix: true),
  UserModel(id: 'm9', name: 'Valentina', age: 21, bio: 'Ballerina classica.', photoUrl: 'https://picsum.photos/seed/vale21p/200/200', coverUrl: 'https://picsum.photos/seed/vale21c/600/900', interests: ['Danza', 'Musica', 'Viaggi', 'Moda']),
  UserModel(id: 'm10', name: 'Riccardo', age: 30, bio: 'Avvocato di giorno, DJ di notte.', photoUrl: 'https://picsum.photos/seed/ricca30p/200/200', coverUrl: 'https://picsum.photos/seed/ricca30c/600/900', interests: ['Musica', 'Viaggi', 'Sport', 'Gaming'], discordTag: 'rico_dj#3344', hasNetflix: true),
];

// Match di esempio
final mockMatches = [mockUsers[0], mockUsers[1], mockUsers[3]];

// Messaggi di esempio
final mockMessages = {
  'm1': [
    {'sender': 'them', 'text': 'Ciao! Ho visto che ami i viaggi 🌍', 'time': '10:30'},
    {'sender': 'me', 'text': 'Sì! Ultima meta: Portogallo. Tu?', 'time': '10:32'},
    {'sender': 'them', 'text': 'Anche io! Lisbona è fantastica 😍', 'time': '10:33'},
  ],
  'm2': [
    {'sender': 'them', 'text': 'Giochi anche a RPG?', 'time': 'Ieri'},
    {'sender': 'me', 'text': 'Certo! Principalmente su PC', 'time': 'Ieri'},
  ],
  'm4': [
    {'sender': 'them', 'text': 'Hai provato la ricetta che ti ho mandato?', 'time': 'Lun'},
  ],
};
