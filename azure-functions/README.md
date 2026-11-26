# FamilyPulse — Azure Functions backend

A single HTTP endpoint that answers a question the Flutter client cannot
answer well on its own: **when, in the next N days, is this entire family
free at the same time?**

## Why this exists

FamilyPulse already finds shared free time for *one day*, on-device, in
`lib/services/event_service.dart`. That works because a single day is a small
read and a short scan.

Asking the same question across two weeks is a different problem. It reads
substantially more of the calendar, it runs the scan once per day per member,
and every member of the family would otherwise compute the same answer
independently on their own phone. Moving it server-side makes it one
computation instead of several, keeps the work off low-end devices, and puts
the result somewhere it could later be cached or scheduled.

## Architectural rule

**Firebase stays the system of record.** This service:

- issues no tokens and stores no users — Firebase Auth remains the only identity provider
- owns no data — Cloud Firestore remains the only database
- holds no state of its own between invocations

It verifies the caller's existing Firebase ID token, reads the same documents
the client already reads, computes an answer, and returns it. Azure supplies
compute. Nothing was migrated.

## Security model

Two checks, in this order, before any data is read:

1. **Authentication** — the `Authorization: Bearer <idToken>` header is
   verified by `firebase-admin` against Google's public signing keys. A
   forged, expired or malformed token is rejected with `401`.

2. **Authorisation** — the token's `uid` must exist in
   `families/{familyId}/users`. This matters more than it looks. The Admin SDK
   **bypasses Firestore security rules entirely** — it is trusted by
   definition — so the membership check that rules perform for free on the
   client path has to be re-implemented here by hand. Without it, any
   authenticated FamilyPulse user could read any family's calendar by changing
   one field in the request body. Failure returns `403`.

The service account credential is never committed. It lives in the
`FIREBASE_SERVICE_ACCOUNT` application setting on the Function App, encrypted
at rest by Azure and injected as an environment variable at start-up.

## Endpoint

`POST /api/free-slots`

Request body:

| Field | Type | Default | Notes |
|---|---|---|---|
| `familyId` | string | required | |
| `rangeStartIso` | string | required | UTC instant of day 0's **local** midnight |
| `days` | number | 14 | 1–31 |
| `minDurationMinutes` | number | 60 | 15–720 |
| `dayStartHour` | number | 8 | local hour the day becomes usable |
| `dayEndHour` | number | 22 | local hour it stops being usable |
| `maxResults` | number | 10 | 1–50 |

Response `200`:

```json
{
  "familyId": "abc123",
  "memberCount": 3,
  "query": { "days": 14, "minDurationMinutes": 180, "dayStartHour": 8, "dayEndHour": 22 },
  "scanned": { "events": 37 },
  "slots": [
    { "startIso": "2026-12-01T06:00:00.000Z", "endIso": "2026-12-01T11:00:00.000Z", "durationMinutes": 300, "dayIndex": 5 }
  ]
}
```

| Status | Meaning |
|---|---|
| `400` | Malformed body, missing `familyId`, or unparseable `rangeStartIso` |
| `401` | No bearer token, or the token failed verification |
| `403` | Valid token, but the caller is not a member of that family |
| `404` | The family exists but has no members |

Results are ranked longest-first, ties broken soonest-first, then truncated to
`maxResults` — truncation happens *after* ranking, so a short window early in
the range never displaces a long one later.

Timezone handling is deliberately client-side: the caller sends the absolute
instant of day 0's local midnight and the server offsets from there. The known
limitation is a DST transition inside the range, which would shift later days
by one hour.

## Local development

```bash
npm install
npm test     # 8 unit tests — no Azure, no Firebase, no network
func start   # requires Azure Functions Core Tools v4
```

The slot algorithm is pure arithmetic over dates with no I/O, which is why it
lives in `src/lib/slots.js` apart from the HTTP handler — it can be tested
exhaustively without mocking Firestore.

## Infrastructure

| | |
|---|---|
| Resource group | `familypulse-ne` |
| Region | Norway East |
| Plan | Flex Consumption |
| Runtime | Node on Functions v4 |
| Storage | `fpstoresznzoj` (Standard_LRS, public blob access disabled) |

Flex Consumption is Microsoft's current recommendation and is available in all
five permitted regions. One consequence: Flex issues no publish profile, so the
GitHub Actions deploy path used for other plans does not work and the function
is published manually pending a service principal with OIDC federation.

Norway East was not a free choice. The subscription carries an **Allowed
resource deployment regions** policy permitting only `belgiumcentral`,
`norwayeast`, `austriaeast`, `switzerlandnorth` and `italynorth`. Azure Static
Web Apps — the original plan for hosting — exists in none of those, which is
why the web client is hosted on Firebase Hosting instead. Azure Functions is
available in all five, so the compute layer stayed on Azure as intended.

## Deployment

Deployed from Azure Cloud Shell, which already has `az`, `func` and `node`
installed — no local toolchain required:

```bash
git clone --branch rex/azure-deployment --depth 1 \
  https://github.com/rex-daworker/family_pulse.git ~/fp
cd ~/fp/azure-functions
cp local.settings.json.example local.settings.json
npm install --omit=dev
func azure functionapp publish familypulse-fn-sznzoj --javascript
```

`local.settings.json` is gitignored because it is where local secrets go, but
Core Tools reads the project's language from it — so a fresh clone fails with
*"Worker runtime cannot be 'None'"* until the file exists. Copying the example
(or passing `--javascript`) resolves it. The file is only consulted locally;
the deployed app reads its settings from Azure configuration.

The service account is set once, separately, and never travels with the code:

```bash
SA=$(python3 -c 'import json,sys;print(json.dumps(json.load(open(sys.argv[1]))))' ./service-account.json)
az functionapp config appsettings set \
  --name familypulse-fn-sznzoj --resource-group familypulse-ne \
  --settings "FIREBASE_SERVICE_ACCOUNT=$SA" -o none
```

CORS must name the web client's origin explicitly, or the browser blocks the
request before it is ever sent — and the resulting console error looks like a
server fault rather than a configuration one:

```bash
az functionapp cors add --name familypulse-fn-sznzoj \
  --resource-group familypulse-ne \
  --allowed-origins https://family-pulse-sznzoj.web.app
```

Verify the deployment rejects anonymous callers:

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
  -X POST https://familypulse-fn-sznzoj.azurewebsites.net/api/free-slots \
  -H "Content-Type: application/json" \
  -d '{"familyId":"x","rangeStartIso":"2026-11-27T00:00:00Z"}'
```

`HTTP 401` is the expected and correct result.
