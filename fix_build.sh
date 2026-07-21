#!/bin/bash
# fix_build.sh - 将项目完全替换为 witv 源码
set -e

echo "=========================================="
echo "  🔄 替换为 witv 源码"
echo "=========================================="

# 1. 克隆 witv 仓库到临时目录
TMP_DIR=$(mktemp -d)
git clone --depth 1 https://github.com/whyun-android/witv.git "$TMP_DIR"

# 2. 备份当前 android 目录（以防万一）
if [ -d "android" ]; then
    mv android android.bak
    echo "📦 已备份原 android 目录为 android.bak"
fi

# 3. 复制 witv 的 app 模块到 android 目录
mkdir -p android
cp -r "$TMP_DIR/app"/* android/

# 4. 复制根目录的 gradle 文件
cp "$TMP_DIR/build.gradle" android/build.gradle 2>/dev/null || true
cp "$TMP_DIR/settings.gradle" android/settings.gradle 2>/dev/null || true
cp -r "$TMP_DIR/gradle" android/gradle 2>/dev/null || true
cp "$TMP_DIR/gradlew" android/gradlew 2>/dev/null || true
cp "$TMP_DIR/gradlew.bat" android/gradlew.bat 2>/dev/null || true

# 5. 清理临时目录
rm -rf "$TMP_DIR"

# 6. 修改包名（从 com.whyun.witv 改为 com.ku9.player）
# 重命名 Java 包目录
if [ -d "android/src/main/java/com/whyun/witv" ]; then
    mkdir -p android/src/main/java/com/ku9
    mv android/src/main/java/com/whyun/witv android/src/main/java/com/ku9/player
    rm -rf android/src/main/java/com/whyun
fi

# 7. 全局替换包名和引用
find android -type f -name "*.java" -exec sed -i 's/com\.whyun\.witv/com.ku9.player/g' {} \;
find android -type f -name "*.xml" -exec sed -i 's/com\.whyun\.witv/com.ku9.player/g' {} \;
find android -type f -name "*.gradle" -exec sed -i 's/com\.whyun\.witv/com.ku9.player/g' {} \;
find android -type f -name "*.properties" -exec sed -i 's/com\.whyun\.witv/com.ku9.player/g' {} \;

# 8. 修改应用名称（从 WiTV 改为 酷9播放器）
find android -type f -name "strings.xml" -exec sed -i 's/WiTV/酷9播放器/g' {} \;

# 9. 清理构建缓存
rm -rf android/build android/app/build

echo "=========================================="
echo "  ✅ 替换完成！"
echo "  现在执行: cd android && ./gradlew assembleDebug"
echo "=========================================="
