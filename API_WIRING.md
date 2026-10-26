# Wiring this app to the Afro Affinity API

Everything that has to change to take this Flutter app from "screens with
hardcoded lists" to "a working client of the live API". Written 2026-10-26
against API `v0.1.0` and `master` at `0a7d9ff`.

---

## 1. Where the app actually is

Be clear about the starting point, because it is further back than it looks.

| | |
|---|---|
| Dart files | 110 |
| Lines | ~14 600 |
| Screens built | 19 |
| **Calls to any backend** | **one** — a single `.from('profiles')` |

Every screen renders from `const` lists in its own file: `wallet_screen.dart:33`
holds the coin packages, `likes_screen.dart:64` the blurred photos,
`filters_sheet.dart:87-101` the smoking/drinking/relationship options,
`gift_picker.dart:106` the gift suggestions. The UI is real and in good shape.
Nothing behind it is connected.

What *does* work: `Supabase.initialize` in `main.dart`, sign-in, Google
sign-in, and session restore. That is the piece worth keeping, and it is the
piece everything below depends on.

A previous attempt pointed the app at the WordPress plugin instead. It never
worked, was never committed, and now lives on the `wp-attempt` branch. Nothing
in this document refers to it.

## 2. The architecture decision

**Talk to the API, not to Supabase directly.** Supabase stays in the app for
exactly one job: authentication, because it is what mints the JWT the API
expects.

```
  Flutter ──auth──▶ Supabase GoTrue ──JWT──┐
     │                                      ▼
     └──────── HTTPS + Bearer ──────▶ Hono API ──▶ Postgres
```

The reason is not taste. The business rules live in the API and in SQL:
pricing, entitlements, conversation unlocking, the coin ledger, gift economics,
the verification gate. A client that reads tables directly reimplements all of
it in Dart, in a second place, where it will drift. The web app already goes
through the API; the phone should too.

The one exception is **Supabase Realtime for chat**, covered in §7.4 — there is
no HTTP substitute for a live socket.

## 3. Prerequisites

### 3.1 Base URLs

| Environment | API | Supabase |
|---|---|---|
| Production | `https://api.affroafinity.mambandamarket.com` | `https://ymmfduvnwzejrpoqwpmf.supabase.co` |
| Local | `http://localhost:8787` | `http://127.0.0.1:54421` |

The Supabase URL and publishable key are already in
`lib/app/config/auth_config.dart`. They are safe to ship — the publishable key
is public by design and RLS is what protects the data. The API base is not yet
in the app and must be added.

> **Android local dev:** `localhost` on an emulator is the emulator, not your
> Mac. Use `http://10.0.2.2:8787`. iOS Simulator shares the host's loopback and
> can use `localhost` as-is.

### 3.2 Build-time configuration

Replace the hardcoded constants with `--dart-define`, so one binary can target
either environment and no secret is baked in:

```dart
// lib/app/config/api_config.dart  (new)
class ApiConfig {
  const ApiConfig._();
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.affroafinity.mambandamarket.com',
  );
}
```

`.gitignore` already excludes `/config/*.json`, so a `--dart-define-from-file`
setup can live there. Commit a `config/example.json` with the keys and no
values.

### 3.3 CORS — not your problem, but know why

`api/src/app.ts:42` allowlists web origins. A Flutter app sends no `Origin`
header, so CORS never applies. Do not let anyone "fix" CORS to make the app
work; if a request fails it is for another reason.

### 3.4 Dependencies to add

```yaml
dependencies:
  dio: ^5.7.0              # or http; dio gets you interceptors cheaply
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
dev_dependencies:
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
```

Already present and needed: `flutter_riverpod`, `riverpod_annotation`,
`go_router`, `cached_network_image`, `image_picker`, `image_cropper`,
`supabase_flutter`, `google_sign_in`.

### 3.5 Platform configuration

| Platform | Change | Status |
|---|---|---|
| iOS | `platform :ios, '15.0'` + the `post_install` override in `ios/Podfile` | **done** — Xcode 27 refuses anything lower, the app will not build without it |
| iOS | Google sign-in reversed client ID in `Info.plist` | verify before testing sign-in |
| Android | `minSdk` ≥ 23 for `supabase_flutter` | verify |
| Android | OAuth redirect scheme for Google sign-in | verify; the `appAuthRedirectScheme` placeholder on `wp-attempt` was for WordPress and is **not** what this needs |
| Both | No `INTERNET` permission issues — Flutter adds it | — |

