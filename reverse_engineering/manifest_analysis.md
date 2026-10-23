# AndroidManifest analysis

## Application element
| Attribute | Value | Note |
|---|---|---|
| package / applicationId | `com.codez.lahoreelectricbusguide` | |
| `android:name` | `com.pairip.application.Application` | **Play Pairip integrity wrapper** |
| label / icon | `Lahore Speedo Bus Guide` / `@mipmap/ic_launcher` | roundIcon also set |
| theme | `@style/AppTheme` = `Theme.AppCompat.DayNight.NoActionBar` | plus `windowIsTranslucent=true`, `forceDarkAllowed=false`, `editTextBackground=@drawable/rn_edit_text_material` |
| allowBackup | `false` | |
| supportsRtl | `true` | |
| usesCleartextTraffic | `false` | HTTPS only |
| appComponentFactory | `androidx.core.app.CoreComponentFactory` | |
| requiredSplitTypes | `base__abi, base__density` | this base APK has no `lib/`; the native libs ship in the ABI split |

## Components
- **Activities (app)**: `MainActivity` — `com.facebook.react.ReactActivity`,
  `launchMode="singleTask"`, `exported`, `windowSoftInputMode="adjustResize"`,
  `configChanges=keyboard|keyboardHidden|orientation|screenLayout|screenSize|smallestScreenSize|uiMode`,
  single MAIN/LAUNCHER intent filter, **no deep links**.
- **Activities (GMS)**: `SignInHubActivity`, `GoogleApiActivity` (translucent).
- **Providers**: `RNCWebViewFileProvider` (react-native-webview),
  `androidx.startup.InitializationProvider` (WorkManager, EmojiCompat,
  ProcessLifecycle, ProfileInstaller), `ReactNativeFirebaseAppInitProvider`
  (`initOrder=99`), `FirebaseInitProvider` (`initOrder=100`).
- **Services**: `ComponentDiscoveryService` with registrars for
  `@react-native-firebase/app`, Firestore (Ktx + plain), Firebase Analytics
  connector, Firebase Installations, Firebase Common Ktx;
  WorkManager `SystemAlarmService` / `SystemJobService` / `SystemForegroundService`;
  GMS `RevocationBoundService`; GMS measurement services.
- **Receivers**: WorkManager constraint proxies (battery, storage, network),
  `RescheduleReceiver` (BOOT/TIME_SET/TIMEZONE), `ConstraintProxyUpdateReceiver`,
  `ForceStopRunnable$BroadcastReceiver`, exported `DiagnosticsReceiver`,
  GMS `AppMeasurementReceiver`.
- **Queries**: Google Pay readiness probes (`org.chromium.intent.action.PAY`,
  `IS_READY_TO_PAY`, `UPDATE_PAYMENT_DETAILS`) and
  `<package android:name="com.google.android.apps.maps" />`.

## Metadata
- `com.google.android.geo.API_KEY` = `AIzaSyAt8Xg5RpYbhjwKPIXDC7Tw9l-bO-JjPe8`
  — a **Google Maps Android platform key** restricted to the package name and
  SHA-1 `f9:56:bf:83:3a:d4:8f:00:3e:46:52:1a:2f:99:1e:5a:9f:e6:8a:96`.
  Not reused by the rebuild.
- Firebase Analytics: collection ENABLED, deactivated FALSE.
- Google Analytics: adid, ssaid, automatic screen reporting, default allow
  analytics/ad storage/user data/personalisation signals — all enabled.
- `app_data_collection_default_enabled` = true.
- `com.google.android.gms.version` = `@integer/google_play_services_version`.

## Libraries
- `uses-library` `org.apache.http.legacy` (not required).
- `uses-library` `android.ext.adservices` (not required).

## Reproduced in the rebuild
`INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`,
`ACCESS_NETWORK_STATE`, `android.hardware.location` (optional), `launchMode=singleTask`,
`windowSoftInputMode=adjustResize`, label, `allowBackup=false`, `supportsRtl=true`,
`usesCleartextTraffic=false`, the DayNight no-action-bar theme with
`forceDarkAllowed=false`, the launcher icon at all five densities, and
package-visibility queries for `https`/`geo`/`SEND` plus Google Maps.
