'use strict';

/**
 * Multi-day shared free-time search.
 *
 * This is a server-side port of EventService.findFreeSlots() in the Flutter
 * client (lib/services/event_service.dart), extended from a single day to an
 * arbitrary range. The single-day version runs on-device because it reads one
 * day of events; scanning two weeks across every family member is a different
 * shape of problem — more documents, more arithmetic, and a result that every
 * member of the family would otherwise recompute independently. That is why it
 * moved to a function.
 *
 * The algorithm itself is deliberately unchanged: walk the day in fixed steps,
 * keep a step if EVERY member is free during it, and collapse consecutive free
 * steps into windows. Keeping it identical means the two implementations agree,
 * which matters — the client still answers "today" locally.
 */

const MS_PER_MINUTE = 60 * 1000;
const MS_PER_DAY = 24 * 60 * MS_PER_MINUTE;

/**
 * Collapse a day into the windows where every member is simultaneously free.
 *
 * @param {object}   args
 * @param {Array}    args.events      [{ userId, start: Date, end: Date }]
 * @param {string[]} args.memberIds   every member who must be free
 * @param {Date}     args.dayStart    inclusive start of the searchable window
 * @param {Date}     args.dayEnd      exclusive end of the searchable window
 * @param {number}   args.minDurationMinutes
 * @param {number}   args.stepMinutes granularity of the scan
 * @returns {Array<{start: Date, end: Date, durationMinutes: number}>}
 */
function findFreeSlotsForDay({
  events,
  memberIds,
  dayStart,
  dayEnd,
  minDurationMinutes = 60,
  stepMinutes = 30,
}) {
  // Busy blocks, bucketed per member. A member with no events gets an empty
  // bucket rather than being absent, so the `every()` below stays honest.
  const busy = new Map(memberIds.map((id) => [id, []]));
  for (const event of events) {
    const bucket = busy.get(event.userId);
    if (bucket) bucket.push(event);
  }

  const slots = [];
  const stepMs = stepMinutes * MS_PER_MINUTE;
  let cursor = dayStart.getTime();
  let windowStart = null;

  while (cursor < dayEnd.getTime()) {
    const stepEnd = cursor + stepMs;

    // Free means: for every member, every one of their events sits entirely
    // before or entirely after this step. Touching endpoints do not collide —
    // an event ending at 14:00 leaves 14:00 free.
    const allFree = memberIds.every((id) =>
      busy.get(id).every(
        (block) =>
          stepEnd <= block.start.getTime() || cursor >= block.end.getTime(),
      ),
    );

    if (allFree) {
      if (windowStart === null) windowStart = cursor;
    } else if (windowStart !== null) {
      pushWindow(slots, windowStart, cursor, minDurationMinutes);
      windowStart = null;
    }

    cursor = stepEnd;
  }

  // A window still open when the day runs out is closed at the day boundary,
  // not at the cursor — the cursor may have overshot dayEnd by one step.
  if (windowStart !== null) {
    pushWindow(slots, windowStart, dayEnd.getTime(), minDurationMinutes);
  }

  return slots;
}

function pushWindow(slots, startMs, endMs, minDurationMinutes) {
  const durationMinutes = Math.round((endMs - startMs) / MS_PER_MINUTE);
  if (durationMinutes >= minDurationMinutes) {
    slots.push({
      start: new Date(startMs),
      end: new Date(endMs),
      durationMinutes,
    });
  }
}

/**
 * Run the day scan across a range of days and rank what comes back.
 *
 * Day boundaries are supplied by the caller as an absolute instant
 * (`rangeStart` = the UTC instant of the first day's local midnight) plus the
 * local hours that bound a usable day. Doing it this way keeps every timezone
 * decision on the client, where the user's actual offset is known, instead of
 * guessing at it server-side. The known limitation is a DST transition inside
 * the range, which would shift later days by an hour; over a two-week horizon
 * in Finland that is a non-issue outside late March and late October.
 *
 * @returns {Array<{start: Date, end: Date, durationMinutes: number, dayIndex: number}>}
 */
function findFreeSlotsInRange({
  events,
  memberIds,
  rangeStart,
  days,
  dayStartHour = 8,
  dayEndHour = 22,
  minDurationMinutes = 60,
  stepMinutes = 30,
  maxResults = 10,
}) {
  const found = [];

  for (let dayIndex = 0; dayIndex < days; dayIndex += 1) {
    const midnight = rangeStart.getTime() + dayIndex * MS_PER_DAY;
    const dayStart = new Date(midnight + dayStartHour * 60 * MS_PER_MINUTE);
    const dayEnd = new Date(midnight + dayEndHour * 60 * MS_PER_MINUTE);

    // Only hand this day the events that could possibly overlap it. Filtering
    // here rather than inside the scan keeps the inner loop cheap when the
    // range is long and the family is busy.
    const dayEvents = events.filter(
      (event) =>
        event.end.getTime() > dayStart.getTime() &&
        event.start.getTime() < dayEnd.getTime(),
    );

    const daySlots = findFreeSlotsForDay({
      events: dayEvents,
      memberIds,
      dayStart,
      dayEnd,
      minDurationMinutes,
      stepMinutes,
    });

    for (const slot of daySlots) found.push({ ...slot, dayIndex });
  }

  // Longest first, and for equal lengths the soonest — a family asking for
  // three free hours wants the biggest gap, but would rather have it this
  // week than next.
  found.sort(
    (a, b) =>
      b.durationMinutes - a.durationMinutes ||
      a.start.getTime() - b.start.getTime(),
  );

  return found.slice(0, maxResults);
}

module.exports = { findFreeSlotsForDay, findFreeSlotsInRange };
