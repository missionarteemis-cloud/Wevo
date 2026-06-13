import { initializeApp } from 'firebase/app';
import { getAuth, signInWithEmailAndPassword } from 'firebase/auth';
import { getFirestore, doc, setDoc, updateDoc, arrayUnion } from 'firebase/firestore';

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

const accounts = {
  demo: { email: 'demo@wevo.app', password: 'wevo1234' },
  giulia: { email: 'giulia@wevo.app', password: 'wevo1234' },
  marco: { email: 'marco@wevo.app', password: 'wevo1234' },
  sofia: { email: 'sofia@wevo.app', password: 'wevo1234' },
};

async function uidFor(account) {
  const cred = await signInWithEmailAndPassword(auth, account.email, account.password);
  return cred.user.uid;
}

const demoUid = await uidFor(accounts.demo);
const giuliaUid = await uidFor(accounts.giulia);
const marcoUid = await uidFor(accounts.marco);
const sofiaUid = await uidFor(accounts.sofia);

const pairs = [
  [demoUid, giuliaUid],
  [demoUid, marcoUid],
  [demoUid, sofiaUid],
];

for (const [a, b] of pairs) {
  const swipeAB = doc(db, 'swipes', `${a}_${b}`);
  const swipeBA = doc(db, 'swipes', `${b}_${a}`);
  const matchId = [a, b].sort().join('_');
  const matchRef = doc(db, 'matches', matchId);
  const userA = doc(db, 'users', a);
  const userB = doc(db, 'users', b);

  await setDoc(swipeAB, { from: a, to: b, liked: true });
  await setDoc(swipeBA, { from: b, to: a, liked: true });
  await setDoc(matchRef, {
    users: [a, b],
    createdAt: new Date(),
    lastMessage: null,
  });
  await updateDoc(userA, { matches: arrayUnion(b) });
  await updateDoc(userB, { matches: arrayUnion(a) });

  console.log(`match ready: ${a} <-> ${b}`);
}
