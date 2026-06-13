import { initializeApp } from 'firebase/app';
import { getAuth, signInWithEmailAndPassword } from 'firebase/auth';
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

const accounts = {
  demo: { email: 'demo@wevo.app', password: 'wevo1234' },
  giulia: { email: 'giulia@wevo.app', password: 'wevo1234' },
  marco: { email: 'marco@wevo.app', password: 'wevo1234' },
  sofia: { email: 'sofia@wevo.app', password: 'wevo1234' },
};

async function login(account) {
  const cred = await signInWithEmailAndPassword(auth, account.email, account.password);
  return cred.user.uid;
}

async function like(fromAccount, toUid) {
  const fromUid = await login(fromAccount);
  await setDoc(doc(db, 'swipes', `${fromUid}_${toUid}`), {
    from: fromUid,
    to: toUid,
    liked: true,
    createdAt: new Date(),
  });
  return fromUid;
}

async function userUidByEmail(account) {
  const uid = await login(account);
  const snap = await getDoc(doc(db, 'users', uid));
  if (!snap.exists()) throw new Error(`missing user doc for ${account.email}`);
  return uid;
}

const demoUid = await userUidByEmail(accounts.demo);
const giuliaUid = await userUidByEmail(accounts.giulia);
const marcoUid = await userUidByEmail(accounts.marco);
const sofiaUid = await userUidByEmail(accounts.sofia);

await like(accounts.demo, giuliaUid);
await like(accounts.demo, marcoUid);
await like(accounts.demo, sofiaUid);

await like(accounts.giulia, demoUid);
await like(accounts.marco, demoUid);
await like(accounts.sofia, demoUid);

console.log('demo reciprocal swipes seeded');
