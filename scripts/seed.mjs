import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

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
  isMock: false,
};

const matchedMocks = [
  {
    uid: 'm1',
    email: 'giulia@wevo.app', password: 'wevo1234', username: 'giuplays', name: 'Giulia', displayName: 'Giulia', age: 24,
    bio: 'FPS, co-op e sessioni chill la sera.', photoUrl: 'https://picsum.photos/seed/giulia24p/200/200',
    coverUrl: 'https://picsum.photos/seed/giulia24c/600/900', interests: ['FPS', 'Co-op', 'Anime'],
    favoriteGames: ['Valorant', 'Overwatch 2', 'Phasmophobia'], platforms: ['PC'], lookingFor: ['Duo', 'Friendship'],
    discordTag: 'giuplays', spotifyArtist: 'The Japanese House', country: 'Italia', timezone: 'CET', isMock: true,
  },
  {
    uid: 'm2',
    email: 'marco@wevo.app', password: 'wevo1234', username: 'marcojungler', name: 'Marco', displayName: 'Marco', age: 27,
    bio: 'Main jungle, ranked ma senza drama.', photoUrl: 'https://picsum.photos/seed/marco27p/200/200',
    coverUrl: 'https://picsum.photos/seed/marco27c/600/900', interests: ['MOBA', 'Competitive', 'Tech'],
    favoriteGames: ['League of Legends', 'TFT'], platforms: ['PC'], lookingFor: ['Ranked', 'Community'],
    discordTag: 'marcojungler', riotId: 'Marco#EUW', steamId: 'marco27', country: 'Italia', timezone: 'CET', isMock: true,
  },
  {
    uid: 'm3',
    email: 'sofia@wevo.app', password: 'wevo1234', username: 'sofiacozy', name: 'Sofia', displayName: 'Sofia', age: 22,
    bio: 'Indie cozy, design e late night Discord.', photoUrl: 'https://picsum.photos/seed/sofia22p/200/200',
    coverUrl: 'https://picsum.photos/seed/sofia22c/600/900', interests: ['Cozy', 'Design', 'Community'],
    favoriteGames: ['Stardew Valley', 'It Takes Two'], platforms: ['PC', 'Switch'], lookingFor: ['Chill', 'Friendship'],
    discordTag: 'sofiacozy', spotifyArtist: 'Clairo', country: 'Italia', timezone: 'CET', isMock: true,
  },
  {
    uid: 'm4',
    email: 'alex@wevo.app', password: 'wevo1234', username: 'alexvibes', name: 'Alex', displayName: 'Alex', age: 25,
    bio: 'Cerco duo, match e gente con vibe pulita.', photoUrl: 'https://picsum.photos/seed/alex25p/200/200',
    coverUrl: 'https://picsum.photos/seed/alex25c/600/900', interests: ['Music', 'Gaming', 'Movies'],
    favoriteGames: ['Fortnite', 'Minecraft', 'Party Animals'], platforms: ['PC', 'PlayStation'], lookingFor: ['Friendship', 'Community'],
    discordTag: 'alexvibes', country: 'Italia', timezone: 'CET', isMock: true,
  },
  {
    uid: 'm5',
    email: 'noemi@wevo.app', password: 'wevo1234', username: 'n0eheart', name: 'Noemi', displayName: 'Noemi', age: 23,
    bio: "Late night chat, co-op e un po' di chaos.", photoUrl: 'https://picsum.photos/seed/noemi23p/200/200',
    coverUrl: 'https://picsum.photos/seed/noemi23c/600/900', interests: ['Chat', 'Co-op', 'Music'],
    favoriteGames: ['Overcooked', 'The Sims 4', 'Roblox'], platforms: ['PC', 'Mobile'], lookingFor: ['Chill', 'Duo'],
    discordTag: 'n0eheart', spotifyArtist: 'PinkPantheress', country: 'Italia', timezone: 'CET', isMock: true,
  },
];

