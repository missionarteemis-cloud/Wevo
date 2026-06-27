// Run with: dart run bin/seed.dart
// Requires: flutter pub get first
//
// Seeds demo data into Firebase project wevo-22275:
//  - Creates wevo demo account (wevodemo@wevo.demo / wevodemo)
//  - Creates 5 mock user accounts (giulia, marco, sofia, alex, noemi @ wevo.demo)
//  - Creates Firestore documents, matches, and chat messages
//  - Password for all: demo123

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wevo/firebase_options.dart';

// ─────────────────────────────────────────────
// Mock user data
// ─────────────────────────────────────────────
final _mockUsers = <UserSeed>[
  UserSeed(
    id: 'm1',
    email: 'giulia@wevo.demo',
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
    messages: [
      Msg('Ti va una duo stasera?', minutesAgo: 60),
      Msg('Sì, dopo le 21 ci sono', minutesAgo: 58, isMe: true),
      Msg('Perfetto, ti aspetto!', minutesAgo: 55),
    ],
  ),
  UserSeed(
    id: 'm2',
    email: 'marco@wevo.demo',
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
    messages: [
      Msg('Ranked o chill?', minutesAgo: 180),
      Msg('Una ranked e poi chill', minutesAgo: 178, isMe: true),
      Msg("Let's go allora", minutesAgo: 175),
    ],
  ),
  UserSeed(
    id: 'm3',
    email: 'sofia@wevo.demo',
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
    messages: [
      Msg('Hey! Hai mai giocato a Stardew?', minutesAgo: 300),
      Msg('Mai provato, mi incuriosisce!', minutesAgo: 298, isMe: true),
      Msg('Te lo mostro volentieri, è super rilassante', minutesAgo: 295),
    ],
  ),
  UserSeed(
    id: 'm4',
    email: 'alex@wevo.demo',
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
    messages: [
      Msg('Stessa vibe, stesso caos 🔥', minutesAgo: 400),
    ],
  ),
  UserSeed(
    id: 'm5',
    email: 'noemi@wevo.demo',
    name: 'Noemi',
    username: 'n0eheart',
    age: 23,
    bio: "Late night chat, co-op e un po' di chaos.",
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
    messages: [
      Msg('Facciamo un game e poi chat?', minutesAgo: 250),
      Msg('Volentieri! Che giochi hai?', minutesAgo: 248, isMe: true),
      Msg('Overcooked per iniziare?', minutesAgo: 245),
    ],
  ),
];

const _wevo = WevoDemo(
  email: 'wevodemo@wevo.demo',
  password: 'wevodemo',
  name: 'Diego',
  username: 'diegowe',
  age: 25,
  bio: 'Builder, designer, gamer. Cerco gente con vibe.',
  interests: ['Tech', 'Design', 'Music', 'Gaming', 'Community'],
  games: ['Fortnite', 'Minecraft', 'Valorant'],
  platforms: ['PC', 'PlayStation'],
);

const _globalPassword = 'demo123';

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────
class Msg {
  final String text;
  final int minutesAgo;
  final bool isMe;
  const Msg(this.text, {this.minutesAgo = 0, this.isMe = false});
}

class UserSeed {
  final String id, email, name, username;
  final int age;
  final String bio, photoUrl, coverUrl;
  final List<String> interests, favoriteGames, platforms, lookingFor;
  final String? discordTag, steamId, spotifyArtist, riotId, country, timezone;
  final List<Msg> messages;

  const UserSeed({
    required this.id, required this.email, required this.name, required this.username,
    required this.age, required this.bio, required this.photoUrl, required this.coverUrl,
    required this.interests, this.favoriteGames = const [], this.platforms = const [],
    this.lookingFor = const [], this.discordTag, this.steamId, this.spotifyArtist,
    this.riotId, this.country = 'Italia', this.timezone = 'CET', this.messages = const [],
  });
}

class WevoDemo {
  final String email, password, name, username, bio;
  final int age;
  final List<String> interests, games, platforms;
  const WevoDemo({
    required this.email, required this.password, required this.name, required this.username,
    required this.age, required this.bio, required this.interests, required this.games,
    required this.platforms,
  });
}

