import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { beforeUserCreated } from 'firebase-functions/v2/identity';
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

initializeApp();

const db = getFirestore();
const STARTER_COINS = 500;

export const grantStarterCoins = beforeUserCreated({ region: 'us-central1' }, async (event) => {
  const user = event.data;
  if (!user?.uid) return;

  await db.collection('users').doc(user.uid).set(
    {
      uid: user.uid,
      email: user.email ?? null,
      coins: STARTER_COINS,
      updatedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
});

export const buyItem = onCall({ region: 'us-central1' }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const itemId = request.data?.itemId;
  if (typeof itemId !== 'string' || itemId.isEmpty) {
    throw new HttpsError('invalid-argument', 'itemId is required.');
  }

  const uid = request.auth.uid;
  const userRef = db.collection('users').doc(uid);
  const catalogRef = db.collection('catalog').doc(itemId);
  const inventoryRef = userRef.collection('inventory').doc();

  try {
    const result = await db.runTransaction(async (tx) => {
      const [userSnap, catalogSnap] = await Promise.all([
        tx.get(userRef),
        tx.get(catalogRef),
      ]);

      if (!catalogSnap.exists) {
        return { ok: false, error: 'not-found' };
      }

      const item = catalogSnap.data();
      const price = Number(item?.price ?? 0);
      const coins = Number(userSnap.data()?.coins ?? 0);

      if (coins < price) {
        return { ok: false, error: 'insufficient' };
      }

      tx.set(
        userRef,
        {
          coins: coins - price,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      tx.set(inventoryRef, {
        itemId,
        acquiredAt: FieldValue.serverTimestamp(),
      });

      return { ok: true, instanceId: inventoryRef.id, remainingCoins: coins - price };
    });

    return result;
  } catch (error) {
    console.error('buyItem failed', error);
    throw new HttpsError('internal', 'buyItem failed');
  }
});
