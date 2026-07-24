#!/bin/bash
# Reconstruieste Stressy si il reinstaleaza pe iPhone-ul conectat.
# Cerinte: iPhone conectat cu cablul, deblocat, Developer Mode ON.
set -e
cd "$(dirname "$0")/.."
export LANG=en_US.UTF-8
DEVICE=00008130-001A02E2266A001C

echo "==> Pregatesc framework-ul Flutter..."
flutter build ios --release || true   # pregateste (poate 'esua' la signing, e ok)

echo "==> Construiesc cu Xcode..."
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release \
  -destination "id=$DEVICE" -allowProvisioningUpdates build

APP=$(xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release \
  -destination "id=$DEVICE" -showBuildSettings 2>/dev/null \
  | awk '/ TARGET_BUILD_DIR =/{print $3}')/Runner.app

echo "==> Instalez pe iPhone..."
xcrun devicectl device install app --device "$DEVICE" "$APP"
echo "✅ Gata! Deschide Stressy pe telefon."
