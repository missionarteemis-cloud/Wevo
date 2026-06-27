import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('❌ Missing GOOGLE_APPLICATION_CREDENTIALS');
  process.exit(1);
}

initializeApp({ credential: applicationDefault() });
const db = getFirestore();
const STARTER_COINS = 500;

const catalog = [
  {
    itemId: 'sofa_neon_2x1',
    name: 'Neon Sofa',
    description: 'Divano lounge glow per room cyberpop.',
    price: 120,
    type: 'arredi',
    footprint: { w: 2, h: 1 },
    rotatable: true,
    interaction: 'sit',
    assetRef: 'sofa_neon_2x1',
  },
  {
    itemId: 'table_low_2x2',
    name: 'Low Table',
    description: 'Tavolo basso quadrato per la zona chill.',
    price: 90,
    type: 'arredi',
    footprint: { w: 2, h: 2 },
    rotatable: false,
    interaction: 'none',
    assetRef: 'table_low_2x2',
  },
  {
    itemId: 'lamp_pillar_1x1',
    name: 'Pillar Lamp',
    description: 'Luce verticale per accenti neon.',
    price: 70,
    type: 'arredi',
    footprint: { w: 1, h: 1 },
    rotatable: true,
    interaction: 'none',
    assetRef: 'lamp_pillar_1x1',
  },
  {
    itemId: 'bed_loft_3x1',
    name: 'Loft Bed',
    description: 'Letto isometrico con vibe late-night.',
    price: 160,
    type: 'arredi',
    footprint: { w: 3, h: 1 },
    rotatable: true,
    interaction: 'lie',
    assetRef: 'bed_loft_3x1',
  },
  {
    itemId: 'arcade_duo_2x2',
    name: 'Arcade Duo',
    description: 'Cabinato doppio per showdown in stanza.',
    price: 220,
    type: 'arredi',
    footprint: { w: 2, h: 2 },
    rotatable: true,
    interaction: 'sit',
    assetRef: 'arcade_duo_2x2',
  },
  {
    itemId: 'neon_rug_3x2',
    name: 'Neon Rug',
    description: 'Tappeto glow che unisce tutta la palette.',
    price: 85,
    type: 'arredi',
    footprint: { w: 3, h: 2 },
    rotatable: true,
    interaction: 'none',
    assetRef: 'neon_rug_3x2',
  },
  {
    itemId: 'fridge_pixel_1x1',
    name: 'Pixel Fridge',
    description: 'Mini frigo isometrico per la zona social.',
    price: 110,
    type: 'arredi',
    footprint: { w: 1, h: 1 },
    rotatable: true,
    interaction: 'none',
    assetRef: 'fridge_pixel_1x1',
  },
  {
    itemId: 'coins_pack_small',
    name: 'Coins Pack S',
    description: 'Placeholder store item per il tab crediti.',
    price: 4,
    type: 'crediti',
    footprint: { w: 0, h: 0 },
    rotatable: false,
    interaction: 'none',
    assetRef: 'coins_pack_small',
  },
  {
    itemId: 'hoodie_neon_drop',
    name: 'Neon Hoodie',
    description: 'Placeholder wearable per il tab vestiti.',
    price: 140,
    type: 'vestiti',
    footprint: { w: 0, h: 0 },
    rotatable: false,
    interaction: 'none',
    assetRef: 'hoodie_neon_drop',
  },
  {
    itemId: 'summer_event_pass',
    name: 'Summer Event Pass',
    description: 'Placeholder limited item per il tab evento.',
    price: 260,
    type: 'evento',
    footprint: { w: 0, h: 0 },
    rotatable: false,
    interaction: 'none',
    assetRef: 'summer_event_pass',
  },
];

async function seedCatalog() {
  console.log('🛍️ Seeding Wevo catalog');
  for (const item of catalog) {
    await db.collection('catalog').doc(item.itemId).set({
      ...item,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    console.log(`✓ ${item.itemId}`);
  }
}

async function grantCoinsToExistingUsers() {
  console.log('💰 Granting starter coins to existing users');
  const usersSnap = await db.collection('users').get();
  for (const doc of usersSnap.docs) {
    const currentCoins = Number(doc.data().coins ?? 0);
    if (currentCoins >= STARTER_COINS) {
      console.log(`• ${doc.id} already has ${currentCoins}`);
      continue;
    }
    await doc.ref.set({
      coins: STARTER_COINS,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    console.log(`✓ ${doc.id} -> ${STARTER_COINS} coins`);
  }
}

async function main() {
  await seedCatalog();
  await grantCoinsToExistingUsers();
  console.log('✅ Catalog seed complete');
}

main().catch((error) => {
  console.error('❌ Catalog seed failed');
  console.error(error);
  process.exit(1);
});
