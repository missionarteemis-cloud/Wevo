import { initializeApp } from 'firebase/app';
import {
  getAuth,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
} from 'firebase/auth';
import {
  getFirestore,
  doc,
  setDoc,
  getDoc,
  updateDoc,
  arrayUnion,
  collection,
  addDoc,
  Timestamp,
} from 'firebase/firestore';

const firebaseConfig = {
  apiKey: 'AIzaSyBtc_p9_zKfPW_wICyp5qWFlqYSLCR0yYY',
  authDomain: 'wevo-22275.firebaseapp.com',
  projectId: 'wevo-22275',
  storageBucket: 'wevo-22275.firebasestorage.app',
  messagingSenderId: '800541292018',
  appId: '1:800541292018:web:b384c72504d28e033d676b',
  measurementId: 'G-TG0ZCQB0Q4',
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

const demoAccount = {
  email: 'demo@wevo.app',
  password: 'wevo1234',
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
    email: 'giulia@wevo.app', password: 'wevo1234', username: 'giuplays', name: 'Giulia', age: 24,
    bio: 'FPS, co-op e sessioni chill la sera.', photoUrl: 'https://picsum.photos/seed/giulia24p/200/200',
    coverUrl: 'https://picsum.photos/seed/giulia24c/600/900', interests: ['FPS', 'Co-op', 'Anime'],
    favoriteGames: ['Valorant', 'Overwatch 2', 'Phasmophobia'], platforms: ['PC'], lookingFor: ['Duo', 'Friendship'],
    discordTag: 'giuplays', spotifyArtist: 'The Japanese House', country: 'Italia', timezone: 'CET',
    messages: [
      { text: 'Ti va una duo stasera?', minutesAgo: 60, sender: 'other' },
      { text: 'Sì, dopo le 21 ci sono', minutesAgo: 58, sender: 'demo' },
      { text: 'Perfetto, ti aspetto!', minutesAgo: 55, sender: 'other' },
    ],
  },
  {
    email: 'marco@wevo.app', password: 'wevo1234', username: 'marcojungler', name: 'Marco', age: 27,
    bio: 'Main jungle, ranked ma senza drama.', photoUrl: 'https://picsum.photos/seed/marco27p/200/200',
    coverUrl: 'https://picsum.photos/seed/marco27c/600/900', interests: ['MOBA', 'Competitive', 'Tech'],
    favoriteGames: ['League of Legends', 'TFT'], platforms: ['PC'], lookingFor: ['Ranked', 'Community'],
    discordTag: 'marcojungler', riotId: 'Marco#EUW', steamId: 'marco27', country: 'Italia', timezone: 'CET',
    messages: [
      { text: 'Ranked o chill?', minutesAgo: 180, sender: 'other' },
      { text: 'Una ranked e poi chill', minutesAgo: 178, sender: 'demo' },
      { text: "Let's go allora", minutesAgo: 175, sender: 'other' },
    ],
  },
  {
    email: 'sofia@wevo.app', password: 'wevo1234', username: 'sofiacozy', name: 'Sofia', age: 22,
    bio: 'Indie cozy, design e late night Discord.', photoUrl: 'https://picsum.photos/seed/sofia22p/200/200',
    coverUrl: 'https://picsum.photos/seed/sofia22c/600/900', interests: ['Cozy', 'Design', 'Community'],
    favoriteGames: ['Stardew Valley', 'It Takes Two'], platforms: ['PC', 'Switch'], lookingFor: ['Chill', 'Friendship'],
    discordTag: 'sofiacozy', spotifyArtist: 'Clairo', country: 'Italia', timezone: 'CET',
    messages: [
      { text: 'Hey! Hai mai giocato a Stardew?', minutesAgo: 300, sender: 'other' },
      { text: 'Mai provato, mi incuriosisce!', minutesAgo: 298, sender: 'demo' },
      { text: 'Te lo mostro volentieri, è super rilassante', minutesAgo: 295, sender: 'other' },
    ],
  },
  {
    email: 'alex@wevo.app', password: 'wevo1234', username: 'alexvibes', name: 'Alex', age: 25,
    bio: 'Cerco duo, match e gente con vibe pulita.', photoUrl: 'https://picsum.photos/seed/alex25p/200/200',
    coverUrl: 'https://picsum.photos/seed/alex25c/600/900', interests: ['Music', 'Gaming', 'Movies'],
    favoriteGames: ['Fortnite', 'Minecraft', 'Party Animals'], platforms: ['PC', 'PlayStation'], lookingFor: ['Friendship', 'Community'],
    discordTag: 'alexvibes', country: 'Italia', timezone: 'CET',
    messages: [
      { text: 'Stessa vibe, stesso caos 🔥', minutesAgo: 400, sender: 'other' },
    ],
  },
  {
    email: 'noemi@wevo.app', password: 'wevo1234', username: 'n0eheart', name: 'Noemi', age: 23,
    bio: "Late night chat, co-op e un po' di chaos.", photoUrl: 'https://picsum.photos/seed/noemi23p/200/200',
    coverUrl: 'https://picsum.photos/seed/noemi23c/600/900', interests: ['Chat', 'Co-op', 'Music'],
    favoriteGames: ['Overcooked', 'The Sims 4', 'Roblox'], platforms: ['PC', 'Mobile'], lookingFor: ['Chill', 'Duo'],
    discordTag: 'n0eheart', spotifyArtist: 'PinkPantheress', country: 'Italia', timezone: 'CET',
    messages: [
      { text: 'Facciamo un game e poi chat?', minutesAgo: 250, sender: 'other' },
      { text: 'Volentieri! Che giochi hai?', minutesAgo: 248, sender: 'demo' },
      { text: 'Overcooked per iniziare?', minutesAgo: 245, sender: 'other' },
    ],
  },
];

