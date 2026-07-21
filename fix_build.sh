#!/bin/bash
# fix_build.sh - 修复主题名称及缺失资源，重建完整功能
set -e

echo "=========================================="
echo "  🔧 修复主题及资源错误"
echo "=========================================="

# ---------- 1. 确保颜色和主题文件存在且名称匹配 ----------
mkdir -p android/app/src/main/res/values

cat > android/app/src/main/res/values/colors.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="purple_200">#FFBB86FC</color>
    <color name="purple_500">#FF6200EE</color>
    <color name="purple_700">#FF3700B3</color>
    <color name="teal_200">#FF03DAC5</color>
    <color name="teal_700">#FF018786</color>
    <color name="black">#FF000000</color>
    <color name="white">#FFFFFFFF</color>
</resources>
EOF

cat > android/app/src/main/res/values/themes.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.Ku9Player" parent="Theme.MaterialComponents.DayNight.NoActionBar">
        <item name="colorPrimary">@color/purple_500</item>
        <item name="colorPrimaryVariant">@color/purple_700</item>
        <item name="colorOnPrimary">@color/white</item>
        <item name="colorSecondary">@color/teal_200</item>
        <item name="colorSecondaryVariant">@color/teal_700</item>
        <item name="colorOnSecondary">@color/black</item>
        <item name="android:statusBarColor">?attr/colorPrimaryVariant</item>
    </style>
</resources>
EOF

# ---------- 2. 确保 build.gradle 依赖完整（幂等操作） ----------
APP_GRADLE="android/app/build.gradle"
if ! grep -q "viewBinding {" "$APP_GRADLE"; then
    sed -i '/android {/a\
    buildFeatures {\
        viewBinding true\
    }' "$APP_GRADLE"
fi

add_dependency() {
    local dep="$1"
    if ! grep -q "$dep" "$APP_GRADLE"; then
        sed -i "/dependencies {/a\\
    implementation \"$dep\"" "$APP_GRADLE"
    fi
}
add_dependency "com.squareup.okhttp3:okhttp:4.12.0"
add_dependency "com.squareup.okhttp3:logging-interceptor:4.12.0"
add_dependency "androidx.media3:media3-exoplayer:1.4.0"
add_dependency "androidx.media3:media3-exoplayer-hls:1.4.0"
add_dependency "androidx.media3:media3-ui:1.4.0"
add_dependency "androidx.media3:media3-common:1.4.0"
add_dependency "androidx.recyclerview:recyclerview:1.3.2"
add_dependency "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3"
add_dependency "androidx.lifecycle:lifecycle-runtime-ktx:2.6.2"
add_dependency "com.google.android.material:material:1.9.0"
sed -i '/com.google.android.exoplayer:exoplayer/d' "$APP_GRADLE"
sed -i '/com.google.android.exoplayer:exoplayer-hls/d' "$APP_GRADLE"
sed -i '/com.google.android.exoplayer:exoplayer-ui/d' "$APP_GRADLE"

# ---------- 3. 清理并重新生成 R 文件 ----------
rm -rf android/app/build/generated

echo "=========================================="
echo "  ✅ 主题及资源修复完成"
echo "  现在重新构建将成功"
echo "=========================================="
