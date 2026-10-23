# Permissions & Android Integration

## Permissions declared (recovered from AndroidManifest.xml)
| Permission | Purpose (as used by the app) |
|---|---|
| `android.permission.INTERNET` | Network access (Firestore, error logging) |
| `android.permission.ACCESS_FINE_LOCATION` | "Nearby" tab – user's precise location |
| `android.permission.ACCESS_COARSE_LOCATION` | "Nearby" tab – fallback location |
| `android.permission.POST_NOTIFICATIONS` | Requested at startup after the update check (`requestNotificationPermission`, module 1485) |
| `android.permission.ACCESS_NETWORK_STATE` | Library-driven (React Native + Firebase) |
| `android.permission.WAKE_LOCK` | WorkManager |
| `android.permission.ACCESS_WIFI_STATE` | Play services measurement |
| `android.permission.RECEIVE_BOOT_COMPLETED` | WorkManager rescheduling |
| `android.permission.FOREGROUND_SERVICE` | WorkManager |
| `com.google.android.gms.permission.AD_ID` | Play-services ads identifier (collection ENABLED by default) |
| `android.permission.ACCESS_ADSERVICES_ATTRIBUTION` | Ad-services attribution |
| `android.permission.ACCESS_ADSERVICES_AD_ID` | Ad-services ad id |
| `com.google.android.finsky.permission.BIND_GET_INSTALL_REFERRER_SERVICE` | Play Install Referrer |
| `com.android.vending.CHECK_LICENSE` | **Play Integrity / Pairip anti-tampering** |
| `com.codez.lahoreelectricbusguide.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | AndroidX generated (signature) |

## Features
- `android.hardware.faketouch` (required)
- `android.hardware.location` (implied by coarse/fine location) – **effectively required**
- `android.hardware.wifi` (not required)
- `uses-gl-es: 0x00020000` (required)
- screens: small, normal, large, xlarge; any density; locales: only `--_--` (default)

## Queries (intent visibility)
- `org.chromium.intent.action.PAY`, `IS_READY_TO_PAY`, `UPDATE_PAYMENT_DETAILS` – Google Pay readiness probe (react-native-webview / RN PayPal-style billing libs)
- `<package android:name="com.google.android.apps.maps" />` – the app checks whether Google Maps is installed before offering "open in Maps".

## Providers
- `com.codez.lahoreelectricbusguide.fileprovider` → `com.reactnativecommunity.webview.RNCWebViewFileProvider`, `@xml/file_provider_paths` (react-native-webview)
- `com.codez.lahoreelectricbusguide.androidx-startup` → `androidx.startup.InitializationProvider` with WorkManager / EmojiCompat / ProcessLifecycle / ProfileInstaller initialisers
- `com.codez.lahoreelectricbusguide.reactnativefirebaseappinitprovider` → `io.invertase.firebase.app.ReactNativeFirebaseAppInitProvider`, `initOrder=99`
- `com.codez.lahoreelectricbusguide.firebaseinitprovider` → `com.google.firebase.provider.FirebaseInitProvider`, directBootAware, `initOrder=100`

## Services
- `com.google.firebase.components.ComponentDiscoveryService` with registrars for:
  - `io.invertase.firebase.app.ReactNativeFirebaseAppRegistrar`
  - `com.google.firebase.firestore.FirebaseFirestoreKtxRegistrar`
  - `com.google.firebase.firestore.FirestoreRegistrar`
  - `com.google.firebase.analytics.connector.internal.AnalyticsConnectorRegistrar`
  - `com.google.firebase.installations.*`
  - `com.google.firebase.FirebaseCommonKtxRegistrar`
- `androidx.work.impl.background.systemalarm.SystemAlarmService`
- `androidx.work.impl.background.systemjob.SystemJobService` (exported, `BIND_JOB_SERVICE`)
- `androidx.work.impl.foreground.SystemForegroundService`
- `com.google.android.gms.auth.api.signin.RevocationBoundService` (exported)
- GMS measurement: `AppMeasurementReceiver`, `AppMeasurementService`, `AppMeasurementJobService`

## Receivers
- WorkManager constraint proxies (battery charging, battery not low, storage not low, network state), `RescheduleReceiver` (BOOT_COMPLETED / TIME_SET / TIMEZONE_CHANGED), `ConstraintProxyUpdateReceiver`, `ForceStopRunnable$BroadcastReceiver`, exported `DiagnosticsReceiver` (DUMP permission).

## Activities
- `MainActivity` (exported, LAUNCHER)
- `com.google.android.gms.auth.api.signin.internal.SignInHubActivity` (translucent)
- `com.google.android.gms.common.api.GoogleApiActivity` (translucent)

## Application metadata
- `android:name="com.pairip.application.Application"` → **Google Play Pairip integrity/anti-tampering wrapper**. Not to be bypassed; the rebuilt app is a clean reimplementation and simply does not include it.
- `android:theme="@style/AppTheme"` = `Theme.AppCompat.DayNight.NoActionBar` + `windowIsTranslucent=true` + `forceDarkAllowed=false` + `editTextBackground=@drawable/rn_edit_text_material`.
- `<meta-data android:name="com.google.android.geo.API_KEY" .../>` – a **Google Maps Android API key** for the package `com.codez.lahoreelectricbusguide` (SHA1 `f9:56:bf:83:3a:d4:8f:00:3e:46:52:1a:2f:99:1e:5a:9f:e6:8a:96`). This is a *restricted* platform key bound to the original signing certificate; it must **not** be copied into the rebuild. The rebuilt app uses its own configuration (see `.env.example`).
- Analytics/ad-storage collection is **enabled by default** (`firebase_analytics_collection_enabled`, `google_analytics_adid_collection_enabled`, `app_data_collection_default_enabled`).

## Reproduced in the Flutter rebuild
`INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `POST_NOTIFICATIONS`, `ACCESS_NETWORK_STATE`. No wake-lock / ads / licence permissions are added because the corresponding behaviour is not reimplemented.