---

## 4. The foundation — build this first

Nothing else can be wired until these four exist.

### 4.1 The auth bridge

The API authenticates with `Authorization: Bearer <supabase access token>`.
`api/src/lib/auth.ts:16` validates it by calling `auth.getUser(token)` against
Supabase on every request.

```dart
// lib/core/api/auth_token.dart
String? currentAccessToken() =>
    Supabase.instance.client.auth.currentSession?.accessToken;
```

**The token expires (one hour by default).** `supabase_flutter` refreshes it in
the background, but a request started just before expiry can still arrive
stale. The client must handle a `401` by asking Supabase to refresh and
retrying **once**. Do not retry twice — a genuine 401 loops.

```dart
if (res.statusCode == 401 && !isRetry) {
  await Supabase.instance.client.auth.refreshSession();
  return _send(req, isRetry: true);
}
```

### 4.2 The API client

One class, with the cross-cutting concerns in it so no screen reimplements
them:

- Base URL from `ApiConfig`
- `Authorization` header from §4.1 on every request, omitted when signed out
  (several endpoints are deliberately public — see §5)
- `Content-Type: application/json`
- Timeouts: 15 s connect, 30 s receive. Campay's USSD push is slow.
- 401 → refresh once → retry (§4.1)
- Non-2xx → parse the error envelope (§4.3) and throw `ApiException`
- Network failure → throw a distinguishable `NetworkException`, because
  "you are offline" and "the server said no" are different screens

### 4.3 The error envelope

Every failure from the API has the same shape (`api/src/lib/errors.ts:5`):

```json
{ "error": { "code": "insufficient_coins", "message": "Not enough coins", "details": {} } }
```

The codes the app must handle by name, not by string-matching the message:

| Code | HTTP | Means | What the UI should do |
|---|---|---|---|
| `verification_required` | 403 | not verified, or not `active` | send them to the verification flow |
| `account_restricted` | 403 | suspended or deleted | show the suspended screen; **reads still work, writes do not** |
| `plus_required` | 402 | a paid perk | show the upgrade sheet |
| `insufficient_coins` | 402 | wallet too low | show the top-up sheet |
| `daily_limit` | 402 | like cap reached; `details.cap` has the number | show the cap and the upgrade path |
| `rate_limited` | 429 | too fast | back off, do not hammer |
| `invalid_body` | 422 | zod rejected it; `details` is a flattened field map | show per-field errors |
| `not_found` | 404 | | |
| `conflict` | 409 | unique violation | |
| `forbidden` | 403 | RLS refused | usually a bug — log it |
| `db_error` | 400 | anything else from Postgres | generic failure |

### 4.4 Models

`lib/models/` already has 14 files — `profile.dart`, `conversation.dart`,
`message.dart`, `match.dart`, `gift.dart`, `subscription.dart`,
`coin_package.dart`, `user_profile.dart` and others. **Check each against the
real response before reusing it.** They were written for an earlier shape and
some fields will not match.

Use `freezed` + `json_serializable` and generate from the real payloads rather
than hand-writing `fromJson`. The one rule that matters: **a field the API may
omit must be nullable in Dart**, or the first real response crashes the screen.

---

## 5. The endpoint map

126 routes exist in the source. **Only 70 are in `/openapi.json`** — the spec
at `api/src/routes/docs.ts:128` is hand-maintained and has fallen behind. These
24 member-facing routes are real and undocumented; read the route file, not the
spec:

```
/search                      /searches                 /searches/{id}
/directory                   /friends                  /friends/requests
/friends/requests/{id}/respond                         /friends/{userId}
/winks                       /winks/received           /gifts
/me/albums                   /me/albums/{id}           /me/albums/{id}/photos
/profiles/{username}/albums  /albums/{id}/photos       /me/privacy
/me/username-available       /profile-options          /public-stats
/promos/check                /subscription/redeem      /transfers
/conversations/{id}/continue /likes/{to} (DELETE)      /stories/{slug}/comments/{id}
```

### Public — no token needed

