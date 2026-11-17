# Insect Sanctuary

A cozy insectarium game built with Flutter and Flame.

## Project layout

The Flutter app lives at the repository root. A separate app directory was useful while comparing engines. With one app, keeping its manifest, source, and tests at the root gives local development and CI the same working directory.

## Run and verify

From the repository root, restore dependencies and run the checks before launching the browser preview.

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```
