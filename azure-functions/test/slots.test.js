'use strict';

const test = require('node:test');
const assert = require('node:assert');
const { findFreeSlotsForDay, findFreeSlotsInRange } = require('../src/lib/slots');

const DAY0 = new Date('2026-12-01T00:00:00.000Z');
const at = (dayIndex, hour, minute = 0) =>
  new Date(DAY0.getTime() + dayIndex * 86400000 + hour * 3600000 + minute * 60000);

const busy = (userId, dayIndex, fromHour, toHour) => ({
  userId,
  start: at(dayIndex, fromHour),
  end: at(dayIndex, toHour),
});

test('an empty calendar is one long free window', () => {
  const slots = findFreeSlotsForDay({
    events: [],
    memberIds: ['a', 'b'],
    dayStart: at(0, 8),
    dayEnd: at(0, 22),
    minDurationMinutes: 60,
  });

  assert.equal(slots.length, 1);
  assert.equal(slots[0].durationMinutes, 14 * 60);
});

test('one member busy blocks the window for everyone', () => {
  const slots = findFreeSlotsForDay({
    events: [busy('a', 0, 12, 14)],
    memberIds: ['a', 'b'],
    dayStart: at(0, 8),
    dayEnd: at(0, 22),
    minDurationMinutes: 60,
  });

  assert.equal(slots.length, 2);
  assert.equal(slots[0].durationMinutes, 4 * 60); // 08:00–12:00
  assert.equal(slots[1].durationMinutes, 8 * 60); // 14:00–22:00
});

test('windows shorter than the minimum are discarded', () => {
  const slots = findFreeSlotsForDay({
    events: [busy('a', 0, 9, 21)],
    memberIds: ['a'],
    dayStart: at(0, 8),
    dayEnd: at(0, 22),
    minDurationMinutes: 90,
  });

  // 08:00–09:00 and 21:00–22:00 both exist but are only 60 minutes each.
  assert.equal(slots.length, 0);
});

test('a member with no events is still required to be free', () => {
  const slots = findFreeSlotsForDay({
    events: [busy('a', 0, 8, 22)],
    memberIds: ['a', 'b', 'c'],
    dayStart: at(0, 8),
    dayEnd: at(0, 22),
    minDurationMinutes: 30,
  });

  assert.equal(slots.length, 0);
});

test('back-to-back events do not invent a gap between them', () => {
  const slots = findFreeSlotsForDay({
    events: [busy('a', 0, 8, 15), busy('b', 0, 15, 22)],
    memberIds: ['a', 'b'],
    dayStart: at(0, 8),
    dayEnd: at(0, 22),
    minDurationMinutes: 30,
  });

  assert.equal(slots.length, 0);
});

test('the range search spans days and ranks longest first', () => {
  const events = [
    busy('a', 0, 8, 20), // day 0 almost gone
    busy('a', 1, 8, 12), // day 1 free from midday
    // day 2 completely free
  ];

  const slots = findFreeSlotsInRange({
    events,
    memberIds: ['a', 'b'],
    rangeStart: DAY0,
    days: 3,
    dayStartHour: 8,
    dayEndHour: 22,
    minDurationMinutes: 60,
  });

  assert.equal(slots[0].dayIndex, 2);
  assert.equal(slots[0].durationMinutes, 14 * 60);
  assert.equal(slots[1].dayIndex, 1);
  assert.equal(slots[1].durationMinutes, 10 * 60);
});

test('equal-length windows are ranked soonest first', () => {
  const slots = findFreeSlotsInRange({
    events: [],
    memberIds: ['a'],
    rangeStart: DAY0,
    days: 3,
    minDurationMinutes: 60,
  });

  assert.deepEqual(
    slots.map((slot) => slot.dayIndex),
    [0, 1, 2],
  );
});

test('maxResults truncates after ranking, not before', () => {
  const slots = findFreeSlotsInRange({
    events: [busy('a', 0, 8, 20)],
    memberIds: ['a'],
    rangeStart: DAY0,
    days: 5,
    minDurationMinutes: 60,
    maxResults: 2,
  });

  assert.equal(slots.length, 2);
  // Day 0's surviving 2-hour sliver must not outrank the full free days.
  assert.ok(slots.every((slot) => slot.durationMinutes === 14 * 60));
});

test('hours that have already passed are not offered as free time', () => {
  // Midday on day 0, searching a day that runs 08:00–22:00.
  const noon = at(0, 12);

  const slots = findFreeSlotsInRange({
    events: [],
    memberIds: ['a'],
    rangeStart: DAY0,
    days: 2,
    dayStartHour: 8,
    dayEndHour: 22,
    minDurationMinutes: 60,
    notBefore: noon,
  });

  const today = slots.filter((slot) => slot.dayIndex === 0);
  assert.equal(today.length, 1);
  assert.equal(today[0].start.getTime(), noon.getTime());
  assert.equal(today[0].durationMinutes, 10 * 60); // 12:00–22:00, not 08:00

  // Tomorrow is untouched.
  const tomorrow = slots.filter((slot) => slot.dayIndex === 1);
  assert.equal(tomorrow[0].durationMinutes, 14 * 60);
});

test('a day already finished is skipped entirely', () => {
  const slots = findFreeSlotsInRange({
    events: [],
    memberIds: ['a'],
    rangeStart: DAY0,
    days: 1,
    dayStartHour: 8,
    dayEndHour: 22,
    minDurationMinutes: 60,
    notBefore: at(0, 23), // 23:00 — the searchable day ended an hour ago
  });

  assert.equal(slots.length, 0);
});