// ─────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────
Future<void> main() async {
  print('🔥 Wevo Seed — starting...\n');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authInstance = auth.FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  // 1. Create / find wevo demo user
  final wevoCred = await _ensureUser(
    authInstance,
    email: _wevo.email,
    password: _wevo.password,
  );
  final wevoUid = wevoCred.user!.uid;
  print('✅ Wevo demo: $wevoUid (${_wevo.email})');

  // 2. Write / merge wevo demo Firestore doc
  await firestore.collection('users').doc(wevoUid).set({
    'name': _wevo.name,
    'username': _wevo.username,
    'age': _wevo.age,
    'bio': _wevo.bio,
    'photoUrl': 'https://picsum.photos/seed/wevodemo/200/200',
    'coverUrl': '',
    'interests': _wevo.interests,
    'favoriteGames': _wevo.games,
    'platforms': _wevo.platforms,
    'lookingFor': ['Friendship', 'Community', 'Chill'],
    'country': 'Italia',
    'timezone': 'CET',
    'matches': [],
  }, SetOptions(merge: true));
  print('✅ Wevo demo Firestore doc written\n');

  // 3. Process each mock user
  final allMockUids = <String>[];

  for (final user in _mockUsers) {
    print('── ${user.name} ──');

    // Auth
    final cred = await _ensureUser(
      authInstance,
      email: user.email,
      password: _globalPassword,
    );
    final actualUid = cred.user!.uid;
    allMockUids.add(actualUid);
    print('  Auth: ${user.name} ($actualUid)');

    // Firestore doc under mock id + real uid
    final docData = {
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
      if (user.steamId != null) 'steamId': user.steamId,
      if (user.riotId != null) 'riotId': user.riotId,
      if (user.spotifyArtist != null) 'spotifyArtist': user.spotifyArtist,
      'country': user.country,
      'timezone': user.timezone,
      'matches': [wevoUid],
    };

    await firestore.collection('users').doc(user.id).set(docData, SetOptions(merge: true));
    if (actualUid != user.id) {
      await firestore.collection('users').doc(actualUid).set(docData, SetOptions(merge: true));
    }
    print('  Firestore doc: ${user.id}' +
        (actualUid != user.id ? ' + $actualUid' : ''));

    // Match document
    final sorted = [wevoUid, actualUid]..sort();
    final matchId = '${sorted[0]}_${sorted[1]}';
    await firestore.collection('matches').doc(matchId).set({
      'users': [wevoUid, actualUid],
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
      'lastMessage': null,
      'lastMessageAt': null,
      'lastSenderId': null,
    }, SetOptions(merge: true));

    // Add to wevo's match list
    await firestore.collection('users').doc(wevoUid).set({
      'matches': FieldValue.arrayUnion([actualUid]),
    }, SetOptions(merge: true));
    print('  Match: wevo <-> ${user.name}');

    // Messages
    if (user.messages.isNotEmpty) {
      final chatSorted = [wevoUid, actualUid]..sort();
      final chatId = '${chatSorted[0]}_${chatSorted[1]}';
      final now = DateTime.now();

      for (int i = 0; i < user.messages.length; i++) {
        final msg = user.messages[i];
        final ts = now.subtract(Duration(minutes: msg.minutesAgo));
        final msgRef = firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc();

        await msgRef.set({
          'text': msg.text,
          'senderId': msg.isMe ? wevoUid : actualUid,
          'createdAt': Timestamp.fromDate(ts),
        });

        if (i == user.messages.length - 1) {
          // Last message → update match + chat meta
          await firestore.collection('chats').doc(chatId).set({
            'users': [wevoUid, actualUid],
            'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
          }, SetOptions(merge: true));

          await firestore.collection('matches').doc(matchId).update({
            'lastMessage': msg.text,
            'lastMessageAt': Timestamp.fromDate(ts),
            'lastSenderId': msg.isMe ? wevoUid : actualUid,
          });
        }
      }
      print('  Messages: ${user.messages.length} msg(s)');
    }

    print('');
  }

  print('🎉 Seeding complete!');
  print('');
  print('── Login credentials ──');
  print('Demo account:');
  print('  Email:    ${_wevo.email}');
  print('  Password: ${_wevo.password}');
  print('');
  print('Mock users (password: "$_globalPassword"):');
  for (final u in _mockUsers) {
    print('  ${u.email} — ${u.name}');
  }
}

Future<auth.UserCredential> _ensureUser(
  auth.FirebaseAuth authInstance, {
  required String email,
  required String password,
}) async {
  try {
    return await authInstance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  } on auth.FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
      return await authInstance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
    rethrow;
  }
}
