import { initializeApp } from 'firebase/app';
import { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword } from 'firebase/auth';
import { getFirestore, doc, setDoc, getDoc } from 'firebase/firestore';

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

const demoUsers = [
  {
    email: 'giulia@wevo.app', password: 'wevo1234', username: 'giuplays', name: 'Giulia', age: 24,
    bio: 'FPS, co-op e sessioni chill la sera.', interests: ['FPS', 'Co-op', 'Anime'],
    favoriteGames: ['Valorant', 'Overwatch 2', 'Phasmophobia'], platforms: ['PC'], lookingFor: ['Duo', 'Friendship'],
    discordTag: 'giuplays', spotifyArtist: 'The Japanese House', country: 'Italia', timezone: 'CET'
  },
  {
    email: 'marco@wevo.app', password: 'wevo1234', username: 'marcojungler', name: 'Marco', age: 27,
    bio: 'Main jungle, ranked ma senza drama.', interests: ['MOBA', 'Competitive', 'Tech'],
    favoriteGames: ['League of Legends', 'TFT'], platforms: ['PC'], lookingFor: ['Ranked', 'Community'],
    discordTag: 'marcojungler', riotId: 'Marco#EUW', steamId: 'marco27', country: 'Italia', timezone: 'CET'
  },
  {
    email: 'sofia@wevo.app', password: 'wevo1234', username: 'sofiacozy', name: 'Sofia', age: 22,
    bio: 'Indie cozy, design e late night Discord.', interests: ['Cozy', 'Design', 'Community'],
    favoriteGames: ['Stardew Valley', 'It Takes Two'], platforms: ['PC', 'Switch'], lookingFor: ['Chill', 'Friendship'],
    discordTag: 'sofiacozy', spotifyArtist: 'Clairo', country: 'Italia', timezone: 'CET'
  }
];

for (const user of demoUsers) {
  try {
    let cred;
    try {
      cred = await createUserWithEmailAndPassword(auth, user.email, user.password);
    } catch {
      cred = await signInWithEmailAndPassword(auth, user.email, user.password);
    }

    const ref = doc(db, 'users', cred.user.uid);
    const snap = await getDoc(ref);
    if (!snap.exists()) {
      await setDoc(ref, {
        uid: cred.user.uid,
        name: user.name,
        username: user.username,
        age: user.age,
        email: user.email,
        bio: user.bio,
        interests: user.interests,
        favoriteGames: user.favoriteGames,
        platforms: user.platforms,
        lookingFor: user.lookingFor,
        photoUrl: '',
        coverUrl: '',
        discordTag: user.discordTag ?? null,
        steamId: user.steamId ?? null,
        spotifyArtist: user.spotifyArtist ?? null,
        riotId: user.riotId ?? null,
        timezone: user.timezone,
        country: user.country,
        likedBy: [],
        matches: [],
      });
    }
    console.log(`ok ${user.email}`);
  } catch (e) {
    console.error(`fail ${user.email}`, e.message);
  }
}
