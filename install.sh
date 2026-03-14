#!/bin/bash
# Boring Notch 构建和安装脚本
# 用法：./install.sh

set -e

PROJECT_ROOT="/Users/tinker.chen/work/code/github/tools/boring.notch"
PROJECT_DIR="$PROJECT_ROOT/boringNotch.xcodeproj"
BUILD_DIR="$PROJECT_ROOT/build"
APP_PATH="$BUILD_DIR/Build/Products/Release/boringNotch.app"

echo "🔨 开始构建 Boring Notch..."

# 清理旧的构建
echo "🧹 清理旧的构建..."
rm -rf "$BUILD_DIR"

# 使用 xcodebuild 构建 Release 版本
echo "📦 构建 Release 版本..."
xcodebuild -project "$PROJECT_DIR" \
    -scheme "boringNotch" \
    -configuration "Release" \
    -derivedDataPath "$BUILD_DIR" \
    -destination "platform=macOS" \
    build

if [ ! -d "$APP_PATH" ]; then
    echo "❌ 构建失败，未找到 $APP_PATH"
    exit 1
fi

echo "✅ 构建成功：$APP_PATH"

# 移除 quarantine 属性
echo "🔓 移除 quarantine 属性..."
xattr -dr com.apple.quarantine "$APP_PATH"

# 重新签名所有嵌入的 Framework 和 App（解决 Team ID 不匹配问题）
echo "✍️  重新签名 Framework 和 App..."
codesign --force --deep --sign - "$APP_PATH/Contents/Frameworks/MediaRemoteAdapter.framework"
codesign --force --deep --sign - "$APP_PATH/Contents/Frameworks/Lottie.framework"
codesign --force --deep --sign - "$APP_PATH/Contents/Frameworks/Sparkle.framework"
codesign --force --deep --sign - "$APP_PATH"

echo "✅ 完成！"
echo ""
echo "🎉 构建成功！"
echo ""
echo "应用位置：$APP_PATH"
echo ""

# 打开应用
echo "🚀 启动应用..."
open "$APP_PATH"
