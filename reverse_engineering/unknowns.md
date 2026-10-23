# Unknowns, inferences and gaps

## Inferred (implemented, flagged)
1. **Schedule header colour** — `activeCategory?.color ?? colors.primary`.
   hermes-dec renders the null check with inverted polarity (`if (r5) goto …`
   where r5 is the always-truthy category object).
2. **`waitMinutesFrom` / `walkMinutesFor` / `estimateTravelMinutes` /
   `addMinutes` / `minutesOfDay` / `timeToMinutes` / `formatDeparture`** —
   Hermes inlined these and hermes-dec emits empty bodies. Implemented from the
   recovered constants: 80 m/min, 2 min/stop, one departure per
   `parseFrequencyMinutes` inside operating hours.
3. **`formatDeparture` signature** — recovered as `(timeOfDay, minutesAway)`
   from its single call site in `getNextDepartures`.
4. **CreditsScreen reachability** — route registered but never pushed. The
   rebuild exposes it from Settings → Help & Support; this is a deliberate
   deviation, documented in the README.
5. **`RouteDetailScreen` / `StopDetailScreen` exact paddings** — several values
   come from the recovered token scale rather than a measurement, because a few
   computed accessors are elided by hermes-dec.
6. **`Route not found` guard** — RouteDetail shows the guard, but the exact
   error-screen layout below it is not recoverable; an `EmptyState` is used.

## Unrecoverable
1. **The native runtime** — `lib/*.so` is in the ABI split, not in the base APK,
   so the app cannot be installed or screenshotted here. No visual baseline
   could be captured.
2. **Pairip-protected code paths** — deliberately untouched.
3. **Analytics / install-referrer payloads** — excluded by design.
4. **The original signing key** — not present, not needed.
5. **`google/protobuf`, `kotlin/`, `google/firebase` resources** — library data,
   no app behaviour attached.

## Deliberate design deviations
1. OpenStreetMap instead of the Maps key (legal necessity).
2. Firestore → `FEEDBACK_ENDPOINT` (no credentials in source).
3. Notification permission: retained in the manifest, requested at bootstrap as
   in the original.
4. `README` documents these; nothing was silently changed.