| Endpoint | Use |
|---|---|
| `GET /config` | support contacts, limits. Cache 60 s. |
| `GET /profile-options` | **the option lists for 10 profile fields** — replaces the hardcoded arrays in `filters_sheet.dart`. Shape below. |
| `GET /public-stats` | member count for the landing/splash |
| `GET /online-count` | "N online now" |
| `GET /stories`, `GET /stories/{slug}` | stories and testimonials |
| `GET /profiles/{username}` | a profile card; returns a teaser when signed out |
| `GET /store` | packs, tiers, gifts, prices, payment methods |

**`GET /profile-options` — the exact shape**, because it is the one public
endpoint the app will lean on hardest:

```json
{ "fields": {
    "eye_color": [ { "value": "black", "label_en": "Black", "label_fr": "Noirs" }, … ],
    "hair_color": [ … ], "body_type": [ … ], "marital_status": [ … ],
    "children": [ … ], "income_band": [ … ], "smoker": [ … ],
    "drinker": [ … ], "employment": [ … ], "education": [ … ]
} }
```

A map of field name to option list, ten fields, each option carrying **both
locales**. Send `value` to the API; show `label_en` or `label_fr` by the
member's locale — never the raw value, which renders as `prefer_not_say`.

This is the direct replacement for `filters_sheet.dart:87-101`
(`_smokingOptions`, `_drinkingOptions`, `_relationshipOptions`): `smoker`,
`drinker` and `marital_status` are three of the ten, and the server validates
against the same table, so a hardcoded list that drifts produces a `23514` the
member cannot act on.

### Authenticated

| Endpoint | Method | Notes |
|---|---|---|
| `/me` | GET | the whole self — see §6.1 |
| `/me` | PATCH | edit profile; schema in `routes/me.ts:17` |
| `/me/photos` | PUT | `{ "paths": [...] }`, max 6, each must start `<uid>/` |
| `/me/audio` | PUT | voice prompt path or null |
| `/me/settings` | PATCH | incognito + locale |
| `/me/privacy` | GET, PATCH | the eight privacy controls |
| `/me/complete-onboarding` | POST | validates required fields, moves `onboarding` → `pending` |
| `/me/heartbeat` | POST | presence; call every 60 s while foregrounded |
| `/me/wallet`, `/me/ledger` | GET | balance, earned, history |
| `/me/boost` | POST | spends coins; **requireVerified** |
| `/me/username-available` | GET | works signed-out |
| `/discover` | GET | the deck/grid; query schema at `routes/discover.ts:14` |
| `/search` | POST | full filters; **some are Platinum-only and refused by the DB** |
| `/directory` | GET | A–Z browse, 60/min per IP |
| `/likes` | POST | `{ to, kind: like\|superlike\|pass }` |
| `/likes/{to}` | DELETE | undo |
| `/likes/received`, `/views/received`, `/views/sent` | GET | **blurred without the `see_likes` perk** |
| `/matches` | GET | |
| `/favorites`, `/favorites/{id}` | GET, POST, DELETE | |
| `/blocks`, `/blocks/{id}` | GET, POST, DELETE | |
| `/reports` | POST | reason enum; auto-blocks by default |
| `/friends`, `/friends/requests`, `/friends/{userId}` | GET, POST, DELETE | |
| `/winks`, `/winks/received` | GET, POST | daily cap in SQL |
| `/gifts` | GET | sent and received log |
| `/conversations` | GET | thread list with unread counts |
| `/conversations/unlock` | POST | **free on a match, otherwise costs coins** |
| `/conversations/{id}` | GET | header, `messages_left` in soft gate mode |
| `/conversations/{id}/messages` | GET, POST | keyset paging; attachments must be `<uid>/` |
| `/conversations/{id}/read` | POST | |
| `/conversations/{id}/continue` | POST | lifts the free-message quota, costs coins |
| `/conversations/gift` | POST | opens the thread if needed |
| `/me/albums` + the album routes | all | private albums |
| `/store` | GET | |
| `/orders` | GET, POST | **never send a price** — §7.2 |
| `/subscription`, `/subscription/cancel`, `/subscription/redeem` | | |
| `/transfers` | GET, POST | member-to-member coins; requireVerified |
| `/promos/check` | POST | 20 per 10 min |
| `/payouts` | GET, POST | requireVerified; MoMo `^237[0-9]{9}$` |
| `/verification` | GET, POST | selfie + ID paths |
| `/uploads/sign` | POST | **the only way to upload** — §7.3 |

