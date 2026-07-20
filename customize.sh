#!/bin/bash
# customize.sh - 构建前自动修改脚本
# 用法：在 build.yml 中通过 run: ./customize.sh 调用

set -e

echo "=========================================="
echo "  🔧 开始执行构建前自定义修改"
echo "=========================================="

# 1. 检查并修复缺失的依赖（示例）
if ! grep -q "exoplayer" android/app/build.gradle; then
    echo "📦 添加 ExoPlayer 依赖..."
    sed -i '/dependencies {/a\
    implementation "com.google.android.exoplayer:exoplayer-core:2.19.1"\
    implementation "com.google.android.exoplayer:exoplayer-hls:2.19.1"\
    implementation "com.google.android.exoplayer:exoplayer-ui:2.19.1"' \
    android/app/build.gradle
fi

# 2. 添加网络权限（如果缺失）
if ! grep -q "INTERNET" android/app/src/main/AndroidManifest.xml; then
    echo "🌐 添加网络权限..."
    sed -i '/<manifest/a\
    <uses-permission android:name="android.permission.INTERNET" />\
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />' \
    android/app/src/main/AndroidManifest.xml
fi

# 3. 添加存储权限（U盘读取）
if ! grep -q "READ_EXTERNAL_STORAGE" android/app/src/main/AndroidManifest.xml; then
    echo "💾 添加存储权限..."
    sed -i '/<manifest/a\
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />\
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />' \
    android/app/src/main/AndroidManifest.xml
fi

# 4. 启用 AndroidX（如果未启用）
if ! grep -q "android.useAndroidX" android/gradle.properties; then
    echo "📱 启用 AndroidX..."
    echo "android.useAndroidX=true" >> android/gradle.properties
    echo "android.enableJetifier=true" >> android/gradle.properties
fi

# 5. 您自己的修改逻辑（根据需求添加）
# 例如：修改版本号、替换图标、更新频道列表等
# echo "📝 执行自定义修改..."
# sed -i 's/旧内容/新内容/g' 目标文件

echo "=========================================="
echo "  ✅ 自定义修改完成"
echo "=========================================="
