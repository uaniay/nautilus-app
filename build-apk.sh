#!/bin/bash
set -e

ANDROID_SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

echo "=== Installing Android SDK ==="
mkdir -p ~/android-sdk/cmdline-tools
cd ~/android-sdk/cmdline-tools

if [ ! -d "latest" ]; then
    wget -q --show-progress "$ANDROID_SDK_URL" -O tools.zip
    unzip -q tools.zip
    mv cmdline-tools latest
    rm tools.zip
    echo "Android SDK tools downloaded"
else
    echo "Already exists, skipping"
fi

export ANDROID_HOME="$HOME/android-sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

echo "=== Accepting licenses ==="
yes | sdkmanager --licenses || true

echo "=== Installing SDK components ==="
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

echo "=== Configuring Flutter ==="
flutter config --android-sdk ~/android-sdk
yes | flutter doctor --android-licenses || true

echo "=== Building APK ==="
cd ~/repos/nautilus-app
flutter pub get
flutter build apk --release

echo ""
echo "=== Done! ==="
echo "APK: ~/repos/nautilus-app/build/app/outputs/flutter-apk/app-release.apk"
