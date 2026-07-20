#!/bin/bash
# fix_build.sh - 自动修复编译错误
set -e

echo "=========================================="
echo "  🔧 开始执行构建修复脚本"
echo "=========================================="

# ---------- 修复 app/build.gradle ----------
APP_GRADLE="android/app/build.gradle"

if ! grep -q "viewBinding {" "$APP_GRADLE"; then
    echo "📱 启用 ViewBinding..."
    sed -i '/android {/a\
    buildFeatures {\
        viewBinding true\
    }' "$APP_GRADLE"
fi

add_dependency() {
    local dep="$1"
    if ! grep -q "$dep" "$APP_GRADLE"; then
        echo "📦 添加依赖: $dep"
        sed -i "/dependencies {/a\\
    implementation \"$dep\"" "$APP_GRADLE"
    fi
}

add_dependency "com.squareup.okhttp3:okhttp:4.12.0"
add_dependency "com.squareup.okhttp3:logging-interceptor:4.12.0"
add_dependency "androidx.media3:media3-exoplayer:1.3.1"
add_dependency "androidx.media3:media3-exoplayer-hls:1.3.1"
add_dependency "androidx.media3:media3-ui:1.3.1"
add_dependency "androidx.media3:media3-common:1.3.1"
add_dependency "androidx.recyclerview:recyclerview:1.3.2"

# ---------- 创建 EpgProgram ----------
EPG_CLASS="android/app/src/main/java/com/ku9/player/EpgProgram.kt"
if [ ! -f "$EPG_CLASS" ]; then
    echo "📄 创建 EpgProgram.kt..."
    mkdir -p "$(dirname "$EPG_CLASS")"
    cat > "$EPG_CLASS" << 'EOF'
package com.ku9.player

data class EpgProgram(
    val title: String,
    val start: String,
    val end: String,
    val desc: String = ""
)
EOF
fi

# ---------- 修复 ParserManager ----------
PARSER_MANAGER="android/app/src/main/java/com/ku9/player/ParserManager.kt"
if [ -f "$PARSER_MANAGER" ]; then
    echo "🔧 修复 ParserManager..."
    sed -i 's/M3UParser()/M3UParser().parse()/g' "$PARSER_MANAGER"
fi

# ---------- 修复 SourceManager ----------
SOURCE_MANAGER="android/app/src/main/java/com/ku9/player/SourceManager.kt"
if [ -f "$SOURCE_MANAGER" ]; then
    echo "🔧 修复 SourceManager..."
    sed -i 's/, logo=[^,)]*//g' "$SOURCE_MANAGER"
fi

# ---------- 修复 ChannelAdapter ----------
CHANNEL_ADAPTER="android/app/src/main/java/com/ku9/player/ChannelAdapter.kt"
if [ -f "$CHANNEL_ADAPTER" ]; then
    echo "🔧 修复 ChannelAdapter 构造函数..."
    sed -i 's/class ChannelAdapter(private val onItemClick: (Channel) -> Unit)/class ChannelAdapter(private val channels: List<Channel>, private val onItemClick: (Channel) -> Unit)/' "$CHANNEL_ADAPTER"
fi

echo "=========================================="
echo "  ✅ 修复完成"
echo "=========================================="
