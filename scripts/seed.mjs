import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('❌ Missing GOOGLE_APPLICATION_CREDENTIALS');
  process.exit(1);
}

initializeApp({ credential: applicationDefault() });

const auth = getAuth();
const db = getFirestore();

const demoAccount = {
  uid: 'demo',
  email: 'demo@wevo.app',
  password: 'wevo1234',
  displayName: 'Diego',
  name: 'Diego',
  username: 'wevo_demo',
  age: 25,
  bio: 'Builder, designer, gamer. Cerco gente con vibe.',
  photoUrl: 'https://picsum.photos/seed/wevodemo/200/200',
  coverUrl: '',
  interests: ['Tech', 'Design', 'Music', 'Gaming', 'Community'],
  favoriteGames: ['Fortnite', 'Minecraft', 'Valorant'],
  platforms: ['PC', 'PlayStation'],
  lookingFor: ['Friendship', 'Community', 'Chill'],
  country: 'Italia',
  timezone: 'CET',
};

const demoUsers = [
  {
    uid: 'm1',
    email: 'giulia@wevo.app', password: 'wevo1234', username: 'giuplays', name: 'Giulia', displayName: 'Giulia', age: 24,
    bio: 'FPS, co-op e sessioni chill la sera.', photoUrl: 'https://picsum.photos/seed/giulia24p/200/200',
    coverUrl: 'https://picsum.photos/seed/giulia24c/600/900', interests: ['FPS', 'Co-op', 'Anime'],
    favoriteGames: ['Valorant', 'Overwatch 2', 'Phasmophobia'], platforms: ['PC'], lookingFor: ['Duo', 'Friendship'],
    discordTag: 'giuplays', spotifyArtist: 'The Japanese House', country: 'Italia', timezone: 'CET',
    messages: [
      { id: 'm1-msg-1', text: 'Ti va una duo stasera?', minutesAgo: 60, sender: 'other' },
      { id: 'm1-msg-2', text: 'Sì, dopo le 21 ci sono', minutesAgo: 58, sender: 'demo' },
      { id: 'm1-msg-3', text: 'Perfetto, ti aspetto!', minutesAgo: 55, sender: 'other' },
    ],
  },
  {
    uid: 'm2',
    email: 'marco@wevo.app', password: 'wevo1234', username: 'marcojungler', name: 'Marco', displayName: 'Marco', age: 27,
    bio: 'Main jungle, ranked ma senza drama.', photoUrl: 'https://picsum.photos/seed/marco27p/200/200',
    coverUrl: 'https://picsum.photos/seed/marco27c/600/900', interests: ['MOBA', 'Competitive', 'Tech'],
    favoriteGames: ['League of Legends', 'TFT'], platforms: ['PC'], lookingFor: ['Ranked', 'Community'],
    discordTag: 'marcojungler', riotId: 'Marco#EUW', steamId: 'marco27', country: 'Italia', timezone: 'CET',
    messages: [
      { id: 'm2-msg-1', text: 'Ranked o chill?', minutesAgo: 180, sender: 'other' },
      { id: 'm2-msg-2', text: 'Una ranked e poi chill', minutesAgo: 178, sender: 'demo' },
      { id: 'm2-msg-3', text: "Let's go allora", minutesAgo: 175, sender: 'other' },
    ],
  },
  {
    uid: 'm3',
    email: 'sofia@wevo.app', password: 'wevo1234', username: 'sofiacozy', name: 'Sofia', displayName: 'Sofia', age: 22,
    bio: 'Indie cozy, design e late night Discord.', photoUrl: 'https://picsum.photos/seed/sofia22p/200/200',
    coverUrl: 'https://picsum.photos/seed/sofia22c/600/900', interests: ['Cozy', 'Design', 'Community'],
    favoriteGames: ['Stardew Valley', 'It Takes Two'], platforms: ['PC', 'Switch'], lookingFor: ['Chill', 'Friendship'],
    discordTag: 'sofiacozy', spotifyArtist: 'Clairo', country: 'Italia', timezone: 'CET',
    messages: [
      { id: 'm3-msg-1', text: 'Hey! Hai mai giocato a Stardew?', minutesAgo: 300, sender: 'other' },
      { id: 'm3-msg-2', text: 'Mai provato, mi incuriosisce!', minutesAgo: 298, sender: 'demo' },
      { id: 'm3-msg-3', text: 'Te lo mostro volentieri, è super rilassante', minutesAgo: 295, sender: 'other' },
    ],
  },
  {
    uid: 'm4',
    email: 'alex@wevo.app', password: 'wevo1234', username: 'alexvibes', name: 'Alex', displayName: 'Alex', age: 25,
    bio: 'Cerco duo, match e gente con vibe pulita.', photoUrl: 'https://picsum.photos/seed/alex25p/200/200',
    coverUrl: 'https://picsum.photos/seed/alex25c/600/900', interests: ['Music', 'Gaming', 'Movies'],
    favoriteGames: ['Fortnite', 'Minecraft', 'Party Animals'], platforms: ['PC', 'PlayStation'], lookingFor: ['Friendship', 'Community'],
    discordTag: 'alexvibes', country: 'Italia', timezone: 'CET',
    messages: [
      { id: 'm4-msg-1', text: 'Stessa vibe, stesso caos 🔥', minutesAgo: 400, sender: 'other' },
    ],
  },
  {
    uid: 'm5',
    email: 'noemi@wevo.app', password: 'wevo1234', username: 'n0eheart', name: 'Noemi', displayName: 'Noemi', age: 23,
    bio: "Late night chat, co-op e un po' di chaos.", photoUrl: 'https://picsum.photos/seed/noemi23p/200/200',
    coverUrl: 'https://picsum.photos/seed/noemi23c/600/900', interests: ['Chat', 'Co-op', 'Music'],
    favoriteGames: ['Overcooked', 'The Sims 4', 'Roblox'], platforms: ['PC', 'Mobile'], lookingFor: ['Chill', 'Duo'],
    discordTag: 'n0eheart', spotifyArtist: 'PinkPantheress', country: 'Italia', timezone: 'CET',
    messages: [
      { id: 'm5-msg-1', text: 'Facciamo un game e poi chat?', minutesAgo: 250, sender: 'other' },
      { id: 'm5-msg-2', text: 'Volentieri! Che giochi hai?', minutesAgo: 248, sender: 'demo' },
      { id: 'm5-msg-3', text: 'Overcooked per iniziare?', minutesAgo: 245, sender: 'other' },
    ],
  },
];

