import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore, Timestamp } from 'firebase-admin/firestore';

initializeApp();

const db = getFirestore();
const STARTER_COINS = 500;
const CALLABLE_REGION = 'us-central1';

// Coins iniziali NON-bloccanti: callable idempotente chiamata dall'app dopo il
// login. (Sostituisce il vecchio trigger bloccante beforeUserCreated, che con le
// 2nd gen aveva un bug "aud claim" e BLOCCAVA la registrazione.)
export const claimStarterCoins = onCall({ region: CALLABLE_REGION }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
  const ref = db.collection('users').doc(request.auth.uid);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const coins = snap.data()?.coins;
    if (typeof coins === 'number') {
      return { ok: true, coins, granted: false };
    }
    tx.set(ref, { coins: STARTER_COINS, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    return { ok: true, coins: STARTER_COINS, granted: true };
  });
});

export const buyItem = onCall({ region: CALLABLE_REGION }, async (request) => {
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

export const placeItem = onCall({ region: CALLABLE_REGION }, async (request) => {
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

export const takeItem = onCall({ region: CALLABLE_REGION }, async (request) => {
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

export const sendChatMessage = onCall({ region: CALLABLE_REGION }, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const text = typeof request.data?.text === 'string' ? request.data.text.trim() : '';
  const otherUserId = typeof request.data?.otherUserId === 'string' ? request.data.otherUserId.trim() : '';

  if (!otherUserId) {
    throw new HttpsError('invalid-argument', 'otherUserId is required.');
  }

  if (!text) {
    throw new HttpsError('invalid-argument', 'text is required.');
  }

  if (text.length > 1000) {
    throw new HttpsError('invalid-argument', 'text too long.');
  }

  const uid = request.auth.uid;
  if (uid === otherUserId) {
    throw new HttpsError('invalid-argument', 'Cannot message yourself.');
  }

  const users = [uid, otherUserId].sort();
  const chatId = `${users[0]}_${users[1]}`;
  const chatRef = db.collection('chats').doc(chatId);
  const matchRef = db.collection('matches').doc(chatId);
  const messageRef = chatRef.collection('messages').doc();
  const senderRef = db.collection('users').doc(uid);
  const otherRef = db.collection('users').doc(otherUserId);

  try {
    const result = await db.runTransaction(async (tx) => {
      const [senderSnap, otherSnap, matchSnap, chatSnap] = await Promise.all([
        tx.get(senderRef),
        tx.get(otherRef),
        tx.get(matchRef),
        tx.get(chatRef),
      ]);

      if (!senderSnap.exists) {
        return { ok: false, error: 'sender-not-found' };
      }
      if (!otherSnap.exists) {
        return { ok: false, error: 'recipient-not-found' };
      }

      const senderMatches = Array.isArray(senderSnap.data()?.matches) ? senderSnap.data().matches : [];
      const otherMatches = Array.isArray(otherSnap.data()?.matches) ? otherSnap.data().matches : [];
      const matched = senderMatches.includes(otherUserId) || otherMatches.includes(uid) || matchSnap.exists;
      if (!matched) {
        return { ok: false, error: 'not-matched' };
      }

      tx.set(
        chatRef,
        {
          users,
          matchId: chatId,
          createdAt: chatSnap.exists ? chatSnap.data()?.createdAt ?? FieldValue.serverTimestamp() : FieldValue.serverTimestamp(),
          lastMessage: text,
          lastMessageAt: FieldValue.serverTimestamp(),
          lastSenderId: uid,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      tx.set(messageRef, {
        senderId: uid,
        text,
        createdAt: FieldValue.serverTimestamp(),
        type: 'text',
      });

      tx.set(
        matchRef,
        {
          users,
          createdAt: matchSnap.exists ? matchSnap.data()?.createdAt ?? FieldValue.serverTimestamp() : FieldValue.serverTimestamp(),
          lastMessage: text,
          lastMessageAt: FieldValue.serverTimestamp(),
          lastSenderId: uid,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      const otherIsMock = otherSnap.data()?.isMock === true;
      return { ok: true, chatId, messageId: messageRef.id, otherIsMock };
    });

    if (!result.ok) {
      return result;
    }

    if (result.otherIsMock) {
      const replyText = 'OK';
      const replyAt = Timestamp.fromDate(new Date(Date.now() + 1500));
      await chatRef.collection('messages').add({
        senderId: otherUserId,
        text: replyText,
        createdAt: replyAt,
        type: 'text',
        automated: true,
      });
      await Promise.all([
        chatRef.set(
          {
            lastMessage: replyText,
            lastMessageAt: replyAt,
            lastSenderId: otherUserId,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        ),
        matchRef.set(
          {
            lastMessage: replyText,
            lastMessageAt: replyAt,
            lastSenderId: otherUserId,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        ),
      ]);
    }

    return result;
  } catch (error) {
    console.error('sendChatMessage failed', error);
    throw new HttpsError('internal', 'sendChatMessage failed');
  }
});
