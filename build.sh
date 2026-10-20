#!/usr/bin/env bash
set -euo pipefail

APP_NAME="ServerLens"
OUT="build"

echo "==> 工具链状态"
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version

echo "==> 检测/安装 XcodeGen"
if ! command -v xcodegen >/dev/null 2>&1; then
  brew install xcodegen
fi
xcodegen --version

echo "==> 生成工程"
xcodegen generate

echo "==> 解析 SPM 依赖（Citadel）"
xcodebuild -resolvePackageDependencies \
  -project "${APP_NAME}.xcodeproj" \
  -scheme "${APP_NAME}" \
  -clonedSourcePackagesDirPath "$OUT/SourcePackages"

echo "==> 极速并行编译"
xcodebuild \
  -project "${APP_NAME}.xcodeproj" \
  -scheme "${APP_NAME}" \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath "$OUT" \
  -clonedSourcePackagesDirPath "$OUT/SourcePackages" \
  -jobs 6 \
  COMPILER_INDEX_STORE_ENABLE=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP_PATH="$OUT/Build/Products/Release-iphoneos/${APP_NAME}.app"
echo "==> 编译产物验证"
ls -la "$APP_PATH"

echo "==> 校验 Mach-O 部署目标与 SDK"
otool -l "$APP_PATH/${APP_NAME}" | grep -A5 LC_BUILD_VERSION || true

echo "==> 打包 Payload 与 IPA"
mkdir -p "$OUT/Payload"
cp -R "$APP_PATH" "$OUT/Payload/"
( cd "$OUT" && zip -qry "../${APP_NAME}-unsigned.ipa" Payload )

ls -lh "${APP_NAME}-unsigned.ipa"
shasum -a 256 "${APP_NAME}-unsigned.ipa"