---

## 6. Screen-by-screen

### 6.1 Splash / session restore — `features/splash`

1. `Supabase.initialize` (already there).
2. Wait for the session to restore before routing. Routing on a half-restored
   session sends a signed-in member to login.
3. `GET /me`.
4. Route on `status` from that response:

| `status` | Where to go |
|---|---|
| `onboarding` | onboarding |
| `pending` | "awaiting review" — they can browse, not interact |
| `active` | discover |
| `suspended` | suspended screen |
| `deleted` | sign out |

`GET /me` returns everything the shell needs in one call
(`routes/me.ts:66-102`): profile, `photos[]` with signed URLs, `wallet
{balance, earned}`, `plus`, `perks{}`, `subscription`, `verification`,
`stats{matches, likes_received}`, `currency`. **Cache it in a Riverpod provider
and invalidate on any mutation** — do not re-fetch per screen.

`perks` is the whole set in one object, so a screen can render a control as
locked rather than only failing on submit. The keys: `incognito`, `see_likes`,
`unlimited_likes`, `free_unlocks`, `advanced_search`.

### 6.2 Auth — `features/auth`

Keep Supabase. `signInWithPassword`, `signUp`, Google via `signInWithIdToken`,
`resetPasswordForEmail`.

**After sign-up the profile already exists** — a Postgres trigger creates it
from `raw_user_meta_data`. Pass `username`, `first_name`, `gender`,
`birth_date`, `locale` in the sign-up metadata and they land on the profile.
Do not POST a profile afterwards.

> `username` is silently dropped if it collides or fails
> `^[a-z0-9_]{3,24}$`. Check `GET /me/username-available` before sign-up and
> show the member the problem, or they get an account with no username and no
> explanation.

Email confirmation is on and **no mail provider is configured** (`/health`
reports `email: false`). Until Resend is wired, accounts must be created with
auto-confirm, or sign-in will fail silently after sign-up. This blocks
real-device testing of the sign-up flow.

### 6.3 Onboarding — `features/onboarding`

- `GET /profile-options` for every option list. **Delete the hardcoded arrays**
  in `filters_sheet.dart:87-101` and anywhere else; the server validates
  against `profile_options` and raises `23514` on anything it does not know, so
  a hardcoded list that drifts produces an error the member cannot act on.
- `PATCH /me` per step (the schema at `routes/me.ts:17` is all-optional, so
  partial saves work).
- `POST /uploads/sign` → upload → `PUT /me/photos` (§7.3).
- `POST /me/complete-onboarding` at the end — it validates and flips the
  status. Nothing else may set `status`.

### 6.4 Discover — `features/discover` (2 120 lines)

`GET /discover`, query per `routes/discover.ts:14`: `min_age`, `max_age`,
`radius_km`, `online`, `interests`, `tribe`, `country`, `city`, `deck`,
`gender`, `verified`, `limit` (max 60), `offset`.

- `deck=true` is the swipe deck; omit it for the grid.
- Swipe right → `POST /likes {to, kind:'like'}`; left → `kind:'pass'`.
- Superlike → `kind:'superlike'`. **It costs coins and can fail with
  `insufficient_coins`** — do not animate the swipe as successful until the
  call returns.
- A mutual like comes back as a match; show the match sheet from the response,
  do not re-fetch.
- `daily_limit` (402) carries `details.cap`. Show that number.
- **Never show distance you computed yourself.** The API returns `distance_km`
  already rounded; exact coordinates are deliberately not exposed (migration
  `0039`).

`filters_sheet.dart` must be rebuilt on `/profile-options` and, for the
Platinum-only filters, on `perks.advanced_search` — the database refuses them
otherwise, so render them locked.

### 6.5 Likes & views — `features/likes`

`GET /likes/received`, `/views/received`, `/views/sent`.

**Without the `see_likes` perk the API returns blurred/redacted rows** — the
blurring is server-side, which is the point. `likes_screen.dart:64`'s
`_blurredPhotos` placeholder list goes away; render what the API sends and show
the upgrade prompt when `perks.see_likes` is false.

