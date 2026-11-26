'use strict';

const { app } = require('@azure/functions');
const { verifyIdToken, firestore } = require('../lib/firebase');
const { findFreeSlotsInRange } = require('../lib/slots');

/**
 * POST /api/free-slots
 *
 * Finds windows where every member of a family is simultaneously free, across
 * a range of days rather than a single one.
 *
 * Firebase Auth and Cloud Firestore are untouched by this endpoint — it holds
 * no user table, issues no tokens and owns no data. It verifies the caller's
 * existing Firebase ID token, reads the same Firestore documents the app
 * already reads, and returns a computed answer. Azure is doing the arithmetic;
 * Firebase remains the system of record.
 *
 * Request body:
 *   familyId            string   required
 *   rangeStartIso       string   required — UTC instant of day 0's LOCAL midnight
 *   days                number   1..31, default 14
 *   minDurationMinutes  number   default 60
 *   dayStartHour        number   default 8   — local hour the day becomes usable
 *   dayEndHour          number   default 22  — local hour it stops being usable
 *   maxResults          number   default 10
 */

const MAX_DAYS = 31;
const MS_PER_DAY = 24 * 60 * 60 * 1000;

app.http('freeSlots', {
  methods: ['POST', 'OPTIONS'],
  authLevel: 'anonymous', // Authorisation is the Firebase token, not an Azure key.
  route: 'free-slots',
  handler: async (request, context) => {
    if (request.method === 'OPTIONS') return { status: 204 };

    // ── 1. Authenticate ──────────────────────────────────────────────────
    // Nothing below this point runs for an unauthenticated caller. The token
    // is verified against Google's public keys by firebase-admin, so a forged
    // or expired one fails here rather than deeper in.
    const header = request.headers.get('authorization') || '';
    const match = header.match(/^Bearer (.+)$/i);
    if (!match) {
      return json(401, { error: 'missing_token' });
    }

    let claims;
    try {
      claims = await verifyIdToken(match[1]);
    } catch (error) {
      context.warn(`Token rejected: ${error.code || error.message}`);
      return json(401, { error: 'invalid_token' });
    }

    // ── 2. Validate input ────────────────────────────────────────────────
    let body;
    try {
      body = await request.json();
    } catch {
      return json(400, { error: 'invalid_json' });
    }

    const familyId = typeof body.familyId === 'string' ? body.familyId.trim() : '';
    if (!familyId) return json(400, { error: 'family_id_required' });

    const rangeStart = new Date(body.rangeStartIso);
    if (Number.isNaN(rangeStart.getTime())) {
      return json(400, { error: 'invalid_range_start' });
    }

    const days = clamp(body.days ?? 14, 1, MAX_DAYS);
    const minDurationMinutes = clamp(body.minDurationMinutes ?? 60, 15, 12 * 60);
    const dayStartHour = clamp(body.dayStartHour ?? 8, 0, 23);
    const dayEndHour = clamp(body.dayEndHour ?? 22, dayStartHour + 1, 24);
    const maxResults = clamp(body.maxResults ?? 10, 1, 50);

    const db = firestore();

    // ── 3. Authorise ─────────────────────────────────────────────────────
    // This is the check Firestore security rules perform for free on the
    // client path, and which therefore has to be re-implemented the moment a
    // server with admin credentials sits in front of the data. The Admin SDK
    // bypasses security rules entirely — it is trusted by definition — so
    // without this block any authenticated FamilyPulse user could read any
    // family's calendar simply by changing familyId in the request.
    const callerDoc = await db
      .collection('families')
      .doc(familyId)
      .collection('users')
      .doc(claims.uid)
      .get();

    if (!callerDoc.exists) {
      context.warn(`uid ${claims.uid} is not a member of family ${familyId}`);
      return json(403, { error: 'not_a_family_member' });
    }

    // ── 4. Read the family and its calendar ──────────────────────────────
    const membersSnapshot = await db
      .collection('families')
      .doc(familyId)
      .collection('users')
      .get();

    const memberIds = membersSnapshot.docs.map((doc) => doc.id);
    if (memberIds.length === 0) return json(404, { error: 'family_empty' });

    const rangeEnd = new Date(rangeStart.getTime() + days * MS_PER_DAY);

    // One range query instead of one query per day. Firestore charges per
    // document read, so fetching the window once and partitioning it in memory
    // is both faster and cheaper than 14 round trips.
    const eventsSnapshot = await db
      .collection('families')
      .doc(familyId)
      .collection('events')
      .where('start_time', '>=', rangeStart)
      .where('start_time', '<', rangeEnd)
      .get();

    const events = [];
    for (const doc of eventsSnapshot.docs) {
      const data = doc.data();
      const start = toDate(data.start_time);
      const end = toDate(data.end_time);
      if (!start || !end || end <= start) continue; // skip malformed rows
      events.push({ userId: data.user_id, start, end });
    }

    // ── 5. Compute ───────────────────────────────────────────────────────
    const slots = findFreeSlotsInRange({
      events,
      memberIds,
      rangeStart,
      days,
      dayStartHour,
      dayEndHour,
      minDurationMinutes,
      maxResults,
    });

    context.log(
      `family=${familyId} members=${memberIds.length} days=${days} ` +
        `events=${events.length} slots=${slots.length}`,
    );

    return json(200, {
      familyId,
      memberCount: memberIds.length,
      query: { days, minDurationMinutes, dayStartHour, dayEndHour },
      scanned: { events: events.length },
      slots: slots.map((slot) => ({
        startIso: slot.start.toISOString(),
        endIso: slot.end.toISOString(),
        durationMinutes: slot.durationMinutes,
        dayIndex: slot.dayIndex,
      })),
    });
  },
});

function clamp(value, min, max) {
  const number = Number(value);
  if (!Number.isFinite(number)) return min;
  return Math.min(Math.max(Math.round(number), min), max);
}

/** Firestore Timestamp, ISO string or epoch millis → Date (or null). */
function toDate(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate();
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function json(status, payload) {
  return {
    status,
    jsonBody: payload,
    headers: { 'Content-Type': 'application/json' },
  };
}
