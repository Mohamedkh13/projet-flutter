# Device Monitor

A Flutter app for viewing live device and network telemetry.

## Data sources

- On Android, app CPU usage, process memory, system RAM usage, and battery
  status come from Android runtime APIs.
- Device identity and OS version come from `device_info_plus`.
- Network type and local IP are read from the active device interfaces.
- Endpoint latency and request history come from real HTTP requests initiated
  by the app.
- Device metrics refresh every 5 seconds; endpoint probes refresh every
  30 seconds. Sampling starts after sign-in and personal PIN verification.
- Security details show the current Firebase provider and ID-token expiry;
  they do not claim to scan other apps or modify device settings.
- On the first successful Google sign-in, users create and confirm a personal
  4-digit PIN. It is stored in the device's encrypted secure storage, scoped to
  the Firebase user, and required again when reopening or resuming the app.
  Five incorrect attempts require signing in with Google again.

## Permissions and privacy

Android declares `INTERNET` and `ACCESS_NETWORK_STATE`, which are install-time
permissions and do not display a runtime prompt. The telemetry does not need
location, contacts, or storage access, so the app does not request them.
The response cache is held in memory for the current signed-in session.

On platforms without the Android metrics channel, unsupported system metrics
are shown as unavailable rather than estimated.

## Checks

```powershell
flutter analyze
flutter test
flutter build apk --release --split-per-abi
```
