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

## Test on Android from VS Code

Open the repository root in VS Code with the Dart and Flutter extensions. The project already contains an Android target. Use Android Studio's SDK Manager to install the Android tooling and its Device Manager if you want an emulator. You can edit and debug the game in VS Code. [Flutter Android setup](https://docs.flutter.dev/platform-integration/android/setup) · [VS Code Flutter workflow](https://docs.flutter.dev/tools/vs-code)

- Install Android Studio and complete its first-run setup. In SDK Manager, select Android SDK Platform 36. Under SDK Tools, check Build-Tools, Platform-Tools, Command-line Tools, and CMake. Enable **Show Package Details** and select NDK `28.2.13676358` under **NDK (Side by side)**. Install Android Emulator and create a virtual device if you want to test without a phone. The emulator can run a newer Android version than the SDK used to compile the app. [Android Studio download](https://developer.android.com/studio) · [Install a specific NDK version](https://developer.android.com/studio/projects/install-ndk)
- Run `flutter doctor -v` to verify the Android toolchain. If it reports pending licenses, follow the instructions it prints. Newer Android command-line tools may report that the separate `--android-licenses` command is no longer needed.
- Start the emulator or connect a phone with USB debugging enabled and authorize the computer when prompted. Run `flutter devices` to confirm Flutter can see it.
- In VS Code, select the Android device in the status bar and press **F5** to run with debugging and hot reload.

During a debug session, click the lightning bolt on the VS Code debug toolbar to hot reload. If you launched from the terminal with `flutter run`, press lowercase `r` in that terminal. Use **Flutter: Hot Restart** from the VS Code command palette or uppercase `R` in the terminal when changing how the Flame scene is constructed. [Flutter hot reload](https://docs.flutter.dev/tools/hot-reload)

Use the Android emulator on Windows to check layout and interaction. For frame timing, run a profile build on the iPhone from a Mac with Xcode and inspect the UI and raster tracks in Flutter DevTools. Replace `<device-id>` with the ID from `flutter devices`. [Flutter iOS setup](https://docs.flutter.dev/platform-integration/ios/setup) · [Flutter performance profiling](https://docs.flutter.dev/perf/ui-performance)

```powershell
flutter run --profile -d <device-id>
```

For the woodland performance baseline, open DevTools **Performance** after the enclosure appears. Clear the timeline and capture one full trip from the upper branch to the floor and back, including a meal. Then tap the insect and expand **Recent activity** to capture the journal opening and expansion. Compare UI and raster times for the same sequence on the same phone as we add foliage. Export the DevTools snapshot if you want to compare runs later. [DevTools Performance view](https://docs.flutter.dev/tools/devtools/performance)
