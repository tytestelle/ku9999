#!/bin/bash
# fix_build.sh - 完整替换为 witv 源码（同时升级 Gradle wrapper）
set -e

echo "=========================================="
echo "  🔄 完整替换为 witv 源码"
echo "=========================================="

# 1. 克隆 witv 仓库到临时目录
TMP_DIR=$(mktemp -d)
echo "📥 克隆 witv 仓库..."
git clone --depth 1 https://github.com/whyun-android/witv.git "$TMP_DIR"

# 2. 备份当前 android 目录（如果存在）
if [ -d "android" ]; then
    mv android android.bak
    echo "📦 已备份原 android 目录为 android.bak"
fi

# 3. 复制整个项目结构（包含所有 Gradle 配置文件）
echo "📁 复制项目文件..."
cp -r "$TMP_DIR" android

# 4. 删除临时目录中的 .git 文件夹（避免冲突）
rm -rf android/.git

# 5. 清理临时目录
rm -rf "$TMP_DIR"

# 6. 修改包名：com.whyun.witv → com.ku9.player
echo "📝 修改包名..."

# 6.1 重命名 Java 包目录
if [ -d "android/app/src/main/java/com/whyun/witv" ]; then
    mkdir -p android/app/src/main/java/com/ku9
    mv android/app/src/main/java/com/whyun/witv android/app/src/main/java/com/ku9/player
    rm -rf android/app/src/main/java/com/whyun
fi

# 6.2 替换所有文件中的包名引用
find android -type f \( -name "*.java" -o -name "*.xml" -o -name "*.gradle" -o -name "*.properties" -o -name "*.kt" \) -exec sed -i 's/com\.whyun\.witv/com.ku9.player/g' {} \;

# 6.3 修改 app/build.gradle 中的 namespace 和 applicationId
sed -i 's/namespace '\''com\.whyun\.witv'\''/namespace '\''com.ku9.player'\''/g' android/app/build.gradle
sed -i 's/applicationId "com\.whyun\.witv"/applicationId "com.ku9.player"/g' android/app/build.gradle

# 7. 修改应用名称：WiTV → 酷9播放器
echo "📝 修改应用名称..."
find android -type f -name "strings.xml" -exec sed -i 's/WiTV/酷9播放器/g' {} \;

# 8. 修改 settings.gradle 中的项目名称（如果有）
if [ -f "android/settings.gradle" ]; then
    sed -i "s/rootProject.name = 'WiTV'/rootProject.name = 'Ku9Player'/g" android/settings.gradle
fi

# 9. 升级 Gradle wrapper 版本（从 8.4 到 8.9）
echo "⬆️ 升级 Gradle wrapper 到 8.9..."
if [ -f "android/gradle/wrapper/gradle-wrapper.properties" ]; then
    sed -i 's/gradle-8.4-all.zip/gradle-8.9-all.zip/g' android/gradle/wrapper/gradle-wrapper.properties
    # 如果找不到 8.4，也可能直接替换
    sed -i 's/gradle-8\.[0-9]*-all.zip/gradle-8.9-all.zip/g' android/gradle/wrapper/gradle-wrapper.properties
fi

# 10. 给 gradlew 添加执行权限
chmod +x android/gradlew

# 11. 清理构建缓存
rm -rf android/build android/app/build

echo "=========================================="
echo "  ✅ 替换完成！"
echo ""
echo "  项目结构："
echo "  - 根目录: android/"
echo "  - Gradle 配置: android/build.gradle, android/settings.gradle"
echo "  - 应用模块: android/app/"
echo "  - 包名: com.ku9.player"
echo "  - 应用名: 酷9播放器"
echo "  - Gradle wrapper: 已升级到 8.9"
echo ""
echo "  现在执行: cd android && ./gradlew assembleDebug"
echo "=========================================="
