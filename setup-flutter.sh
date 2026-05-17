#!/bin/bash
set -e

echo "=== Installing system dependencies ==="
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk unzip wget curl git clang cmake ninja-build pkg-config libgtk-3-dev

echo "=== Downloading Flutter SDK ==="
cd ~
if [ ! -d "$HOME/flutter" ]; then
    wget -q --show-progress https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz
    tar xf flutter_linux_3.24.0-stable.tar.xz
    rm flutter_linux_3.24.0-stable.tar.xz
else
    echo "Flutter already exists, skipping download"
fi

echo "=== Downloading Android SDK command-line tools ==="
mkdir -p ~/android-sdk/cmdline-tools
cd ~/android-sdk/cmdline-tools
if [ ! -d "latest" ]; then
    wget -q --show-progress https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
    unzip -q commandlinetools-linux-11076708_latest.zip
    mv cmdline-tools latest
    rm commandlinetools-linux-11076708_latest.zip
else
    echo "Android SDK tools already exist, skipping download"
fi

echo "=== Setting up environment variables ==="
if ! grep -q "flutter/bin" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# Flutter & Android SDK
export PATH="$HOME/flutter/bin:$PATH"
export ANDROID_HOME="$HOME/android-sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
EOF
fi

export PATH="$HOME/flutter/bin:$PATH"
export ANDROID_HOME="$HOME/android-sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

echo "=== Accepting Android SDK licenses ==="
yes | sdkmanager --licenses || true

echo "=== Installing Android SDK components ==="
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

echo "=== Configuring Flutter ==="
flutter config --android-sdk ~/android-sdk
yes | flutter doctor --android-licenses || true

echo "=== Flutter Doctor ==="
flutter doctor

echo ""
echo "=== Done! ==="
echo "Run: source ~/.bashrc"
echo "Then: cd ~/repos/nautilus-app && flutter pub get && flutter build apk --release"
