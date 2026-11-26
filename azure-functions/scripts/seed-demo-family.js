'use strict';

/**
 * Creates a demo family with three members and two weeks of overlapping
 * calendars, so the multi-day free-time search has something realistic to
 * find.
 *
 * A reviewer needs to log in and click. An empty account proves nothing —
 * "no free windows found" and "the feature is broken" look identical from
 * the outside. The schedules below are deliberately awkward: work, school
 * and evening commitments overlap enough that most days have no three-hour
 * window, which is what makes the handful that do worth surfacing.
 *
 * Usage, from azure-functions/ (firebase-admin must be installed):
 *   node scripts/seed-demo-family.js ../service-account.json
 *
 * Safe to re-run: existing demo accounts are reused and their events are
 * cleared first, so you get one clean family rather than a pile of them.
 */

const admin = require('firebase-admin');
const path = require('path');

const KEY_PATH = process.argv[2];
if (!KEY_PATH) {
  console.error('Usage: node scripts/seed-demo-family.js <service-account.json>');
  process.exit(1);
}

// eslint-disable-next-line import/no-dynamic-require
const serviceAccount = require(path.resolve(KEY_PATH));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id,
});

const auth = admin.auth();
const db = admin.firestore();

const PASSWORD = 'FamilyPulse2026!';
const FAMILY_NAME = 'Demo Family';

const MEMBERS = [
  { email: 'anne@familypulse.demo', name: 'Anne', role: 'parent', label: 'Reviewer' },
  { email: 'mikko@familypulse.demo', name: 'Mikko', role: 'parent', label: 'Dad' },
  { email: 'sofia@familypulse.demo', name: 'Sofia', role: 'child', label: 'Daughter' },
];

/**
 * Busy blocks per weekday index (0 = Monday). Hours are local.
 * Tuned so that roughly a third of days have a usable three-hour window and
 * the rest do not — a search that returns everything is as useless as one
 * that returns nothing.
 */
const WEEKDAY_SCHEDULE = {
  0: [ // Monday — nothing free in the evening
    { who: 1, title: 'Work', from: 9, to: 17 },
    { who: 2, title: 'School', from: 8, to: 15 },
    { who: 0, title: 'Teaching', from: 10, to: 16 },
    { who: 0, title: 'Choir practice', from: 18, to: 20.5 },
    { who: 1, title: 'Gym', from: 17.5, to: 19 },
  ],
  1: [ // Tuesday — Sofia's football blocks the early evening
    { who: 1, title: 'Work', from: 9, to: 17 },
    { who: 2, title: 'School', from: 8, to: 15 },
    { who: 2, title: 'Football training', from: 17, to: 19 },
    { who: 0, title: 'Teaching', from: 10, to: 18 },
  ],
  2: [ // Wednesday — short day, this one should surface
    { who: 1, title: 'Work', from: 9, to: 15 },
    { who: 2, title: 'School', from: 8, to: 14 },
    { who: 0, title: 'Teaching', from: 9, to: 15 },
  ],
  3: [ // Thursday — late meetings
    { who: 1, title: 'Work', from: 9, to: 17 },
    { who: 1, title: 'Project review', from: 18, to: 20 },
    { who: 2, title: 'School', from: 8, to: 15 },
    { who: 0, title: 'Teaching', from: 10, to: 16 },
    { who: 0, title: 'Department meeting', from: 17, to: 19.5 },
  ],
  4: [ // Friday — everyone finishes early
    { who: 1, title: 'Work', from: 9, to: 15 },
    { who: 2, title: 'School', from: 8, to: 13 },
    { who: 0, title: 'Teaching', from: 9, to: 14 },
  ],
  5: [ // Saturday — one commitment each, morning gone
    { who: 2, title: 'Football match', from: 10, to: 12.5 },
    { who: 1, title: 'Shopping run', from: 9, to: 11 },
  ],
  6: [ // Sunday — Sofia busy all afternoon
    { who: 2, title: 'Homework group', from: 13, to: 17 },
    { who: 0, title: 'Church', from: 10, to: 12 },
  ],
};