### 6.6 Matches & chat — `features/matches`, `features/chat` (1 314 lines)

1. `GET /matches`.
2. `GET /conversations` — thread list, other party, unread counts.
3. Opening a thread that does not exist yet → `POST /conversations/unlock
   {to}`. **Free on a match; otherwise it spends `pricing.unlock_coins`.** The
   response carries `{conversation_id, charged, balance}` — show `charged` if
   it is non-zero, people notice silent spending.
4. `GET /conversations/{id}/messages` — keyset paging with `before`, not
   offset.
5. `POST /conversations/{id}/messages` — body, or an attachment path (§7.3).
6. `POST /conversations/{id}/read` on open and on each new message.
7. Soft gate mode: `GET /conversations/{id}` returns `messages_left`. At zero,
   `POST /conversations/{id}/continue` to pay for more.

Realtime: see §7.4.

### 6.7 Wallet & store — `features/wallet` (1 153 lines), `features/premium`

**`wallet_screen.dart:33`'s `_packages` list must go.** `GET /store` returns
packs, tiers, gifts, pricing settings, the available payment `methods` for the
member's currency, and whether each is `simulated`.

Buying:

```
POST /orders  { kind:'coins'|'plan', item_code, period?, momo_number?, method?, coins?, promo? }
```

**Never send a price.** `quote_coins` derives it server-side from the same grid
the app was quoted from; a price in the body is ignored at best.

- Mobile money: `momo_number` must match `^237[0-9]{9}$`. The response is a
  pending order; the USSD push happens on the handset. **Poll `GET
  /orders/{id}` until `status` leaves `pending`** — there is no push yet.
- Cards: the response carries a checkout URL to open in a browser.
- `GET /store` → `methods[].simulated` tells you payments are in sandbox.
  **Surface that in the UI during testing**; `/health` currently reports
  `momo:false, cards:false` and both providers simulating.

`GET /me/ledger` for history, `GET /me/wallet` for the balance.

### 6.8 Feed & gifts — `features/feed` (1 750 lines), `features/gifts`

The feed has **no endpoint**. See §9 — this is a gap, not an oversight on your
part.

Gifts: `GET /store` for the catalogue (drop `gift_picker.dart:106`'s
`_suggestions`), `POST /conversations/gift {to, code, note?}` to send, `GET
/gifts` for the log.

### 6.9 Profile — `features/profile`

`GET /me` / `PATCH /me`; photos per §7.3; `/me/albums*` for albums;
`/me/privacy` for the eight controls; `/me/settings` for incognito and locale.

**Incognito is a paid perk and is no longer a writable column** (migration
`0039`). `PATCH /me/settings {incognito:true}` returns `402 plus_required`
without it. Turning it *off* always works.

### 6.10 Settings — `features/settings`

`PATCH /me/settings` (locale), `/me/privacy`, `POST /verification`, `DELETE
/me` (soft delete), sign out via Supabase.

---

## 7. Rules the app must respect

### 7.1 The verification gate

`requireVerified` guards **every member-to-member action**: likes, messages,
gifts, winks, friend requests, boosts, transfers, payouts, album writes, story
comments. It needs `verified_at` set **and** `status = 'active'`.

Browsing is not gated. So the correct shape is: let an unverified member look
around, and render every interactive control as locked with a route into the
verification flow. Do not discover this with a 403 after they tap.

### 7.2 Money is decided by the server

Prices, discounts, coin costs and payout rates are all server-side. The app's
job is to *display* what `/store` returns and *send* an item code. Anything
else is a bug waiting for someone to patch the APK.

### 7.3 Uploads — the only correct sequence

1. `POST /uploads/sign { bucket, ext }` → `{ path, token/signedUrl }`
2. Upload the bytes to that URL
3. Send the **path** to the owning endpoint — `PUT /me/photos`, `POST
   /verification`, `POST /conversations/{id}/messages`

Buckets: `photos`, `avatars` (public); `albums`, `audio-prompts`,
`chat-attachments`, `verification` (private, served as signed URLs);
`story-media` (admin only).

**Every path must start `<uid>/`.** Storage policies enforce it and every
route re-checks it. Max 6 photos per member — trigger-enforced, the seventh
raises.

### 7.4 Realtime chat