function matchIdFor(a, b) {
  return [a, b].sort().join('_');
}

async function ensureAuthUser(account) {
  try {
    await auth.createUser({
      uid: account.uid,
      email: account.email,
      password: account.password,
      displayName: account.displayName,
    });
    return 'created';
  } catch (error) {
    if (error?.code === 'auth/uid-already-exists') {
      await auth.updateUser(account.uid, {
        email: account.email,
        password: account.password,
        displayName: account.displayName,
      });
      return 'updated';
    }

    if (error?.code === 'auth/email-already-exists') {
      const existing = await auth.getUserByEmail(account.email);
      if (existing.uid !== account.uid) {
        console.warn(`⚠️ Email ${account.email} exists on uid ${existing.uid}, reusing existing auth uid instead of ${account.uid}`);
        await auth.updateUser(existing.uid, {
          email: account.email,
          password: account.password,
          displayName: account.displayName,
        });
        account.uid = existing.uid;
      } else {
        await auth.updateUser(account.uid, {
          email: account.email,
          password: account.password,
          displayName: account.displayName,
        });
      }
      return 'updated';
    }

    throw error;
  }
}

async function ensureProfile(profile, matches) {
  await db.collection('users').doc(profile.uid).set({
    uid: profile.uid,
    name: profile.name,
    username: profile.username,
    age: profile.age,
    email: profile.email,
    bio: profile.bio,
    photoUrl: profile.photoUrl,
    coverUrl: profile.coverUrl,
    interests: profile.interests,
    favoriteGames: profile.favoriteGames,
    platforms: profile.platforms,
    lookingFor: profile.lookingFor,
    discordTag: profile.discordTag ?? null,
    steamId: profile.steamId ?? null,
    spotifyArtist: profile.spotifyArtist ?? null,
    riotId: profile.riotId ?? null,
    timezone: profile.timezone,
    country: profile.country,
    isMock: profile.isMock === true,
    matches,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
}

async function seedMessages(chatId, demoUid, otherUid, messages) {
  const now = Date.now();
  let lastMessage = null;
  let lastMessageAt = null;
  let lastSenderId = null;

  for (const msg of messages) {
    const createdAt = Timestamp.fromMillis(now - msg.minutesAgo * 60 * 1000);
    const senderId = msg.sender === 'demo' ? demoUid : otherUid;
    await db.collection('chats').doc(chatId).collection('messages').doc(msg.id).set({
      text: msg.text,
      senderId,
      createdAt,
    }, { merge: true });
    lastMessage = msg.text;
    lastMessageAt = createdAt;
    lastSenderId = senderId;
  }

  return { lastMessage, lastMessageAt, lastSenderId };
}

async function seedPair(demoUid, user) {
  const authState = await ensureAuthUser(user);
  await ensureProfile(user, [demoUid]);

  const matchId = matchIdFor(demoUid, user.uid);
  const now = FieldValue.serverTimestamp();

  await db.collection('swipes').doc(`${demoUid}_${user.uid}`).set({
    from: demoUid,
    to: user.uid,
    liked: true,
    createdAt: now,
  }, { merge: true });

  await db.collection('swipes').doc(`${user.uid}_${demoUid}`).set({
    from: user.uid,
    to: demoUid,
    liked: true,
    createdAt: now,
  }, { merge: true });

  const seeded = await seedMessages(matchId, demoUid, user.uid, user.messages ?? []);

  const sharedData = {
    users: [demoUid, user.uid],
    createdAt: now,
    lastMessage: seeded.lastMessage,
    lastMessageAt: seeded.lastMessageAt,
    lastSenderId: seeded.lastSenderId,
    updatedAt: now,
  };

  await db.collection('chats').doc(matchId).set(sharedData, { merge: true });
  await db.collection('matches').doc(matchId).set(sharedData, { merge: true });

  await db.collection('users').doc(demoUid).set({
    matches: FieldValue.arrayUnion(user.uid),
    updatedAt: now,
  }, { merge: true });

  await db.collection('users').doc(user.uid).set({
    matches: FieldValue.arrayUnion(demoUid),
    updatedAt: now,
  }, { merge: true });

  console.log(`✓ ${user.email} (${authState})`);
}

async function main() {
  console.log('🌱 Seeding Wevo demo data with firebase-admin');

  const demoAuthState = await ensureAuthUser(demoAccount);
  await ensureProfile(demoAccount, demoUsers.map((user) => user.uid));
  console.log(`✓ ${demoAccount.email} (${demoAuthState})`);

  for (const user of demoUsers) {
    user.isMock = true;
    await seedPair(demoAccount.uid, user);
  }

  console.log('✅ Wevo seed complete');
}

main().catch((error) => {
  console.error('❌ Seed failed');
  console.error(error);
  process.exit(1);
});
