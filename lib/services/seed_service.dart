// SeedService — seeds demo data directly from the app.
// Uses the already-authenticated Firebase user to write Firestore data.
// Triggered by a button in ProfileScreen (or via dev toolbar).
//
// Creates:
//   - Firestore docs for 5 mock users (under m1-m5 IDs + real auth UID)
//   - Match documents linking current user to each mock user
//   - Chat messages with mock timestamps
//   - Current user's matches list populated

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeedService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;

  static Future<String> seedDemoData() async {
    final log = StringBuffer();

    log.writeln('🔥 SeedService: starting at ${DateTime.now()}');

    // ── Write current user's profile if missing fields ──
    final wevoRef = _db.collection('users').doc(_uid);
    await wevoRef.set({
      'name': 'Diego',
      'username': 'diegowe',
      'age': 25,
      'bio': 'Builder, designer, gamer. Cerco gente con vibe.',
      'photoUrl': 'https://picsum.photos/seed/wevodemo/200/200',
      'coverUrl': '',
      'interests': ['Tech', 'Design', 'Music', 'Gaming', 'Community'],
      'favoriteGames': ['Fortnite', 'Minecraft', 'Valorant'],
      'platforms': ['PC', 'PlayStation'],
      'lookingFor': ['Friendship', 'Community', 'Chill'],
      'country': 'Italia',
      'timezone': 'CET',
    }, SetOptions(merge: true));
    log.writeln('✅ Wevo profile updated');

    // ── Mock user data ──
    final mockData = [
      _MockUser(
        id: 'm1', name: 'Giulia', username: 'giuplays', age: 24,
        bio: 'FPS, co-op e sessioni chill la sera.',
        photoUrl: 'https://picsum.photos/seed/giulia24p/200/200',
        coverUrl: 'https://picsum.photos/seed/giulia24c/600/900',
        interests: ['FPS', 'Co-op', 'Anime'],
        favoriteGames: ['Valorant', 'Overwatch 2', 'Phasmophobia'],
        platforms: ['PC'],
        lookingFor: ['Duo', 'Friendship'],
        discordTag: 'giuplays', spotifyArtist: 'The Japanese House',
        messages: [
          ('Ti va una duo stasera?', false, 60),
          ('Sì, dopo le 21 ci sono', true, 58),
          ('Perfetto, ti aspetto!', false, 55),
        ],
      ),
      _MockUser(
        id: 'm2', name: 'Marco', username: 'marcojungler', age: 27,
        bio: 'Main jungle, ranked ma senza drama.',
        photoUrl: 'https://picsum.photos/seed/marco27p/200/200',
        coverUrl: 'https://picsum.photos/seed/marco27c/600/900',
        interests: ['MOBA', 'Competitive', 'Tech'],
        favoriteGames: ['League of Legends', 'TFT'],
        platforms: ['PC'],
        lookingFor: ['Ranked', 'Community'],
        discordTag: 'marcojungler', riotId: 'Marco#EUW', steamId: 'marco27',
        messages: [
          ('Ranked o chill?', false, 180),
          ('Una ranked e poi chill', true, 178),
          ("Let's go allora", false, 175),
        ],
      ),
      _MockUser(
        id: 'm3', name: 'Sofia', username: 'sofiacozy', age: 22,
        bio: 'Indie cozy, design e late night Discord.',
        photoUrl: 'https://picsum.photos/seed/sofia22p/200/200',
        coverUrl: 'https://picsum.photos/seed/sofia22c/600/900',
        interests: ['Cozy', 'Design', 'Community'],
        favoriteGames: ['Stardew Valley', 'It Takes Two'],
        platforms: ['PC', 'Switch'],
        lookingFor: ['Chill', 'Friendship'],
        discordTag: 'sofiacozy', spotifyArtist: 'Clairo',
        messages: [
          ('Hey! Hai mai giocato a Stardew?', false, 300),
          ('Mai provato, mi incuriosisce!', true, 298),
          ('È super rilassante', false, 295),
        ],
      ),
      _MockUser(
        id: 'm4', name: 'Alex', username: 'alexvibes', age: 25,
        bio: 'Cerco duo, match e gente con vibe pulita.',
        photoUrl: 'https://picsum.photos/seed/alex25p/200/200',
        coverUrl: 'https://picsum.photos/seed/alex25c/600/900',
        interests: ['Music', 'Gaming', 'Movies'],
        favoriteGames: ['Fortnite', 'Minecraft', 'Party Animals'],
        platforms: ['PC', 'PlayStation'],
        lookingFor: ['Friendship', 'Community'],
        discordTag: 'alexvibes',
        messages: [
          ('Stessa vibe, stesso caos 🔥', false, 400),
        ],
      ),
      _MockUser(
        id: 'm5', name: 'Noemi', username: 'n0eheart', age: 23,
        bio: "Late night chat, co-op e un po' di chaos.",
        photoUrl: 'https://picsum.photos/seed/noemi23p/200/200',
        coverUrl: 'https://picsum.photos/seed/noemi23c/600/900',
        interests: ['Chat', 'Co-op', 'Music'],
        favoriteGames: ['Overcooked', 'The Sims 4', 'Roblox'],
        platforms: ['PC', 'Mobile'],
        lookingFor: ['Chill', 'Duo'],
        discordTag: 'n0eheart', spotifyArtist: 'PinkPantheress',
        messages: [
          ('Facciamo un game e poi chat?', false, 250),
          ('Volentieri! Che giochi hai?', true, 248),
          ('Overcooked per iniziare?', false, 245),
        ],
      ),
    ];

    final now = DateTime.now();
    final allMockUids = <String>[];

    for (final user in mockData) {
      log.writeln('\n── ${user.name} ──');

      // Write Firestore doc under mock ID
      final fields = <String, dynamic>{
        'name': user.name,
        'username': user.username,
        'age': user.age,
        'bio': user.bio,
        'photoUrl': user.photoUrl,
        'coverUrl': user.coverUrl,
        'interests': user.interests,
        'favoriteGames': user.favoriteGames,
        'platforms': user.platforms,
        'lookingFor': user.lookingFor,
        if (user.discordTag != null) 'discordTag': user.discordTag,
        if (user.riotId != null) 'riotId': user.riotId,
        if (user.steamId != null) 'steamId': user.steamId,
        if (user.spotifyArtist != null) 'spotifyArtist': user.spotifyArtist,
        'country': 'Italia',
        'timezone': 'CET',
        'matches': <dynamic>[_uid],
      };

      // Use mock ID as doc ID (e.g. 'm1')
      await _db.collection('users').doc(user.id).set(fields, SetOptions(merge: true));
      log.writeln('  Firestore doc: ${user.id}');

      // Match document
      final sorted = [_uid, user.id]..sort();
      final matchId = '${sorted[0]}_${sorted[1]}';
      final createdAt = now.subtract(const Duration(hours: 1));

      await _db.collection('matches').doc(matchId).set({
        'users': <dynamic>[_uid, user.id],
        'createdAt': Timestamp.fromDate(createdAt),
        'lastMessage': null,
        'lastMessageAt': null,
        'lastSenderId': null,
      }, SetOptions(merge: true));
      log.writeln('  Match: $matchId');

      // Chat document (same ID as match)
      await _db.collection('chats').doc(matchId).set({
        'users': <dynamic>[_uid, user.id],
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      }, SetOptions(merge: true));
      log.writeln('  Chat doc created');

      // Messages
      for (int i = 0; i < user.messages.length; i++) {
        final (text, isMe, minsAgo) = user.messages[i];
        final ts = now.subtract(Duration(minutes: minsAgo));
        final msgRef = _db.collection('chats').doc(matchId).collection('messages').doc();

        await msgRef.set({
          'text': text,
          'senderId': isMe ? _uid : user.id,
          'createdAt': Timestamp.fromDate(ts),
        });

        // Update match last message
        if (i == user.messages.length - 1) {
          await _db.collection('matches').doc(matchId).update({
            'lastMessage': text,
            'lastMessageAt': Timestamp.fromDate(ts),
            'lastSenderId': isMe ? _uid : user.id,
          });
        }
      }
      log.writeln('  Messages: ${user.messages.length}');

      allMockUids.add(user.id);
    }

    // Update wevo user's matches field
    await wevoRef.set({
      'matches': allMockUids,
    }, SetOptions(merge: true));
    log.writeln('\n✅ Wevo matches updated: ${allMockUids.length} matches');

    log.writeln('\n🎉 Seeding complete!');
    return log.toString();
  }
}

class _MockUser {
  final String id, name, username;
  final int age;
  final String bio, photoUrl, coverUrl;
  final List<String> interests, favoriteGames, platforms, lookingFor;
  final String? discordTag, steamId, spotifyArtist, riotId;
  final List<(String, bool, int)> messages; // (text, isMe, minutesAgo)

  const _MockUser({
    required this.id, required this.name, required this.username, required this.age,
    required this.bio, required this.photoUrl, required this.coverUrl,
    required this.interests, this.favoriteGames = const [], this.platforms = const [],
    this.lookingFor = const [], this.discordTag, this.steamId, this.spotifyArtist,
    this.riotId, this.messages = const [],
  });
}