async function ensureUser(account) {
  try {
    return await createUserWithEmailAndPassword(auth, account.email, account.password);
  } catch (error) {
    if (error?.code === 'auth/email-already-in-use') {
      return signInWithEmailAndPassword(auth, account.email, account.password);
    }
    if (error?.code === 'auth/invalid-credential' || error?.code === 'auth/user-not-found') {
      return signInWithEmailAndPassword(auth, account.email, account.password);
    }
    throw error;
  }
}

async function ensureProfile(uid, profile) {
  const ref = doc(db, 'users', uid);
  const snap = await getDoc(ref);
  if (!snap.exists()) {
    await setDoc(ref, { uid, ...profile, matches: profile.matches ?? [] });
    return;
  }
  await setDoc(ref, { uid, ...profile }, { merge: true });
}

function matchIdFor(a, b) {
  return [a, b].sort().join('_');
}

async function seedMessages(chatId, demoUid, otherUid, messages) {
  const now = Date.now();
  let lastMessage = null;
  let lastMessageAt = null;
  let lastSenderId = null;

  for (const msg of messages) {
    const ts = Timestamp.fromMillis(now - msg.minutesAgo * 60 * 1000);
    const senderId = msg.sender === 'demo' ? demoUid : otherUid;
    await addDoc(collection(db, 'chats', chatId, 'messages'), {
      text: msg.text,
      senderId,
      createdAt: ts,
    });
    lastMessage = msg.text;
    lastMessageAt = ts;
    lastSenderId = senderId;
  }

  return { lastMessage, lastMessageAt, lastSenderId };
}

async function main() {
  console.log('🌱 Seeding Wevo demo data');

  const demoCred = await ensureUser(demoAccount);
  const demoUid = demoCred.user.uid;

  await ensureProfile(demoUid, {
    name: demoAccount.name,
    username: demoAccount.username,
    age: demoAccount.age,
    email: demoAccount.email,
    bio: demoAccount.bio,
    photoUrl: demoAccount.photoUrl,
    coverUrl: demoAccount.coverUrl,
    interests: demoAccount.interests,
    favoriteGames: demoAccount.favoriteGames,
    platforms: demoAccount.platforms,
    lookingFor: demoAccount.lookingFor,
    country: demoAccount.country,
    timezone: demoAccount.timezone,
    matches: [],
  });

  for (const user of demoUsers) {
    const cred = await ensureUser(user);
    const otherUid = cred.user.uid;

    await ensureProfile(otherUid, {
      name: user.name,
      username: user.username,
      age: user.age,
      email: user.email,
      bio: user.bio,
      photoUrl: user.photoUrl,
      coverUrl: user.coverUrl,
      interests: user.interests,
      favoriteGames: user.favoriteGames,
      platforms: user.platforms,
      lookingFor: user.lookingFor,
      discordTag: user.discordTag ?? null,
      steamId: user.steamId ?? null,
      spotifyArtist: user.spotifyArtist ?? null,
      riotId: user.riotId ?? null,
      timezone: user.timezone,
      country: user.country,
      matches: [demoUid],
    });

    const matchId = matchIdFor(demoUid, otherUid);
    const swipeAB = doc(db, 'swipes', `${demoUid}_${otherUid}`);
    const swipeBA = doc(db, 'swipes', `${otherUid}_${demoUid}`);
    const matchRef = doc(db, 'matches', matchId);
    const chatRef = doc(db, 'chats', matchId);

    await setDoc(swipeAB, {
      from: demoUid,
      to: otherUid,
      liked: true,
      createdAt: Timestamp.now(),
    }, { merge: true });

    await setDoc(swipeBA, {
      from: otherUid,
      to: demoUid,
      liked: true,
      createdAt: Timestamp.now(),
    }, { merge: true });

    const seeded = await seedMessages(matchId, demoUid, otherUid, user.messages ?? []);

    await setDoc(chatRef, {
      users: [demoUid, otherUid],
      createdAt: Timestamp.now(),
      lastMessage: seeded.lastMessage,
      lastMessageAt: seeded.lastMessageAt,
      lastSenderId: seeded.lastSenderId,
    }, { merge: true });

    await setDoc(matchRef, {
      users: [demoUid, otherUid],
      createdAt: Timestamp.now(),
      lastMessage: seeded.lastMessage,
      lastMessageAt: seeded.lastMessageAt,
      lastSenderId: seeded.lastSenderId,
    }, { merge: true });

    await updateDoc(doc(db, 'users', demoUid), {
      matches: arrayUnion(otherUid),
    });
    await updateDoc(doc(db, 'users', otherUid), {
      matches: arrayUnion(demoUid),
    });

    console.log(`✓ ${user.email} seeded`);
  }

  console.log('✅ Wevo seed complete');
}

main().catch((error) => {
  console.error('❌ Seed failed');
  console.error(error);
  process.exit(1);
});