HTTP polling is not acceptable for chat. Subscribe with the Supabase client to
`messages` filtered by `thread_id`.

**The socket must be authenticated after the session restores.** An anonymous
socket passes RLS as nobody and silently delivers zero rows — no error, just a
chat that never updates:

```dart
await Supabase.instance.client.realtime.setAuth(session.accessToken);
```

Re-call it after every token refresh. `conversations` and `messages` are both
in the `supabase_realtime` publication; nothing else is.

De-duplicate: the sender's own insert comes back over the socket, so a message
appended optimistically will arrive twice unless you check the id.

### 7.5 Rate limits

`POST /likes` 60/min, `/orders` 5/10min, `/transfers` 10/hr, `/payouts` 3/day,
`/promos/check` 20/10min, `/directory` 60/min. Handle `429` with backoff rather
than a red error.

### 7.6 Presence

`POST /me/heartbeat` every 60 s **while the app is foregrounded only**. Stop it
on background or every member reads as permanently online.

---

## 8. Suggested order

1. **Foundation** (§4) — client, auth bridge, errors, one model. Prove it with
   `GET /config` and `GET /me`.
2. **Splash + auth + routing on `status`** (§6.1, §6.2).
3. **Onboarding** (§6.3) — needed to create a testable account.
4. **Discover** (§6.4) — the core loop, and the biggest screen.
5. **Likes/matches/chat** (§6.5, §6.6) including realtime.
6. **Profile + photos + verification** (§6.9, §7.3).
7. **Wallet/store** (§6.7).
8. **Friends, winks, favourites, blocks, reports, albums.**
9. **Feed** — only after §9 is resolved.

## 9. Gaps the app will hit, which are not the app's fault

| Gap | Effect |
|---|---|
| **No feed endpoint** | `features/feed` is 1 750 lines against an API that has nothing to serve it. The old WP site had `wp_dsp_news_feed` (1 717 rows). Either build the endpoint or cut the screen — do not fake it. |
| **No push notifications** | `/health` reports `push:false`. `notification_service.dart` has nothing to talk to. New messages arrive only while the app is open. |
| **No email** | `email:false`. Sign-up confirmation, password reset and receipts do not send. Blocks real-device testing of sign-up. |
| **Payments are simulated** | `momo:false, cards:false`, both providers simulating. Checkout will "succeed" without charging. Label it in the UI during testing. |
| **OpenAPI is 56 routes behind** | §5. Read the route source. |
| **No members yet** | The API has 53 demo accounts. The 537 real WordPress members have **not been imported** — that is a separate project. Discover will look empty, and that is correct, not a bug in your wiring. |
| **Campay webhook is forgeable** | Known, documented, not exploitable while payments are off. Must be fixed before live payments. |

## 10. How to know it works

- `GET /config` returns 200 with no token → the client and base URL are right.
- `GET /me` with a token returns the profile → the auth bridge works.
- `GET /me` with a **deliberately expired** token returns 200 after one silent
  refresh → §4.1 works. This is the one most likely to be broken and the least
  likely to be noticed, because it only shows up an hour in.
- An unverified account browsing Discover sees members; every action control is
  locked, and nothing returns 403 by surprise.
- A superlike with an empty wallet shows the top-up sheet, and **no swipe
  animation plays**.
- Two devices, two accounts, one thread: a message appears on the other device
  without a refresh, exactly once.
- Airplane mode shows "you are offline", not "something went wrong".
- `flutter analyze` clean; the app builds for both platforms.

## 11. Reference

- API source: `~/Documents/afroaffinity/api/src/routes/*.ts` — **authoritative**
- Mount prefixes: `~/Documents/afroaffinity/api/src/app.ts:55-73`
- Request schemas: the `z.object` at the top of each route file
- Error codes: `~/Documents/afroaffinity/api/src/lib/errors.ts`
- Entitlements: `~/Documents/afroaffinity/api/src/lib/entitlements.ts`
- Schema and RLS: `~/Documents/afroaffinity/db/migrations/` (0001–0039)
- Spec (incomplete): `https://api.affroafinity.mambandamarket.com/openapi.json`
- Browsable docs: `https://api.affroafinity.mambandamarket.com/docs`
- Health: `https://api.affroafinity.mambandamarket.com/health`