const discoverMocks = [
  {
    uid: 'disc1',
    email: 'disc1@wevo.app', password: 'wevo1234', username: 'latebyte', name: 'Nina', displayName: 'Nina', age: 24,
    bio: 'Late-night byte vibes e duo improvvisate.', photoUrl: 'https://picsum.photos/seed/disc1p/200/200',
    coverUrl: 'https://picsum.photos/seed/disc1c/600/900', interests: ['Tech', 'Gaming', 'Music'],
    favoriteGames: ['Valorant', 'Minecraft'], platforms: ['PC'], lookingFor: ['Friendship', 'Duo'],
    country: 'Italia', timezone: 'CET', isMock: true,
  },
  {
    uid: 'disc2',
    email: 'disc2@wevo.app', password: 'wevo1234', username: 'pixelroma', name: 'Lorenzo', displayName: 'Lorenzo', age: 26,
    bio: 'Pixel art, co-op, caffeina e room glow.', photoUrl: 'https://picsum.photos/seed/disc2p/200/200',
    coverUrl: 'https://picsum.photos/seed/disc2c/600/900', interests: ['Design', 'Co-op', 'Community'],
    favoriteGames: ['It Takes Two', 'Stardew Valley'], platforms: ['PC', 'Switch'], lookingFor: ['Chill', 'Community'],
    country: 'Italia', timezone: 'CET', isMock: true,
  },
  {
    uid: 'disc3',
    email: 'disc3@wevo.app', password: 'wevo1234', username: 'rushmode', name: 'Sara', displayName: 'Sara', age: 23,
    bio: 'Rush mode, headset sempre acceso.', photoUrl: 'https://picsum.photos/seed/disc3p/200/200',
    coverUrl: 'https://picsum.photos/seed/disc3c/600/900', interests: ['FPS', 'Anime', 'Chat'],
    favoriteGames: ['Overwatch 2', 'Apex Legends'], platforms: ['PC'], lookingFor: ['Duo', 'Chat'],
    country: 'Italia', timezone: 'CET', isMock: true,
  },
  {
    uid: 'disc4',
    email: 'disc4@wevo.app', password: 'wevo1234', username: 'moonroom', name: 'Elia', displayName: 'Elia', age: 25,
    bio: 'Room cozy, synthwave e sessioni chill.', photoUrl: 'https://picsum.photos/seed/disc4p/200/200',
    coverUrl: 'https://picsum.photos/seed/disc4c/600/900', interests: ['Movies', 'Music', 'Community'],
    favoriteGames: ['Fortnite', 'Party Animals'], platforms: ['PC', 'PlayStation'], lookingFor: ['Friendship', 'Community'],
    country: 'Italia', timezone: 'CET', isMock: true,
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

async function seedMatchedMock(demoUid, user) {
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

  const sharedData = {
    users: [demoUid, user.uid],
    createdAt: now,
    lastMessage: null,
    lastMessageAt: null,
    lastSenderId: null,
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

  console.log(`✓ matched mock ${user.email} (${authState})`);
}

async function seedDiscoverMock(demoUid, user) {
  const authState = await ensureAuthUser(user);
  await ensureProfile(user, []);

  await db.collection('swipes').doc(`${user.uid}_${demoUid}`).set({
    from: user.uid,
    to: demoUid,
    liked: true,
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`✓ discover mock ${user.email} (${authState})`);
}

async function main() {
  console.log('🌱 Seeding Wevo demo data with firebase-admin');

  const demoAuthState = await ensureAuthUser(demoAccount);
  await ensureProfile(demoAccount, matchedMocks.map((user) => user.uid));
  console.log(`✓ ${demoAccount.email} (${demoAuthState})`);

  for (const user of matchedMocks) {
    await seedMatchedMock(demoAccount.uid, user);
  }

  for (const user of discoverMocks) {
    await seedDiscoverMock(demoAccount.uid, user);
  }

  console.log('✅ Wevo seed complete');
}

main().catch((error) => {
  console.error('❌ Seed failed');
  console.error(error);
  process.exit(1);
});
