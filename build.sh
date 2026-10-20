#!/usr/bin/env bash
set -euo pipefail

APP_NAME="PhoneFacts"
BUNDLE_ID="com.colinstars.phonefacts"
MIN_IOS="15.0"
OUT_DIR="build"

echo "==> SDK"
SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
echo "SDK: $SDK_PATH"
xcrun --sdk iphoneos --show-sdk-version

echo "==> 清理"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR/$APP_NAME.app"

echo "==> 编译 (arm64-apple-ios$MIN_IOS)"
xcrun -sdk iphoneos swiftc \
  -target "arm64-apple-ios$MIN_IOS" \
  -sdk "$SDK_PATH" \
  -parse-as-library \
  -O \
  -module-name "$APP_NAME" \
  -o "$OUT_DIR/$APP_NAME.app/$APP_NAME" \
  Sources/main.swift \
  -framework SwiftUI \
  -framework UIKit \
  -framework Foundation

echo "==> 拷贝 Info.plist"
cp Resources/Info.plist "$OUT_DIR/$APP_NAME.app/Info.plist"

echo "==> 运行时依赖检查"
otool -L "$OUT_DIR/$APP_NAME.app/$APP_NAME" | head -20
echo "--- 架构 ---"
lipo -info "$OUT_DIR/$APP_NAME.app/$APP_NAME" || file "$OUT_DIR/$APP_NAME.app/$APP_NAME"

echo "==> 打包 Payload"
mkdir -p "$OUT_DIR/Payload"
cp -R "$OUT_DIR/$APP_NAME.app" "$OUT_DIR/Payload/"
( cd "$OUT_DIR" && zip -qry "../${APP_NAME}-unsigned.ipa" Payload )

echo "==> 产物"
ls -lh "${APP_NAME}-unsigned.ipa"
shasum -a 256 "${APP_NAME}-unsigned.ipa"
