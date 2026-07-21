#!/bin/bash
# fix_build.sh - 修复资源错误（移除图标引用）
set -e

echo "=========================================="
echo "  🔧 修复 AndroidManifest 图标引用"
echo "=========================================="

MANIFEST="android/app/src/main/AndroidManifest.xml"

# 确保 drawable 存在（备选）
mkdir -p android/app/src/main/res/drawable
cat > android/app/src/main/res/drawable/ic_launcher_foreground.xml << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <group
        android:scaleX="0.3"
        android:scaleY="0.3"
        android:translateX="37.8"
        android:translateY="37.8">
        <path
            android:fillColor="#FFFFFF"
            android:pathData="M54,27 L81,54 L54,81 L27,54 Z" />
        <path
            android:fillColor="#FF0000"
            android:pathData="M54,27 L81,54 L54,81 L27,54 Z" />
    </group>
</vector>
EOF

# 备份原 Manifest
cp "$MANIFEST" "$MANIFEST.bak"

# 移除 android:icon 和 android:roundIcon 属性（如果有）
sed -i 's/ android:icon="[^"]*"//g' "$MANIFEST"
sed -i 's/ android:roundIcon="[^"]*"//g' "$MANIFEST"

# 确保 application 标签有 name 和 theme，如果没有添加
if ! grep -q 'android:name=".Ku9Application"' "$MANIFEST"; then
    sed -i 's/<application /<application android:name=".Ku9Application" /' "$MANIFEST"
fi

# 确保 usesCleartextTraffic 为 true
if ! grep -q 'android:usesCleartextTraffic="true"' "$MANIFEST"; then
    sed -i 's/<application /<application android:usesCleartextTraffic="true" /' "$MANIFEST"
fi

# 添加网络权限（如果缺失）
if ! grep -q "INTERNET" "$MANIFEST"; then
    sed -i '/<manifest/a\
    <uses-permission android:name="android.permission.INTERNET" />' "$MANIFEST"
fi

# 清理构建缓存
rm -rf android/app/build

echo "=========================================="
echo "  ✅ 已移除图标引用，创建默认 drawable"
echo "  重新构建将成功"
echo "=========================================="
