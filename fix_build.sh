#!/bin/bash
# fix_build.sh - 自动修复酷9播放器构建错误（无反向引用版）
set -e

echo "=========================================="
echo "  🔧 开始执行构建修复脚本 (安全版)"
echo "=========================================="

# ---------- 1. 修复 app/build.gradle ----------
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
add_dependency "androidx.media3:media3-exoplayer:1.4.0"
add_dependency "androidx.media3:media3-exoplayer-hls:1.4.0"
add_dependency "androidx.media3:media3-ui:1.4.0"
add_dependency "androidx.media3:media3-common:1.4.0"
add_dependency "androidx.recyclerview:recyclerview:1.3.2"

# ---------- 2. 更新 EpgProgram ----------
EPG_CLASS="android/app/src/main/java/com/ku9/player/EpgProgram.kt"
mkdir -p "$(dirname "$EPG_CLASS")"
cat > "$EPG_CLASS" << 'EOF'
package com.ku9.player

data class EpgProgram(
    val title: String,
    val start: String,
    val end: String,
    val desc: String = "",
    val startTime: Long = 0,
    val endTime: Long = 0
)
EOF
echo "📄 已更新 EpgProgram.kt"

# ---------- 3. 添加 import Pattern.DOTALL ----------
EPG_MANAGER="android/app/src/main/java/com/ku9/player/EPGManager.kt"
if [ -f "$EPG_MANAGER" ]; then
    if ! grep -q "import java.util.regex.Pattern" "$EPG_MANAGER"; then
        echo "📥 添加 import java.util.regex.Pattern"
        sed -i '/^package/a\
import java.util.regex.Pattern' "$EPG_MANAGER"
    fi
    # 修复 forEach 歧义
    sed -i 's/\.forEach {/.entries.forEach { entry ->/g' "$EPG_MANAGER"
    sed -i 's/\bval\s\+program\s*=\s*it\.value/val program = entry.value/g' "$EPG_MANAGER"
    sed -i 's/\bval\s\+key\s*=\s*it\.key/val key = entry.key/g' "$EPG_MANAGER"
fi

# ---------- 4. 检查重复类（仅提示，不自动修改） ----------
MAIN_ACTIVITY="android/app/src/main/java/com/ku9/player/MainActivity.kt"
if [ -f "$MAIN_ACTIVITY" ]; then
    if grep -q "class ChannelListFragment" "$MAIN_ACTIVITY"; then
        echo "⚠️ 发现重复类 ChannelListFragment 在 MainActivity.kt 中，请手动删除或注释掉该内部类"
    fi
fi

# ---------- 5. 修复 ChannelAdapter 构造函数 ----------
CHANNEL_ADAPTER="android/app/src/main/java/com/ku9/player/ChannelAdapter.kt"
if [ -f "$CHANNEL_ADAPTER" ]; then
    echo "🔧 修复 ChannelAdapter 构造函数..."
    sed -i 's/class ChannelAdapter(private val onItemClick: (Channel) -> Unit)/class ChannelAdapter(private val channels: List<Channel>, private val onItemClick: (Channel) -> Unit)/' "$CHANNEL_ADAPTER"
fi

# ---------- 6. 修复 MainActivity 中 ChannelListFragment 实例化 ----------
if [ -f "$MAIN_ACTIVITY" ]; then
    # 将 ChannelListFragment() 改为 ChannelListFragment(emptyList())（若外部类存在）
    sed -i 's/ChannelListFragment()/ChannelListFragment(emptyList())/g' "$MAIN_ACTIVITY"
fi

# ---------- 7. 修复 ParserManager ----------
PARSER_MANAGER="android/app/src/main/java/com/ku9/player/ParserManager.kt"
if [ -f "$PARSER_MANAGER" ]; then
    echo "🔧 修复 ParserManager..."
    sed -i 's/M3UParser()/M3UParser().parse()/g' "$PARSER_MANAGER"
fi

# ---------- 8. 修复 SourceManager ----------
SOURCE_MANAGER="android/app/src/main/java/com/ku9/player/SourceManager.kt"
if [ -f "$SOURCE_MANAGER" ]; then
    echo "🔧 修复 SourceManager..."
    sed -i 's/, logo=[^,)]*//g' "$SOURCE_MANAGER"
    echo "⚠️ 请检查 SourceManager.kt 第74行类型匹配（可能需手动调整）"
fi

# ---------- 9. 修复 PlayerManager API（注释过时调用） ----------
PLAYER_MANAGER="android/app/src/main/java/com/ku9/player/PlayerManager.kt"
if [ -f "$PLAYER_MANAGER" ]; then
    echo "🔧 修复 PlayerManager API..."
    sed -i 's/^.*setHardwareCodecEnabled.*$/\/\/ &/' "$PLAYER_MANAGER"
    sed -i 's/^.*setLoadErrorHandlingPolicy.*$/\/\/ &/' "$PLAYER_MANAGER"
    sed -i 's/^.*setVideoScalingMode.*$/\/\/ &/' "$PLAYER_MANAGER"
    sed -i '/^\/\/ setHardwareCodecEnabled/a\        // TODO: Use DefaultTrackSelector.Builder for media3 1.4+' "$PLAYER_MANAGER"
fi

# ---------- 10. 修复 EPGAdapter 字段名 ----------
EPG_ADAPTER="android/app/src/main/java/com/ku9/player/EPGAdapter.kt"
if [ -f "$EPG_ADAPTER" ]; then
    echo "🔧 修复 EPGAdapter 字段引用..."
    sed -i 's/\.startTime/.start/g' "$EPG_ADAPTER"
    sed -i 's/\.endTime/.end/g' "$EPG_ADAPTER"
fi

# ---------- 11. 检查布局文件 ----------
LAYOUT="android/app/src/main/res/layout/fragment_channel_list.xml"
if [ ! -f "$LAYOUT" ]; then
    echo "⚠️ 布局文件 fragment_channel_list.xml 不存在"
else
    if ! grep -q "android:id=\"@+id/rv_channels\"" "$LAYOUT"; then
        echo "⚠️ 布局文件缺少 rv_channels ID"
    fi
fi

echo "=========================================="
echo "  ✅ 修复完成（脚本执行成功）"
echo "  ⚠️ 请手动处理以下事项："
echo "    - MainActivity.kt 中的重复内部类（如有）"
echo "    - SourceManager.kt 第74行类型不匹配"
echo "    - 检查其他编译错误（若有）"
echo "=========================================="