function hoursToDate(baseDate, hours) {
  const date = new Date(baseDate);
  date.setHours(Math.floor(hours), Math.round((hours % 1) * 60), 0, 0);
  return date;
}

async function ensureUser({ email, name }) {
  try {
    const existing = await auth.getUserByEmail(email);
    await auth.updateUser(existing.uid, { password: PASSWORD, displayName: name });
    console.log(`  reused ${email}`);
    return existing.uid;
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    const created = await auth.createUser({
      email,
      password: PASSWORD,
      displayName: name,
      emailVerified: true,
    });
    console.log(`  created ${email}`);
    return created.uid;
  }
}

/** Finds the demo family this script created previously, if any. */
async function findExistingFamily(uid) {
  const snapshot = await db
    .collectionGroup('users')
    .where('user_id', '==', uid)
    .limit(1)
    .get();
  if (snapshot.empty) return null;
  return snapshot.docs[0].ref.parent.parent.id;
}

async function clearEvents(familyId) {
  const events = await db
    .collection('families')
    .doc(familyId)
    .collection('events')
    .get();

  let batch = db.batch();
  let count = 0;
  for (const doc of events.docs) {
    batch.delete(doc.ref);
    count += 1;
    if (count % 400 === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }
  if (count % 400 !== 0) await batch.commit();
  return count;
}

async function main() {
  console.log('Creating demo accounts…');
  const uids = [];
  for (const member of MEMBERS) uids.push(await ensureUser(member));

  let familyId = await findExistingFamily(uids[0]);

  if (familyId) {
    console.log(`\nReusing family ${familyId}`);
    const removed = await clearEvents(familyId);
    console.log(`  cleared ${removed} existing events`);
  } else {
    const familyRef = await db.collection('families').add({
      name: FAMILY_NAME,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    familyId = familyRef.id;
    console.log(`\nCreated family ${familyId}`);
  }

  // Membership documents are keyed by uid and also carry user_id, because the
  // app looks members up both ways — by document id from the family, and by
  // collection-group query from the user.
  const memberBatch = db.batch();
  MEMBERS.forEach((member, index) => {
    const ref = db
      .collection('families')
      .doc(familyId)
      .collection('users')
      .doc(uids[index]);
    memberBatch.set(ref, {
      user_id: uids[index],
      name: member.name,
      email: member.email,
      role: member.role,
      label: member.label,
    });
  });
  await memberBatch.commit();
  console.log(`  ${MEMBERS.length} members attached`);

  // Two weeks of events starting tomorrow, so "the next 14 days" is always
  // populated regardless of when the demo is opened.
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  let eventBatch = db.batch();
  let created = 0;

  for (let dayOffset = 1; dayOffset <= 14; dayOffset += 1) {
    const day = new Date(today);
    day.setDate(day.getDate() + dayOffset);

    // JS getDay(): 0 = Sunday. Our table is 0 = Monday.
    const weekday = (day.getDay() + 6) % 7;

    for (const block of WEEKDAY_SCHEDULE[weekday]) {
      const start = hoursToDate(day, block.from);
      const end = hoursToDate(day, block.to);
      const ref = db
        .collection('families')
        .doc(familyId)
        .collection('events')
        .doc();

      eventBatch.set(ref, {
        title: block.title,
        description: '',
        date: start,
        category: '',
        start_time: start,
        end_time: end,
        user_id: uids[block.who],
        user_name: MEMBERS[block.who].name,
        recurrence: 'none',
        recurrence_end_date: null,
        series_id: null,
        reminder_minutes_before: null,
      });

      created += 1;
      if (created % 400 === 0) {
        await eventBatch.commit();
        eventBatch = db.batch();
      }
    }
  }
  if (created % 400 !== 0) await eventBatch.commit();

  console.log(`  ${created} events written across 14 days\n`);
  console.log('─'.repeat(52));
  console.log('Demo family ready');
  console.log('─'.repeat(52));
  console.log(`Family code : ${familyId}`);
  console.log(`Password    : ${PASSWORD}`);
  for (const member of MEMBERS) {
    console.log(`  ${member.name.padEnd(6)} ${member.email}`);
  }
  console.log('─'.repeat(52));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('\nSeeding failed:', error);
    process.exit(1);
  });
