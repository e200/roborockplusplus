# Roborock++ app

Flutter app; see the [project README](../README.md).

```sh
flutter test                   # unit, widget and map tests (map tests skip without the private fixture)
flutter build apk --release
dart run tool/smoke.dart       # read-only check against a real robot (needs ../secrets/session.json)
```
