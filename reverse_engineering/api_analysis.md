# API & data-source analysis

## There is no REST/GraphQL API

The app is **offline-first and fully data-bundled**: every route, stop,
coordinate, schedule, frequency, fare and line colour is compiled into the
Hermes bytecode. No base URL, no endpoint path, no request builder and no
response model exists anywhere in the app modules.

## Network destinations (all library-driven)

| Destination | Library | Purpose |
|---|---|---|
| `*.googleapis.com` (Firestore) | `@react-native-firebase/firestore` | feedback submissions from `FeedbackScreen` |
| `*.google-analytics.com`, `app-measurement.com` | GMS measurement | analytics (on by default) |
| `ssl.gstatic.com`, `play.googleapis.com` | Firebase Installations, Play services | install ids, auth probes |
| Play Store | Play Billing / in-app updates | `com.android.vending.CHECK_LICENSE`, `IAUUpdateKind.IMMEDIATE` |
| OSM/Google tiles | `react-native-maps` | MapScreen tiles |

## Firestore write shape (recovered from `FeedbackScreen`)

```js
addDoc(collection(firestore, 'feedback'), {
  name, email, location, type, comment,
  platform: 'android',
  createdAt: serverTimestamp(),
});
```
`type` ∈ `bug | suggestion | complaint | feature | data | other`
(labelled Bug Report, Suggestion, Complaint, Feature Request,
Route / Stop Data Correction, Other). All five fields are required; `email`
is validated against an address regex and shows
`Enter a valid email address.` inline.

## Legal position

- The Maps platform key is restricted to the original package and signing
  certificate: **not reused**. The rebuild uses OpenStreetMap tiles.
- No Firebase project credentials are embedded; the rebuild posts the same
  payload to `FEEDBACK_ENDPOINT` (see `.env.example`) or no-ops while keeping
  the original visible behaviour.
- No authentication, DRM, pinning or server-side authorisation was bypassed.
