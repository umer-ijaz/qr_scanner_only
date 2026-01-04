Place your app logo image named `logo.png` here (path: assets/logo.png).

Recommended sizes:
- Flutter in-app asset: place at `assets/logo.png` (any reasonable size; 1024x1024 is fine)

For native platform splash support (optional but recommended):
- Android: copy the same PNG into `android/app/src/main/res/drawable/launch_image.png`.
- iOS: add the image into `ios/Runner/Assets.xcassets/LaunchImage.imageset/` and update the Contents.json accordingly; name the image `LaunchImage` in the storyboard.

After adding the files, run:

```bash
flutter pub get
flutter clean
flutter run
```

This project has been updated to show an in-app splash using `assets/logo.png` and the Android launch background references `@drawable/launch_image`.
