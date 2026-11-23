# african_affinity

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Releasing an Android APK

```bash
flutter build apk --release        # no --dart-define: defaults point at production
```

- Release signing reads `android/key.properties` (git-ignored) which points at
  `~/.android/afroaffinity-release.jks`. **Back both up.** Losing the key means
  nobody can update the app in place; the app id is `com.afroaffinity.app`.
- Release signing SHA-1: `16:F9:5C:03:9B:2A:E1:24:DA:2C:E6:30:3B:3B:78:96:96:FB:AC:92`
  (register it for any Android OAuth client / Play).
- Google sign-in is hidden unless the build gets `--dart-define=GOOGLE_WEB_CLIENT_ID=...`.
- Local stack: `flutter run --dart-define-from-file=config/local.json`
  (copy `config/local.example.json`).
