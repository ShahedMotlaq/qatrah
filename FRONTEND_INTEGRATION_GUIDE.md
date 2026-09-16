# Frontend Integration Guide — Qatrah Backend

Everything a web or mobile client needs to integrate with the Daraa Water Management backend:
authentication, the rules behind each endpoint, request and response shapes, realtime updates,
and every error code.

This guide is written from the source code. When it and Swagger disagree, trust Swagger
(it is generated from the running code) and report the difference.

---

## Contents

1. [Environments](#1-environments)
2. [Conventions every request follows](#2-conventions-every-request-follows)
3. [Roles and which app to open](#3-roles-and-which-app-to-open)
4. [Authentication](#4-authentication)
5. [App startup sequence](#5-app-startup-sequence)
6. [Location hierarchy (public)](#6-location-hierarchy-public)
7. [Citizen API](#7-citizen-api)
8. [Staff API (admin and operator)](#8-staff-api-admin-and-operator)
9. [Admin API](#9-admin-api)
10. [Realtime: server-sent events and push](#10-realtime-server-sent-events-and-push)
11. [Enums reference](#11-enums-reference)
12. [Error codes reference](#12-error-codes-reference)
13. [Test-mode notes and known limitations](#13-test-mode-notes-and-known-limitations)
14. [Integration checklist](#14-integration-checklist)

---

## 1. Environments

| Environment | Base URL | Swagger |
|---|---|---|
| Local (Docker) | `http://localhost:8085/api` | `http://localhost:8085/api/swagger-ui.html` |
| Local (`mvn spring-boot:run`) | `http://localhost:8080/api` | `http://localhost:8080/api/swagger-ui.html` |

Every path in this guide is relative to the base URL. `POST /auth/login` means
`POST http://localhost:8085/api/auth/login`.

**OpenAPI spec.** The machine-readable spec is at `{base URL}/v3/api-docs`, for example
`http://localhost:8085/api/v3/api-docs`. You can generate a typed client from it (e.g.
`openapi-typescript` for the web, `openapi-generator` for Dart/Flutter).

**CORS.** Browser origins on `http://localhost:*`, `http://127.0.0.1:*` and `*.daraa.gov.sy`
are allowed, plus anything in the server's `CORS_ORIGINS` setting. Credentials are allowed.
Ask the backend team to add your production origin.

---

## 2. Conventions every request follows

### 2.1 Headers

```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer <accessToken>     # every endpoint not marked Public
```

### 2.2 Dates and times

All timestamps are **ISO-8601 with an offset**, and the server's timezone is `Asia/Damascus`.

```json
"plannedStartAt": "2026-09-14T08:30:00+03:00"
```

When you send a date, always include the offset. Display dates in the user's local time.

### 2.3 Phone numbers

Phone numbers are the login identifier for every account. The server accepts any of these and
stores them as `09XXXXXXXX`:

```
0991234567    991234567    963991234567    +963991234567    00963991234567    +963 991 234 567
```

Anything else (landlines, foreign numbers, old usernames such as `admin`) is rejected with
`400 INVALID_PHONE_NUMBER`. Responses always return the normalised `09XXXXXXXX` form.

### 2.4 Input sanitisation

The server cleans every incoming JSON string before it reaches business logic:

- trims leading and trailing whitespace and collapses repeated spaces;
- converts Arabic-Indic digits (`٠١٢٣٤٥٦٧٨٩`) to ASCII digits.

Fields whose names contain `password`, `token`, `secret` or `key` are **never** changed.
You don't need to pre-clean input, but expect the stored value to differ from what the user
typed. For example, `" ٠٩٩١٢٣٤٥٦٧ "` becomes `"0991234567"`.

### 2.5 Pagination

Endpoints that return `Page<…>` accept:

| Query param | Meaning | Default |
|---|---|---|
| `page` | Zero-based page index | `0` |
| `size` | Items per page (max 2000) | `20` |
| `sort` | `field,asc` or `field,desc`; repeat for multiple fields | endpoint-specific |

Response shape (use these fields; ignore the rest):

```json
{
  "content": [ /* items */ ],
  "totalElements": 134,
  "totalPages": 7,
  "number": 0,
  "size": 20,
  "first": true,
  "last": false,
  "empty": false
}
```

Endpoints that return a plain JSON array (`[...]`) are **not** paginated. This is mostly the
location reference data, which is small.

### 2.6 Error response format

Every error — validation, business rule, security or server — has the same body:

```json
{
  "code": "PHONE_ALREADY_REGISTERED",
  "message": "Phone number is already registered",
  "timestamp": "2026-09-14T00:56:30.056+03:00",
  "path": "/api/auth/citizen/register",
  "details": {}
}
```

**Branch on `code`, never on `message`.** Messages can change wording or language (some are in
Arabic); codes are stable. See [section 12](#12-error-codes-reference) for every code.

For bean-validation failures (`400 VALIDATION_ERROR`), `details` maps each invalid field to its
message:

```json
{
  "code": "VALIDATION_ERROR",
  "message": "Request validation failed",
  "details": { "phoneNumber": "Phone number is required", "password": "Password is required" }
}
```

The one exception is **maintenance mode**. When the server is in maintenance, every endpoint
except `/server-state` and `/app-version` returns `503` with the server-state body instead
(see [5.1](#51-server-state--get-server-state-public)).

### 2.7 Success status codes

| Status | When |
|---|---|
| `200 OK` | Reads, updates, and most commands. |
| `201 Created` | Creating a complaint, a user location, water feedback, or a citizen/operator account (admin). |
| `204 No Content` | Logout, deletes, marking notifications read, device-token registration, operator unit assignment. |

Deleting a unit, neighborhood or zone currently returns `200` with an empty body, while
deleting a region returns `204`. **Treat any `2xx` as success.**

---

## 3. Roles and which app to open

Every account has exactly one role:

| `role` | Who | Client | Signs in with |
|---|---|---|---|
| `CITIZEN` | A member of the public | **Mobile app** (citizen experience) | `/auth/login` |
| `OPERATOR` | Pumping operator, scoped to assigned units | **Mobile app** (operator experience) | `/auth/login` |
| `ADMIN` | The single system administrator | **Web dashboard** | `/auth/admin/login` |

Authentication is split by client:

- **Mobile app** — citizens and operators share one set of auth routes (`/auth/login`,
  `/auth/refresh`, `/auth/logout`). After login, the response's `role` tells the app whether to
  open the citizen or the operator experience.
- **Web dashboard** — the admin has separate routes (`/auth/admin/login`, `/auth/admin/refresh`,
  `/auth/admin/logout`).

Each route only accepts its own roles. An admin using the mobile login, or a citizen or operator
using the admin login, gets `403 LOGIN_CHANNEL_NOT_ALLOWED`. This is checked only after the
password is verified.

The URL prefix tells you who may call an endpoint:

| Prefix | Allowed roles |
|---|---|
| `/auth/login`, `/auth/refresh`, `/auth/admin/login`, `/auth/admin/refresh`, `/auth/citizen/register`, `/auth/citizen/otp/*` | Public |
| `GET /regions`, `/units`, `/neighborhoods`, `/zones`, `/hierarchy` | Public |
| `/app-version`, `/server-state` | Public |
| `/auth/logout` | `CITIZEN`, `OPERATOR` |
| `/auth/admin/logout` | `ADMIN` |
| `/users/me`, `/users/me/profile` | Any signed-in role |
| `/me/**` | `CITIZEN` only |
| `/staff/**` | `ADMIN`, `OPERATOR` |
| `/admin/**` | `ADMIN` only |

Hiding a button in the UI is a convenience, not security: the server enforces every rule
above. A citizen calling a `/staff` route gets `403 FORBIDDEN_OPERATION`.

---

## 4. Authentication

### 4.1 How sessions work

- **Access token** (`token`) is a JWT. Send it as `Authorization: Bearer <token>`. Default lifetime: 30 days.
- **Refresh token** (`refreshToken`) is an opaque string used only to get a new session. Default lifetime: 90 days.
- **Refresh tokens rotate.** Every successful refresh invalidates the refresh token you sent and
  returns a new one. Always store both new values.
- Logout revokes both tokens on the server immediately.

Store tokens securely: Keychain/Keystore on mobile; in memory, or an httpOnly-cookie strategy
you control, on the web.

### 4.2 Auth routes by client

| Action | Mobile app (`CITIZEN`, `OPERATOR`) | Web dashboard (`ADMIN`) |
|---|---|---|
| Log in | `POST /auth/login` | `POST /auth/admin/login` |
| Refresh | `POST /auth/refresh` | `POST /auth/admin/refresh` |
| Log out | `POST /auth/logout` | `POST /auth/admin/logout` |

Requests, responses and error codes are identical on both sides; only the path and the accepted
roles differ. The examples below use the mobile paths. On the web dashboard, add `/admin` after
`/auth`.

### 4.3 Log in — `POST /auth/login` · `POST /auth/admin/login` (Public)

```http
POST /auth/login
Content-Type: application/json

{
  "phoneNumber": "0935966659",
  "password": "secret123"
}
```

**200 OK**

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "type": "Bearer",
  "refreshToken": "q8Zk3...",
  "id": 11,
  "phoneNumber": "0935966659",
  "fullName": "أحمد علي",
  "role": "CITIZEN",
  "profileComplete": false
}
```

| Field | Notes |
|---|---|
| `role` | Mobile: `CITIZEN` → open the citizen experience, `OPERATOR` → open the operator experience. Web: always `ADMIN`. |
| `profileComplete` | `false` for newly registered citizens. Prompt them to complete their profile (see [7.1](#71-profile)). |

**Errors**

| Status | `code` | Meaning |
|---|---|---|
| 400 | `VALIDATION_ERROR` | `phoneNumber` or `password` missing. |
| 400 | `INVALID_PHONE_NUMBER` | Not a Syrian mobile number. |
| 401 | `INVALID_CREDENTIALS` | Wrong password or unknown number. The same code is used for both, deliberately. |
| 401 | `ACCOUNT_DISABLED` | The admin deactivated this account. |
| 403 | `LOGIN_CHANNEL_NOT_ALLOWED` | Correct credentials on the wrong app: an admin on mobile, or a citizen/operator on the web dashboard. Show `message` (e.g. "Admin accounts sign in on the web dashboard"). No session is created. |

### 4.4 Refresh the session — `POST /auth/refresh` · `POST /auth/admin/refresh` (Public)

```http
POST /auth/refresh
Content-Type: application/json

{ "refreshToken": "q8Zk3..." }
```

**200 OK**

```json
{ "token": "eyJhbGci...new", "refreshToken": "Yt71...new", "type": "Bearer" }
```

| Status | `code` | Meaning |
|---|---|---|
| 401 | `INVALID_CREDENTIALS` | The refresh token is expired, revoked, already used, or the account is disabled. Clear the session and go to login. |
| 403 | `LOGIN_CHANNEL_NOT_ALLOWED` | The token belongs to an account from the other app. Clear the session. The token is not consumed. |

#### Recommended client logic

1. Call the API with the access token.
2. If the response is **401 with `code: "UNAUTHENTICATED"`**, call your app's refresh route **once**.
3. If refresh succeeds, store both new tokens and retry the original request once.
4. If refresh fails, clear tokens and go to login.

> **Only one refresh at a time.** Because refresh tokens rotate, two parallel refresh calls
> with the same token means the second one fails and logs the user out. Share one in-flight
> refresh promise across all requests that hit a 401.

```ts
// Mobile: '/auth/refresh'   Web dashboard: '/auth/admin/refresh'
const REFRESH_PATH = '/auth/refresh';
let refreshing: Promise<void> | null = null;

async function refreshOnce() {
  refreshing ??= (async () => {
    const res = await fetch(`${BASE}${REFRESH_PATH}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: store.refreshToken }),
    });
    if (!res.ok) { store.clear(); throw new Error('SESSION_EXPIRED'); }
    const { token, refreshToken } = await res.json();
    store.save(token, refreshToken);
  })().finally(() => { refreshing = null; });
  return refreshing;
}
```

### 4.5 Log out — `POST /auth/logout` (`CITIZEN`, `OPERATOR`) · `POST /auth/admin/logout` (`ADMIN`)

```http
POST /auth/logout
Authorization: Bearer <accessToken>
Content-Type: application/json

{ "refreshToken": "q8Zk3..." }
```

**204 No Content.** Clear local tokens **whether or not** the call succeeds. The refresh token
must belong to the signed-in user, otherwise the server returns `401 INVALID_CREDENTIALS`.

If the device registered a push token, remove it **before** logging out
(see [7.6](#76-notifications)).

### 4.6 Citizen self-registration — `POST /auth/citizen/register` (Public)

Staff accounts are created by the admin. Only citizens can register themselves.

```http
POST /auth/citizen/register
Content-Type: application/json

{
  "phoneNumber": "0935966659",
  "fullName": "أحمد علي",
  "password": "secret123"
}
```

| Field | Rules |
|---|---|
| `phoneNumber` | Required, Syrian mobile. |
| `fullName` | Required. |
| `password` | Required, at least 6 characters. |

**200 OK** returns the same body as login, with `role: "CITIZEN"` and `profileComplete: false`.
The user is signed in immediately.

**Errors:** `400 VALIDATION_ERROR`, `400 INVALID_PHONE_NUMBER`,
`409 PHONE_ALREADY_REGISTERED`, and `400 PHONE_NOT_VERIFIED` if the server requires OTP
(see below).

### 4.7 Phone verification by OTP (Public)

OTP is **optional** today; registration works without it. The flow is in place for when it
becomes mandatory:

```http
POST /auth/citizen/otp/send
{ "phoneNumber": "0935966659" }
```
**200** → `{ "message": "OTP sent", "retry_after": 0 }`

```http
POST /auth/citizen/otp/verify
{ "phoneNumber": "0935966659", "otpCode": "1234" }
```
**200** → `{ "success": true, "message": "تم التحقق بنجاح", "phoneNumber": "0935966659" }`

Then call `/auth/citizen/register` within 5 minutes.

| Status | `code` | Meaning |
|---|---|---|
| 400 | `VALIDATION_ERROR` | `otpCode` must be exactly 4 digits. |
| 409 | `PHONE_BELONGS_TO_STAFF` | Number belongs to an admin or operator account. |
| 403 | `FORBIDDEN_OPERATION` | Number belongs to a deactivated citizen. |
| 429 | `OTP_RATE_LIMITED` | Too many requests. Read the `Retry-After` header (seconds) or `details.retryAfterSeconds`, and disable the resend button until then. |

> **Test mode:** no SMS is sent and **any 4-digit code is accepted**. See [section 13](#13-test-mode-notes-and-known-limitations).

---

## 5. App startup sequence

Run these on every cold start, in order:

```
1. GET /server-state                        → stop here if MAINTENANCE
2. GET /app-version?platform=...&currentBuild=...   (mobile only)
3. Restore tokens → GET /users/me           → 401? try refresh → else login screen
4. Route by role
```

### 5.1 Server state — `GET /server-state` (Public)

```json
{ "status": "OK", "message": "", "retryAfter": 0 }
```

When `status` is `MAINTENANCE`, show `message` and retry after `retryAfter` seconds. Other
endpoints return `503` with this same body while maintenance is on.

### 5.2 App version — `GET /app-version?platform=ANDROID&currentBuild=10400` (Public)

| Param | Values |
|---|---|
| `platform` | `ANDROID` or `IOS` |
| `currentBuild` | The installed app's numeric build number |

```json
{
  "platform": "ANDROID",
  "minimumSupportedBuild": 10400,
  "latestBuild": 10500,
  "latestVersionName": "1.5.0",
  "storeUrl": "https://play.google.com/store/apps/details?id=...",
  "releaseNotes": "…",
  "forceUpdate": false,
  "updateAvailable": true
}
```

- `forceUpdate: true` → block the app and send the user to `storeUrl`.
- `updateAvailable: true` → offer an optional update.
- `404 APP_POLICY_NOT_FOUND` → no policy configured yet. Continue normally.

### 5.3 Current user — `GET /users/me` (Any signed-in role)

```json
{
  "id": 7,
  "fullName": "Operator One",
  "phoneNumber": "0991234567",
  "profileComplete": true,
  "role": "OPERATOR",
  "active": true,
  "assignedUnits": [ { "id": 2, "name": "إزرع", "regionId": 1, "regionName": "درعا", "active": true } ],
  "assignedUnitIds": [2],
  "assignedUnitNames": ["إزرع"],
  "assignedRegionIds": [1],
  "assignedRegionNames": ["درعا"],
  "assignedNeighborhoodIds": [],
  "assignedNeighborhoodNames": [],
  "assignedZoneIds": [],
  "assignedZoneNames": []
}
```

The `assigned*` fields are filled for operators only, and define which units they may manage.

---

## 6. Location hierarchy (public)

Locations form a strict four-level tree:

```
Region (المنطقة) → Unit (الناحية) → Neighborhood (الوحدة الإدارية) → Zone (الحي)
```

**Pumping happens per zone**, and citizens save zones as their locations. All reads below are
public and return plain arrays.

### 6.1 Whole tree — `GET /hierarchy/tree`

Only active nodes whose ancestors are all active are included. Children are sorted by id.

```json
[
  {
    "id": 1, "name": "درعا البلد", "type": "region", "active": true,
    "regionId": null, "regionName": null, "unitId": null, "unitName": null,
    "neighborhoodId": null, "neighborhoodName": null,
    "children": [
      {
        "id": 2, "name": "إزرع", "type": "unit", "active": true,
        "regionId": 1, "regionName": "درعا البلد",
        "children": [
          {
            "id": 3, "name": "إبطع", "type": "neighborhood", "active": true,
            "regionId": 1, "regionName": "درعا البلد", "unitId": 2, "unitName": "إزرع",
            "children": [
              {
                "id": 4, "name": "الحي الغربي", "type": "zone", "active": true,
                "regionId": 1, "regionName": "درعا البلد", "unitId": 2, "unitName": "إزرع",
                "neighborhoodId": 3, "neighborhoodName": "إبطع",
                "children": []
              }
            ]
          }
        ]
      }
    ]
  }
]
```

Load this once per session to build cascading pickers (Region → Unit → Neighborhood → Zone).
It is the cheapest way to get all levels: one request, four queries on the server.

### 6.2 Other hierarchy views

| Endpoint | Returns |
|---|---|
| `GET /hierarchy/flat` | The same nodes as the tree, depth-first, without `children`. |
| `GET /hierarchy/region/{regionId}` | One region's tree (the region itself may be inactive). `404 REGION_NOT_FOUND`. |

### 6.3 Per-level endpoints

| Endpoint | Returns |
|---|---|
| `GET /regions`, `GET /regions/active`, `GET /regions/{id}` | `RegionDto` |
| `GET /units`, `/units/active`, `/units/region/{regionId}`, `/units/region/{regionId}/active`, `/units/{id}` | `UnitDto` |
| `GET /neighborhoods`, `/neighborhoods/active`, `/neighborhoods/unit/{unitId}`, `/neighborhoods/unit/{unitId}/active`, `/neighborhoods/region/{regionId}`, `/neighborhoods/{id}` | `NeighborhoodDto` |
| `GET /zones`, `/zones/active`, `/zones/neighborhood/{id}`, `/zones/neighborhood/{id}/active`, `/zones/unit/{unitId}`, `/zones/region/{regionId}`, `/zones/{id}` | `ZoneDto` |

```json
// RegionDto
{ "id": 1, "name": "درعا البلد", "description": "منطقة درعا البلد", "active": true }

// UnitDto
{ "id": 2, "regionId": 1, "regionName": "درعا البلد", "name": "إزرع", "description": null,
  "active": true, "createdAt": "…", "updatedAt": null }

// NeighborhoodDto
{ "id": 3, "unitId": 2, "unitName": "إزرع", "regionId": 1, "regionName": "درعا البلد",
  "name": "إبطع", "description": null, "active": true, "createdAt": "…", "updatedAt": null }

// ZoneDto
{ "id": 4, "neighborhoodId": 3, "neighborhoodName": "إبطع", "unitId": 2, "unitName": "إزرع",
  "regionId": 1, "regionName": "درعا البلد", "name": "الحي الغربي", "description": null,
  "active": true, "createdAt": "…", "updatedAt": null }
```

Not-found codes: `REGION_NOT_FOUND`, `UNIT_NOT_FOUND`, `NEIGHBORHOOD_NOT_FOUND`, `ZONE_NOT_FOUND`.

---

## 7. Citizen API

Every endpoint here requires a **`CITIZEN`** access token, except `/users/me*`, which any
role may call.

### 7.1 Profile

| Method & path | Body | Response |
|---|---|---|
| `GET /users/me` | — | `UserDto` (see [5.3](#53-current-user--get-usersme-any-signed-in-role)) |
| `PUT /users/me/profile` | `{ "fullName": "أحمد علي" }` | `UserDto` |

Updating the profile sets `profileComplete` to `true`. After registration, send the citizen
through profile completion and then to add their first location.

### 7.2 Saved locations — `/me/locations`

A citizen saves one or more zones (home, work, family). Exactly one is the **default**. Most
citizen features take a `locationId`.

| Method & path | Body | Response |
|---|---|---|
| `GET /me/locations` | — | `UserLocationResponse[]`, default first |
| `POST /me/locations` | `{ "zoneId": 4, "label": "المنزل" }` | **201** `UserLocationResponse` |
| `PUT /me/locations/{id}` | `{ "zoneId": 4, "label": "البيت" }` | `UserLocationResponse` |
| `DELETE /me/locations/{id}` | — | **204** |
| `PATCH /me/locations/{id}/default` | — | `UserLocationResponse` |

```json
// UserLocationResponse
{
  "id": 15,
  "zoneId": 4, "zoneName": "الحي الغربي",
  "neighborhoodId": 3, "neighborhoodName": "إبطع",
  "unitId": 2, "unitName": "إزرع",
  "regionId": 1, "regionName": "درعا البلد",
  "label": "المنزل",
  "isDefault": true
}
```

Rules:

- `label` is required, at most 100 characters.
- A citizen's **first** location automatically becomes the default.
- The same zone can't be saved twice → `409 LOCATION_ALREADY_EXISTS`.
- Deleting the default promotes the oldest remaining location. Re-fetch the list afterwards.
- Another user's location id → `404 LOCATION_NOT_FOUND` (never `403`, so ids can't be probed).
- Unknown zone → `404 ZONE_NOT_FOUND`.

#### Deprecated: `/addresses`

An older alias of the same data, kept only for clients built before `/me/locations`. **Don't use
it in new code**; it will be removed. `CITIZEN` only.

| Method & path | Body | Response |
|---|---|---|
| `GET /addresses` | — | `AddressDto[]` |
| `POST /addresses` | `{ "title": "المنزل", "zoneId": 4 }` | `AddressDto` (**200**, not 201) |
| `PUT /addresses/{id}` | `{ "title": "البيت", "zoneId": 4 }` | `AddressDto` |
| `DELETE /addresses/{id}` | — | **204** |

`title` maps to a location's `label`. `regionId`, `unitId` and `neighborhoodId` are accepted in
the body but ignored; only `zoneId` is used. `AddressDto` has the same hierarchy fields as
`UserLocationResponse`, with `title` instead of `label`, and `createdAt` (currently always `null`).

### 7.3 Pumping timeline for a location

`GET /me/locations/{locationId}/pumping-timeline`

```json
{
  "location": { /* UserLocationResponse */ },
  "current": { /* PumpingRunDto or null — the ACTIVE or PAUSED run */ },
  "next":    { /* PumpingRunDto or null — the next SCHEDULED run */ },
  "recent":  [ /* up to 10 finished runs: COMPLETED, STOPPED, CANCELLED */ ],
  "lastEventId": 812
}
```

```json
// PumpingRunDto (citizen view)
{
  "id": 42, "scheduleId": 6, "zoneId": 4, "zoneName": "الحي الغربي",
  "plannedStartAt": "2026-09-14T08:00:00+03:00",
  "plannedEndAt":   "2026-09-14T11:00:00+03:00",
  "actualStartAt":  "2026-09-14T08:05:12+03:00",
  "actualEndAt":    null,
  "status": "ACTIVE",
  "version": 3,
  "overdue": false,
  "canManage": false,
  "allowedActions": []
}
```

Display suggestions:

| `current.status` | Show |
|---|---|
| `ACTIVE` | "Water is being pumped now". Show `overdue` when it has run past the planned end. |
| `PAUSED` | "Pumping paused". |
| `current` is `null` | Show `next.plannedStartAt` as "Next pumping". |

Keep `lastEventId`; the live stream uses it (see [section 10](#10-realtime-server-sent-events-and-push)).

### 7.4 Water feedback — "did the water arrive?"

| Method & path | Body | Response |
|---|---|---|
| `POST /me/water-feedback` | see below | **201** `WaterFeedbackDto` |
| `PUT /me/water-feedback/{id}` | `{ "feedbackType": "LOW_WATER_LEVEL" }` | `WaterFeedbackDto` |
| `GET /me/water-feedback` | — | `Page<WaterFeedbackDto>` |

```json
// POST body
{ "pumpingRunId": 42, "userLocationId": 15, "feedbackType": "WATER_RECEIVED" }

// WaterFeedbackDto
{
  "id": 90, "pumpingRunId": 42, "userId": 11, "userLocationId": 15,
  "zoneId": 4, "zoneName": "الحي الغربي", "runStatus": "ACTIVE",
  "feedbackType": "WATER_RECEIVED",
  "createdAt": "…", "updatedAt": "…"
}
```

`feedbackType` is one of `WATER_RECEIVED`, `WATER_NOT_RECEIVED` or `LOW_WATER_LEVEL`.

When feedback is accepted:

- while the run is `ACTIVE`, or
- for **24 hours** after a `COMPLETED` or `STOPPED` run ends.

Otherwise the server returns `400 FEEDBACK_WINDOW_CLOSED`. The location's zone must match the
run's zone (`400 FEEDBACK_ZONE_MISMATCH`). Posting again for the same run and location
**replaces** the earlier answer, so a "change my answer" button can simply POST again.

### 7.5 Complaints

| Method & path | Body | Response |
|---|---|---|
| `POST /me/complaints` | see below | **201** `ComplaintDTO` |
| `GET /me/complaints` | — | `Page<ComplaintDTO>`, newest first |
| `GET /me/complaints/{id}` | — | `ComplaintDTO` with `messages` and `statusHistory` |
| `POST /me/complaints/{id}/messages` | `{ "message": "…" }` | `ComplaintDTO` with thread |

```json
// POST /me/complaints
{
  "userLocationId": 15,
  "title": "انقطاع المياه",
  "description": "لم تصل المياه إلى المنزل منذ ثلاثة أيام.",
  "category": "NO_WATER"
}
```

| Field | Rules |
|---|---|
| `userLocationId` | Optional. When omitted, the default location is used; with no default → `404 DEFAULT_LOCATION_NOT_FOUND`. |
| `title` | Required, at most 200 characters. |
| `description` | Required, at most 2000 characters. |
| `category` | Required: `NO_WATER`, `WATER_QUALITY`, `LOW_PRESSURE`, `SCHEDULE_ISSUE`, `OTHER`. |

```json
// ComplaintDTO
{
  "id": 4, "userId": 11, "userLocationId": 15, "zoneId": 4, "zoneName": "الحي الغربي",
  "title": "انقطاع المياه", "description": "…",
  "status": "PENDING", "category": "NO_WATER",
  "createdAt": "…", "updatedAt": "…",
  "messages": [
    { "id": 1, "authorId": 11, "message": "…", "createdAt": "…" }
  ],
  "statusHistory": [
    { "id": 1, "oldStatus": null, "newStatus": "PENDING", "changedBy": 11, "createdAt": "…" }
  ]
}
```

In list responses, `messages` and `statusHistory` are always empty arrays. Fetch the complaint
by id to show its thread. A message from someone other than the citizen (compare `authorId` with
your own `id`) is a staff reply.

### 7.6 Notifications

| Method & path | Body | Response |
|---|---|---|
| `GET /me/notifications` | — | `Page<NotificationDto>`, newest first |
| `GET /me/notifications/unread-count` | — | `{ "count": 3 }` |
| `PATCH /me/notifications/{id}/read` | — | **204** |
| `PATCH /me/notifications/read-all` | — | **204** |
| `POST /me/notifications/device-tokens` | see below | **204** |
| `DELETE /me/notifications/device-tokens?token=<fcmToken>` | — | **204** |

```json
// NotificationDto
{
  "id": 301, "notificationEventId": 88, "pumpingEventId": 812, "runId": 42,
  "type": "PUMPING_STARTED",
  "title": "Pumping started",
  "message": "Pumping started in الحي الغربي",
  "deliveryStatus": "SENT",
  "sentAt": "…", "readAt": null, "createdAt": "…"
}
```

- `type` is a pumping event type (see [11](#11-enums-reference)); use it to pick an icon.
- Unread means `readAt` is `null`.
- A citizen is notified about every pumping event in the zones of their saved locations.

Register the device's Firebase token after login, and again whenever FCM rotates it:

```json
// POST /me/notifications/device-tokens
{
  "token": "fL8pN2exampleToken…",
  "deviceType": "ANDROID",
  "deviceId": "android-357951258741236",
  "deviceInfo": "Samsung A55 | Android 14 | app 1.0.0"
}
```

`deviceType` is `ANDROID`, `IOS` or `WEB`. Registering a token that already exists moves it to
the current user.

---

## 8. Staff API (admin and operator)

Every endpoint here requires an `ADMIN` or `OPERATOR` token.

**Operator scope.** An operator only acts on runs and complaints whose zone belongs to one of
their **assigned units** (`GET /users/me` → `assignedUnitIds`). The admin can act on everything.

### 8.1 How pumping is modelled

- A **pumping schedule** (admin-managed) says *"pump zone X for N minutes, starting at T,
  repeating every D days"*.
- The server turns schedules into **pumping runs**, one per occurrence, up to 30 days ahead.
- Staff operate on **runs**: start, pause, resume, complete, stop, cancel, shift.

Run status transitions:

```
SCHEDULED ──start──▶ ACTIVE ──complete──▶ COMPLETED
    │                 │  ▲
    │               pause resume
    │                 ▼  │
    │               PAUSED
    │                 │
    │        stop (from ACTIVE or PAUSED) ──▶ STOPPED
    │
    └──cancel (admin only)──▶ CANCELLED
```

`COMPLETED`, `STOPPED` and `CANCELLED` are final.

### 8.2 List runs — `GET /staff/pumping-runs`

| Query | Meaning |
|---|---|
| `zoneId` | Optional zone filter. |
| `page`, `size`, `sort` | See [2.5](#25-pagination). |

Returns `Page<PumpingRunDto>`. The staff view adds `neighborhood*`, `unit*` and `region*`
fields and, most importantly:

```json
{
  "id": 42,
  "status": "SCHEDULED",
  "version": 0,
  "overdue": false,
  "canManage": true,
  "allowedActions": ["START", "SHIFT"]
}
```

> **Drive the UI from `allowedActions`.** Show a button only when its action is listed. The
> server computes the list from the caller's role, unit scope, the run status and the operator
> time window, so the client never has to reimplement those rules.

| Status | Admin may | Operator (in scope) may |
|---|---|---|
| `SCHEDULED` | `START`, `CANCEL`, `SHIFT` | `START` (only inside the start window), `SHIFT` |
| `ACTIVE` | `PAUSE`, `STOP`, `COMPLETE`, `SHIFT` | same |
| `PAUSED` | `RESUME`, `STOP`, `SHIFT` | same |
| Final | — | — |

**Operator start window:** from 60 minutes before `plannedStartAt` until 120 minutes after it.

### 8.3 Run commands

```
POST /staff/pumping-runs/{id}/start
POST /staff/pumping-runs/{id}/pause
POST /staff/pumping-runs/{id}/resume
POST /staff/pumping-runs/{id}/complete
POST /staff/pumping-runs/{id}/stop
POST /staff/pumping-runs/{id}/cancel     (ADMIN only)
```

Body for all of them:

```json
{
  "idempotencyKey": "3f6c2d0e-7a1b-4c55-9e2a-1d4b8f0c9a77",
  "reasonCode": "POWER_OUTAGE",
  "reasonDetails": "انقطاع الكهرباء عن المحطة"
}
```

| Field | Rules |
|---|---|
| `idempotencyKey` | **Required.** Generate a fresh UUID each time the user presses a button, and reuse it when **retrying that same press** after a network failure. |
| `reasonCode` | **Required for `pause` and `stop`.** See [11](#11-enums-reference). |
| `reasonDetails` | Required when `reasonCode` is `OTHER`. Free text. |

**200 OK** returns the updated `PumpingRunDto`. Replace your local copy with it; its `status`,
`version` and `allowedActions` are authoritative.

**Retries are safe.** Sending the same `idempotencyKey` again for the same run and action
performs nothing new and returns the run's current state.

| Status | `code` | Meaning |
|---|---|---|
| 400 | `IDEMPOTENCY_KEY_REQUIRED` | Missing key. |
| 400 | `REASON_REQUIRED` | Pause or stop without `reasonCode`. |
| 400 | `REASON_DETAILS_REQUIRED` | `OTHER` without details. |
| 403 | `FORBIDDEN_OPERATION` | Outside the caller's scope, an operator cancelling, or an operator starting outside the window. |
| 404 | `RUN_NOT_FOUND` | Unknown run. |
| 409 | `ILLEGAL_STATE_TRANSITION` | The run's status doesn't allow this action. Someone else may have changed it; re-fetch. |
| 409 | `IDEMPOTENCY_KEY_REUSED` | Key already used for a different run or action. Generate a new key. |

### 8.4 Shift a run — `POST /staff/pumping-runs/{id}/shift`

Moves one run to a new start time and keeps its duration. The schedule itself is not changed.

```json
{ "plannedStartAt": "2026-09-14T10:00:00+03:00", "idempotencyKey": "b7a0…" }
```

Final runs can't be shifted → `409 ILLEGAL_STATE_TRANSITION`.

### 8.5 Feedback for a run

| Endpoint | Returns |
|---|---|
| `GET /staff/pumping-runs/{runId}/water-feedback` | `Page<WaterFeedbackDto>` |
| `GET /staff/pumping-runs/{runId}/water-feedback/stats` | Totals, below |

```json
{ "total": 57, "counts": { "WATER_RECEIVED": 41, "WATER_NOT_RECEIVED": 9, "LOW_WATER_LEVEL": 7 } }
```

Feedback types nobody has chosen are absent from `counts`; treat missing keys as `0`.

### 8.6 Schedules (read) — `GET /staff/pumping-schedules`

Returns `Page<PumpingScheduleDto>`; see [9.3](#93-pumping-schedules) for the shape.

### 8.7 Complaints (staff)

| Method & path | Body | Response |
|---|---|---|
| `GET /staff/complaints?status=PENDING&category=NO_WATER` | — | `Page<ComplaintDTO>`, newest first. Admin sees all; an operator sees only complaints in assigned units. Both filters are optional. |
| `GET /staff/complaints/{id}` | — | `ComplaintDTO` with thread |
| `PATCH /staff/complaints/{id}/status` | `{ "status": "IN_PROGRESS", "message": "نعمل على الإصلاح" }` | `ComplaintDTO` |
| `POST /staff/complaints/{id}/messages` | `{ "message": "…" }` | `ComplaintDTO` |

`status` is one of `PENDING`, `IN_PROGRESS`, `RESOLVED`, `REJECTED`. The optional `message` is
added to the thread in the same request. An operator with no assigned units, or a complaint
outside their units, gets `403 FORBIDDEN_OPERATION`.

---

## 9. Admin API

Every endpoint here requires an **`ADMIN`** token.

### 9.1 Citizens — `/admin/citizens`

| Method & path | Body | Response |
|---|---|---|
| `GET /admin/citizens` | — | `Page<ManagedUserResponse>`, default sort `id` |
| `GET /admin/citizens/{id}` | — | `ManagedUserResponse` |
| `POST /admin/citizens` | `{ "fullName", "phoneNumber", "password" }` | **201** |
| `PUT /admin/citizens/{id}` | `{ "fullName", "phoneNumber", "password"?, "active" }` | `ManagedUserResponse` |
| `DELETE /admin/citizens/{id}` | — | **204** |

### 9.2 Operators — `/admin/operators`

| Method & path | Body | Response |
|---|---|---|
| `GET /admin/operators` | — | `Page<ManagedUserResponse>` |
| `GET /admin/operators/{id}` | — | `ManagedUserResponse` |
| `POST /admin/operators` | `{ "fullName", "phoneNumber", "password" }` | **201** |
| `PUT /admin/operators/{id}` | `{ "fullName", "phoneNumber", "password"?, "active" }` | `ManagedUserResponse` |
| `DELETE /admin/operators/{id}` | — | **204** |
| `PUT /admin/operators/{id}/units` | `{ "unitIds": [2, 5] }` | **204**. Replaces all assignments; `[]` removes them. |

```json
// ManagedUserResponse
{ "id": 7, "phoneNumber": "0991234567", "fullName": "Operator One",
  "role": "OPERATOR", "active": true, "unitIds": [2, 5] }
```

Rules for create and update:

- `password` is at least 6 characters. On update, omit it or send `null` to keep the current one.
- `active` is required on update. `false` disables login immediately.
- Changing the phone number or password, or deactivating the account, **signs the user out of all devices**.
- A phone number already used by another account → `409 PHONE_ALREADY_REGISTERED`.
- Wrong id or wrong role (e.g. a citizen id sent to `/admin/operators`) → `404 CITIZEN_NOT_FOUND` / `OPERATOR_NOT_FOUND`.
- Unknown unit in `unitIds` → `404 UNIT_NOT_FOUND`.

### 9.3 Pumping schedules

| Method & path | Response |
|---|---|
| `POST /admin/pumping-schedules` | `PumpingScheduleDto`. Also creates the first run. |
| `PUT /admin/pumping-schedules/{id}` | `PumpingScheduleDto` |
| `PATCH /admin/pumping-schedules/{id}/disable` | `PumpingScheduleDto` with `active: false`. No new runs are generated. |

```json
// Request (create and update)
{
  "zoneId": 4,
  "firstStartAt": "2026-09-15T08:00:00+03:00",
  "plannedDurationMinutes": 180,
  "recurrenceIntervalDays": 7,
  "recurrenceEndsAt": "2026-12-31T23:59:00+03:00"
}

// Response
{
  "id": 6, "zoneId": 4, "zoneName": "الحي الغربي",
  "neighborhoodId": 3, "neighborhoodName": "إبطع",
  "unitId": 2, "unitName": "إزرع", "regionId": 1, "regionName": "درعا البلد",
  "firstStartAt": "…", "plannedDurationMinutes": 180,
  "recurrenceIntervalDays": 7, "recurrenceEndsAt": "…",
  "active": true, "createdBy": 1, "createdAt": "…", "updatedAt": "…", "version": 0
}
```

| Field | Rules |
|---|---|
| `zoneId`, `firstStartAt`, `plannedDurationMinutes` | Required; duration must be positive. |
| `recurrenceIntervalDays` | Optional. Omit for a one-time schedule. |
| `recurrenceEndsAt` | Optional; needs an interval (`400 RECURRENCE_INTERVAL_REQUIRED`) and must be after `firstStartAt` (`400 INVALID_RECURRENCE_END`). |

Changing the zone of a schedule that already has runs → `409 SCHEDULE_ZONE_IMMUTABLE`. Create a
new schedule instead. Recurring runs are generated hourly, up to 30 days ahead, so new
occurrences can take up to an hour to appear in `/staff/pumping-runs`.

### 9.4 Location master data

`POST`, `PUT` and `DELETE` on `/regions`, `/units`, `/neighborhoods` and `/zones` are admin-only.

| Endpoint | Body |
|---|---|
| `POST /regions` | `{ "name", "description"? }` |
| `PUT /regions/{id}` | `{ "name", "description"?, "active" }` |
| `POST /units` | `{ "regionId", "name", "description"? }` |
| `PUT /units/{id}` | `{ "name", "description"?, "active" }` |
| `POST /neighborhoods` | `{ "unitId", "name", "description"? }` |
| `PUT /neighborhoods/{id}` | `{ "name", "description"?, "active" }` |
| `POST /zones` | `{ "neighborhoodId", "name", "description"? }` |
| `PUT /zones/{id}` | `{ "name", "description"?, "active" }` |
| `DELETE /regions/{id}` | — (**204**) |
| `DELETE /units/{id}` | — (**200**, empty body) |
| `DELETE /neighborhoods/{id}` | — (**200**, empty body) |
| `DELETE /zones/{id}` | — (**200**, empty body) |

Create and update return the saved item: `RegionDto`, `UnitDto`, `NeighborhoodDto` or `ZoneDto`
(see [6.3](#63-per-level-endpoints)).

- New items are created active.
- **Always send `active` on update.** Omitting it fails with `409 DATA_CONFLICT`.
- Names must be unique within their parent: `409 REGION_ALREADY_EXISTS`, `UNIT_ALREADY_EXISTS`,
  `NEIGHBORHOOD_ALREADY_EXISTS`, `ZONE_ALREADY_EXISTS`.
- **Prefer deactivating (`active: false`) over deleting.** Deleting a region removes its whole
  subtree, and deleting anything already used by schedules, runs or citizen locations fails with
  `409 DATA_CONFLICT`.

### 9.5 App releases — `PUT /admin/app-releases/{platform}`

`platform` is `ANDROID` or `IOS`.

```json
{
  "minimumSupportedBuild": 10400,
  "latestBuild": 10500,
  "latestVersionName": "1.5.0",
  "storeUrl": "https://play.google.com/store/apps/details?id=…",
  "releaseNotes": "…"
}
```

Returns `AppVersionResponse`. `minimumSupportedBuild` must not exceed `latestBuild`
(`400 INVALID_BUILD_RANGE`).

### 9.6 Configuration download — `GET /admin/config/download`

Downloads the server configuration with secrets redacted, as YAML. Limited to one download per admin every 30 seconds (`429`).

---

## 10. Realtime: server-sent events and push

### 10.1 Which channel to use

| App state | Channel |
|---|---|
| Citizen app in the foreground, on a location screen | **SSE stream** for that location. |
| App in the background or closed | **FCM push**. |

### 10.2 Opening the stream

```http
GET /me/locations/{locationId}/pumping-stream
Authorization: Bearer <citizenAccessToken>
Accept: text/event-stream
Last-Event-ID: 812            # optional: last event id you processed
```

`?afterEventId=812` works as an alternative to the header.

> **Browsers:** the native `EventSource` can't send an `Authorization` header. Use a
> fetch-based SSE client such as `@microsoft/fetch-event-source`. On Flutter, use a streaming
> HTTP client that sets headers.

### 10.3 Events

| `event` | `id` | `data` | Client action |
|---|---|---|---|
| `snapshot` | — | `PumpingTimelineResponse` (see [7.3](#73-pumping-timeline-for-a-location)) | Replace the whole screen state. Always sent first. |
| `pumping-event` | pumping event id | `PumpingEventPayload` | Update the run with that `runId`. |
| `heartbeat` | — | comment only | Ignore. Sent every 25 seconds to keep proxies open. |
| `resync-required` | — | `{ "reason": "REPLAY_LIMIT_EXCEEDED" }` | You missed more than 200 events. Re-fetch the timeline, then reconnect without `Last-Event-ID`. |

```json
// PumpingEventPayload
{ "eventId": 813, "runId": 42, "zoneId": 4, "status": "PAUSED", "version": 4 }
```

### 10.4 Rules for correct updates

1. **Order by `version`.** Apply a payload only if its `version` is greater than the version you
   hold for that run. Drop stale or duplicate events; delivery is at-least-once.
2. **Payloads are small.** They carry status and version, not times. When status alone isn't
   enough (for example after a shift), re-fetch `GET /me/locations/{id}/pumping-timeline`.
3. **Reconnect.** The server closes streams after 30 minutes, and networks drop. Reconnect with
   `Last-Event-ID` set to the last `id` you processed, and missed events are replayed.
4. **Close the stream** when the screen closes, to save battery and server resources.

### 10.5 FCM push payload

Push notifications include a visible `title` and `body` plus these data keys (all strings):

| Key | Example |
|---|---|
| `eventId` | `"813"` |
| `runId` | `"42"` |
| `zoneId` | `"4"` |
| `status` | `"PAUSED"` |
| `version` | `"4"` |

When the user taps the notification, open the location whose zone is `zoneId` and load its
timeline.

---

## 11. Enums reference

| Enum | Values |
|---|---|
| User role | `ADMIN`, `OPERATOR`, `CITIZEN` |
| Run status | `SCHEDULED`, `ACTIVE`, `PAUSED`, `COMPLETED`, `STOPPED`, `CANCELLED` |
| Run action (`allowedActions`) | `START`, `PAUSE`, `RESUME`, `STOP`, `COMPLETE`, `CANCEL`, `SHIFT` |
| Pause/stop reason (`reasonCode`) | `TECHNICAL_FAILURE`, `POWER_OUTAGE`, `MAINTENANCE`, `OPERATOR_DECISION`, `EMERGENCY`, `OTHER` |
| Pumping event / notification `type` | `PUMPING_STARTED`, `PUMPING_PAUSED`, `PUMPING_RESUMED`, `PUMPING_STOPPED`, `PUMPING_COMPLETED`, `PUMPING_CANCELLED`, `RUN_SHIFTED` |
| Water feedback | `WATER_RECEIVED`, `WATER_NOT_RECEIVED`, `LOW_WATER_LEVEL` |
| Complaint status | `PENDING`, `IN_PROGRESS`, `RESOLVED`, `REJECTED` |
| Complaint category | `NO_WATER`, `WATER_QUALITY`, `LOW_PRESSURE`, `SCHEDULE_ISSUE`, `OTHER` |
| Notification delivery | `PENDING`, `SENT`, `FAILED` |
| Device type | `ANDROID`, `IOS`, `WEB` |
| App platform | `ANDROID`, `IOS` |
| Server state | `OK`, `MAINTENANCE` |
| Hierarchy node `type` | `region`, `unit`, `neighborhood`, `zone` (lowercase) |

Suggested Arabic labels:

| Value | Label |
|---|---|
| `SCHEDULED` / `ACTIVE` / `PAUSED` | مجدول / قيد الضخ / متوقف مؤقتاً |
| `COMPLETED` / `STOPPED` / `CANCELLED` | مكتمل / متوقف / ملغى |
| `WATER_RECEIVED` / `WATER_NOT_RECEIVED` / `LOW_WATER_LEVEL` | وصلت المياه / لم تصل المياه / وصلت بمستوى منخفض |
| `PENDING` / `IN_PROGRESS` / `RESOLVED` / `REJECTED` | قيد الانتظار / قيد المعالجة / تم الحل / مرفوضة |
| `NO_WATER` / `WATER_QUALITY` / `LOW_PRESSURE` / `SCHEDULE_ISSUE` / `OTHER` | عدم وصول المياه / جودة المياه / ضغط منخفض / مشكلة في الجدول / أخرى |
| `TECHNICAL_FAILURE` / `POWER_OUTAGE` / `MAINTENANCE` / `OPERATOR_DECISION` / `EMERGENCY` | عطل فني / انقطاع كهرباء / صيانة / قرار المشغل / طارئ |

---

## 12. Error codes reference

### Authentication and access

| HTTP | `code` | Meaning / client action |
|---|---|---|
| 401 | `UNAUTHENTICATED` | Missing, expired or revoked access token. Try refresh once, then login. |
| 401 | `INVALID_CREDENTIALS` | Wrong phone or password, or an invalid refresh token. |
| 401 | `ACCOUNT_DISABLED` | The admin disabled the account. |
| 403 | `FORBIDDEN_OPERATION` | Role or scope doesn't allow this action. Don't retry. |
| 403 | `LOGIN_CHANNEL_NOT_ALLOWED` | Correct credentials on the wrong app (admin on mobile, citizen/operator on web). Tell the user which app to use. |

### Validation (400)

| `code` | Meaning |
|---|---|
| `VALIDATION_ERROR` | Field errors; see `details`. |
| `PHONE_NUMBER_REQUIRED` | Empty phone number. |
| `INVALID_PHONE_NUMBER` | Not a Syrian mobile number. |
| `OTP_CODE_REQUIRED`, `INVALID_OTP_CODE` | Bad OTP input. |
| `PHONE_NOT_VERIFIED` | Registration requires OTP verification first. |
| `IDEMPOTENCY_KEY_REQUIRED` | Run command without a key. |
| `REASON_REQUIRED`, `REASON_DETAILS_REQUIRED` | Pause/stop reason missing. |
| `PLANNED_START_REQUIRED` | Shift without `plannedStartAt`. |
| `FEEDBACK_ZONE_MISMATCH`, `FEEDBACK_WINDOW_CLOSED` | Feedback not allowed. |
| `RECURRENCE_INTERVAL_REQUIRED`, `INVALID_RECURRENCE_END` | Invalid schedule recurrence. |
| `INVALID_BUILD`, `INVALID_BUILD_RANGE` | Invalid app version values. |
| `BAD_REQUEST` | Malformed JSON, or a wrong type in a path or query parameter. |

### Not found (404)

`USER_NOT_FOUND`, `CITIZEN_NOT_FOUND`, `OPERATOR_NOT_FOUND`, `REGION_NOT_FOUND`,
`UNIT_NOT_FOUND`, `NEIGHBORHOOD_NOT_FOUND`, `ZONE_NOT_FOUND`, `LOCATION_NOT_FOUND`,
`DEFAULT_LOCATION_NOT_FOUND`, `RUN_NOT_FOUND`, `SCHEDULE_NOT_FOUND`, `COMPLAINT_NOT_FOUND`,
`FEEDBACK_NOT_FOUND`, `NOTIFICATION_NOT_FOUND`, `APP_POLICY_NOT_FOUND`, and `NOT_FOUND` for an
unknown URL.

### Conflict (409)

| `code` | Meaning |
|---|---|
| `PHONE_ALREADY_REGISTERED` | Phone number in use. |
| `PHONE_BELONGS_TO_STAFF` | OTP requested for a staff number. |
| `LOCATION_ALREADY_EXISTS` | Zone already saved by this citizen. |
| `REGION_ALREADY_EXISTS`, `UNIT_ALREADY_EXISTS`, `NEIGHBORHOOD_ALREADY_EXISTS`, `ZONE_ALREADY_EXISTS` | Duplicate name in the same parent. |
| `ILLEGAL_STATE_TRANSITION` | Run status doesn't allow the action. Re-fetch. |
| `IDEMPOTENCY_KEY_REUSED` | Key used for another command. |
| `SCHEDULE_ZONE_IMMUTABLE` | Can't move a schedule that already has runs. |
| `DATA_CONFLICT` | A database rule rejected the write (duplicate, in-use record, or missing required value). |

### Other

| HTTP | `code` | Meaning |
|---|---|---|
| 405 | `METHOD_NOT_ALLOWED` | Wrong HTTP method. |
| 415 | `UNSUPPORTED_MEDIA_TYPE` | Missing `Content-Type: application/json`. |
| 429 | `OTP_RATE_LIMITED` | Wait `Retry-After` seconds. |
| 429 | `HTTP_ERROR` | Config download rate limit. |
| 500 | `INTERNAL_ERROR` | Server bug. Show a generic error and report it with the `timestamp` and `path`. |
| 503 | — | Maintenance mode; the body is `ServerStateResponse`. |

---

## 13. Test-mode notes and known limitations

These apply to the current test environment and **will change**. Don't build permanent
behaviour on them.

- **OTP is not real yet.** No SMS is sent, and any 4-digit code passes verification. Registration
  doesn't require OTP (`AUTH_REGISTRATION_REQUIRE_OTP=false`). Build the OTP screens anyway;
  they will become mandatory.
- **Seed admin.** Local environments create one admin from `SEED_ADMIN_PHONE` and
  `ADMIN_PASSWORD` in the backend's `.env`. Ask the backend team for test credentials. There is
  exactly one admin.
- **Only regions are seeded.** Create units, neighborhoods, zones and schedules through the admin
  API before testing citizen flows.
- **Access tokens last 30 days** by default. Still implement refresh from day one.
- **Staff don't have an in-app notification inbox.** `/me/notifications` is citizen-only.
- **Location reference lists aren't paginated.** Cache them per session.
- **Delete status codes are inconsistent** (`200` vs `204`); treat any `2xx` as success.

---

## 14. Integration checklist

**Every app**
- [ ] Base URL is configurable per environment.
- [ ] Errors are handled by `code`, not `message`.
- [ ] Startup: `/server-state` → `/app-version` (mobile) → `/users/me`.
- [ ] Mobile app: one login screen calling `POST /auth/login`, opening the citizen or operator experience by `role`.
- [ ] Web dashboard: login calling `POST /auth/admin/login`, refresh and logout on `/auth/admin/*`.
- [ ] `403 LOGIN_CHANNEL_NOT_ALLOWED` shown as "use the other app", not as a wrong password.
- [ ] Single-flight refresh on `401 UNAUTHENTICATED`; both tokens replaced on success.
- [ ] Logout removes the FCM token (mobile), calls the app's logout route, clears storage.
- [ ] Phone input accepts local and international formats.
- [ ] Dates sent with an offset and displayed in local time.

**Citizen app**
- [ ] Registration → profile completion → add first location.
- [ ] Cascading zone picker built from `GET /hierarchy/tree`.
- [ ] Location list with default switching.
- [ ] Timeline screen plus SSE stream with `Last-Event-ID` reconnect and version ordering.
- [ ] Water feedback shown only while the run is active or recently finished.
- [ ] Complaints list, create, and thread.
- [ ] Notifications inbox, unread badge, FCM token registration.

**Staff app**
- [ ] Runs list filtered by zone, with action buttons driven by `allowedActions`.
- [ ] UUID `idempotencyKey` per button press, reused only on retry.
- [ ] Reason picker for pause and stop; details field for `OTHER`.
- [ ] Complaints queue with status changes and replies.
- [ ] Admin screens: citizens, operators and unit assignment, schedules, location master data, app releases.
