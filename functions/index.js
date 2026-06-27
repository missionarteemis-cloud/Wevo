import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { beforeUserCreated } from 'firebase-functions/v2/identity';
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

initializeApp();

const db = getFirestore();
const STARTER_COINS = 500;
const FUNCTION_REGION = 'us-central1';

export const grantStarterCoins = beforeUserCreated({ region: FUNCTION_REGION }, async (event) => {
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

export const buyItem = onCall({ region: FUNCTION_REGION }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const itemId = request.data?.itemId;
  if (typeof itemId !== 'string' || !itemId) {
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

export const placeItem = onCall({ region: FUNCTION_REGION }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const { instanceId, x, y, rot } = request.data ?? {};
  if (typeof instanceId !== 'string' || !instanceId) {
    throw new HttpsError('invalid-argument', 'instanceId is required.');
  }
  if (![x, y, rot].every((value) => Number.isInteger(value))) {
    throw new HttpsError('invalid-argument', 'x, y and rot must be integers.');
  }

  const uid = request.auth.uid;
  const userRef = db.collection('users').doc(uid);
  const inventoryRef = userRef.collection('inventory').doc(instanceId);
  const roomRef = db.collection('rooms').doc(uid);

  try {
    const result = await db.runTransaction(async (tx) => {
      const [inventorySnap, roomSnap] = await Promise.all([
        tx.get(inventoryRef),
        tx.get(roomRef),
      ]);

      if (!inventorySnap.exists) {
        return { ok: false, error: 'not-owned' };
      }

      const itemId = inventorySnap.data()?.itemId;
      if (typeof itemId !== 'string' || !itemId) {
        return { ok: false, error: 'invalid-item' };
      }

      const currentFurniture = Array.isArray(roomSnap.data()?.furniture)
        ? [...roomSnap.data().furniture]
        : [];

      currentFurniture.push({ instanceId, itemId, x, y, rot });

      tx.set(
        roomRef,
        {
          ownerUid: uid,
          furniture: currentFurniture,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      tx.delete(inventoryRef);

      return { ok: true, instanceId, itemId };
    });

    return result;
  } catch (error) {
    console.error('placeItem failed', error);
    throw new HttpsError('internal', 'placeItem failed');
  }
});

export const takeItem = onCall({ region: FUNCTION_REGION }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const instanceId = request.data?.instanceId;
  if (typeof instanceId !== 'string' || !instanceId) {
    throw new HttpsError('invalid-argument', 'instanceId is required.');
  }

  const uid = request.auth.uid;
  const userRef = db.collection('users').doc(uid);
  const inventoryRef = userRef.collection('inventory').doc(instanceId);
  const roomRef = db.collection('rooms').doc(uid);

  try {
    const result = await db.runTransaction(async (tx) => {
      const roomSnap = await tx.get(roomRef);
      const currentFurniture = Array.isArray(roomSnap.data()?.furniture)
        ? [...roomSnap.data().furniture]
        : [];

      const index = currentFurniture.findIndex((item) => item?.instanceId === instanceId);
      if (index === -1) {
        return { ok: false, error: 'not-found' };
      }

      const [removed] = currentFurniture.splice(index, 1);
      const itemId = removed?.itemId;
      if (typeof itemId !== 'string' || !itemId) {
        return { ok: false, error: 'invalid-item' };
      }

      tx.set(
        roomRef,
        {
          ownerUid: uid,
          furniture: currentFurniture,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      tx.set(inventoryRef, {
        itemId,
        acquiredAt: FieldValue.serverTimestamp(),
      });

      return { ok: true, instanceId, itemId };
    });

    return result;
  } catch (error) {
    console.error('takeItem failed', error);
    throw new HttpsError('internal', 'takeItem failed');
  }
});
