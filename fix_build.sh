#!/bin/bash
# fix_build.sh - 完整替换为 witv 源码 + 升级 Gradle 8.9
set -e

echo "=========================================="
echo "  🔄 完整替换为 witv 源码 (Gradle 8.9)"
echo "=========================================="

# 1. 克隆 witv 仓库
TMP_DIR=$(mktemp -d)
echo "📥 克隆 witv 仓库..."
git clone --depth 1 https://github.com/whyun-android/witv.git "$TMP_DIR"

# 2. 备份当前 android 目录
if [ -d "android" ]; then
    mv android android.bak
    echo "📦 已备份原 android 目录为 android.bak"
fi

# 3. 复制完整项目
echo "📁 复制项目文件..."
cp -r "$TMP_DIR" android
rm -rf android/.git
rm -rf "$TMP_DIR"

# 4. 升级 Gradle 到 8.9
echo "⬆️  升级 Gradle 到 8.9..."
if [ -f "android/gradle/wrapper/gradle-wrapper.properties" ]; then
    sed -i 's/gradle-8\.[0-9]*-all\.zip/gradle-8.9-all.zip/g' android/gradle/wrapper/gradle-wrapper.properties
else
    mkdir -p android/gradle/wrapper
    cat > android/gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.9-all.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
fi

# 5. 修改包名
echo "📝 修改包名: com.whyun.witv → com.ku9.player"
if [ -d "android/app/src/main/java/com/whyun/witv" ]; then
    mkdir -p android/app/src/main/java/com/ku9
    mv android/app/src/main/java/com/whyun/witv android/app/src/main/java/com/ku9/player
    rm -rf android/app/src/main/java/com/whyun
fi

find android -type f \( -name "*.java" -o -name "*.xml" -o -name "*.gradle" -o -name "*.properties" -o -name "*.kt" \) -exec sed -i 's/com\.whyun\.witv/com.ku9.player/g' {} \;

sed -i 's/namespace '\''com\.whyun\.witv'\''/namespace '\''com.ku9.player'\''/g' android/app/build.gradle
sed -i 's/applicationId "com\.whyun\.witv"/applicationId "com.ku9.player"/g' android/app/build.gradle

# 6. 修改应用名称
echo "📝 修改应用名称: WiTV → 酷9播放器"
find android -type f -name "strings.xml" -exec sed -i 's/WiTV/酷9播放器/g' {} \;

if [ -f "android/settings.gradle" ]; then
    sed -i "s/rootProject.name = 'WiTV'/rootProject.name = 'Ku9Player'/g" android/settings.gradle
fi

# 7. 修复 build.gradle 中可能存在的版本冲突
echo "🔧 修复 build.gradle 配置..."
if [ -f "android/build.gradle" ]; then
    sed -i 's/classpath "com\.android\.tools\.build:gradle:.*"/classpath "com.android.tools.build:gradle:8.5.0"/g' android/build.gradle
fi

# 8. 添加执行权限
chmod +x android/gradlew

# 9. 清理构建缓存
rm -rf android/build android/app/build

echo "=========================================="
echo "  ✅ 替换完成！"
echo ""
echo "  📋 修改内容："
echo "  - 包名: com.ku9.player"
echo "  - 应用名: 酷9播放器"
echo "  - Gradle: 8.9"
echo "  - AGP: 8.5.0"
echo ""
echo "  现在执行: cd android && ./gradlew assembleDebug"
echo "=========================================="
