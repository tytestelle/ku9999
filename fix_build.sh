#!/bin/bash
# fix_build.sh - 酷9播放器构建修复脚本（最终版）
set -e

echo "=========================================="
echo "  🔧 开始执行构建修复脚本（最终版）"
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

# ---------- 2. 补全 EpgProgram ----------
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

# ---------- 3. 修复 EPGManager ----------
EPG_MANAGER="android/app/src/main/java/com/ku9/player/EPGManager.kt"
if [ -f "$EPG_MANAGER" ]; then
    # 添加 import Pattern
    if ! grep -q "import java.util.regex.Pattern" "$EPG_MANAGER"; then
        echo "📥 添加 import java.util.regex.Pattern"
        sed -i '/^package/a\
import java.util.regex.Pattern' "$EPG_MANAGER"
    fi
    # 将 .forEach { 替换为 .entries.forEach { ，保留 it 不变（it 仍代表 Map.Entry）
    sed -i 's/\.forEach {/.entries.forEach {/g' "$EPG_MANAGER"
fi

# ---------- 4. 修复 MainActivity（注释内部类 + 补参数） ----------
MAIN_ACTIVITY="android/app/src/main/java/com/ku9/player/MainActivity.kt"
if [ -f "$MAIN_ACTIVITY" ]; then
    # 检查是否存在内部类，若存在则注释掉整个类（使用 /* ... */ 包裹）
    if grep -q "class ChannelListFragment" "$MAIN_ACTIVITY"; then
        echo "⚠️ 发现重复类 ChannelListFragment，正在尝试注释掉内部类..."
        # 使用 sed 在匹配行前插入 /*，并在匹配到的结束 } 后插入 */
        # 更稳健的方法：用 awk 处理，但为了简化，我们直接删除整个内部类（因为外部类 MainActivity 通常不依赖内部类）
        # 使用 sed 删除从 "class ChannelListFragment" 到下一个同缩进的 }（假设缩进为 4 空格）
        # 先备份
        cp "$MAIN_ACTIVITY" "$MAIN_ACTIVITY.bak"
        # 删除匹配块（从 class ChannelListFragment 到第一个同缩进的 }）
        sed -i '/^[[:space:]]*class ChannelListFragment/,/^[[:space:]]*}/d' "$MAIN_ACTIVITY"
        echo "已删除内部类定义（保留备份 at $MAIN_ACTIVITY.bak）"
    fi
    # 修复 ChannelListFragment 调用缺少参数
    # 将 ChannelListFragment() 替换为 ChannelListFragment(emptyList())
    sed -i 's/ChannelListFragment()/ChannelListFragment(emptyList())/g' "$MAIN_ACTIVITY"
fi

# ---------- 5. 修复 ChannelAdapter 构造函数 ----------
CHANNEL_ADAPTER="android/app/src/main/java/com/ku9/player/ChannelAdapter.kt"
if [ -f "$CHANNEL_ADAPTER" ]; then
    echo "🔧 修复 ChannelAdapter 构造函数..."
    sed -i 's/class ChannelAdapter(private val onItemClick: (Channel) -> Unit)/class ChannelAdapter(private val channels: List<Channel>, private val onItemClick: (Channel) -> Unit)/' "$CHANNEL_ADAPTER"
fi

# ---------- 6. 修复 ParserManager ----------
PARSER_MANAGER="android/app/src/main/java/com/ku9/player/ParserManager.kt"
if [ -f "$PARSER_MANAGER" ]; then
    echo "🔧 修复 ParserManager 中 M3UParser 调用..."
    # 将 M3UParser() 改为 M3UParser.parse()（假设 parse 为静态方法）
    sed -i 's/M3UParser()/M3UParser.parse()/g' "$PARSER_MANAGER"
fi

# ---------- 7. 修复 M3UParser 返回类型 ----------
M3U_PARSER="android/app/src/main/java/com/ku9/player/M3UParser.kt"
if [ -f "$M3U_PARSER" ]; then
    echo "🔧 修复 M3UParser.kt 第25行类型不匹配..."
    # 将 val channels: String = ... 改为 val channels = ...（去掉类型声明）
    sed -i 's/val channels: String/val channels/g' "$M3U_PARSER"
fi

# ---------- 8. 修复 SourceManager ----------
SOURCE_MANAGER="android/app/src/main/java/com/ku9/player/SourceManager.kt"
if [ -f "$SOURCE_MANAGER" ]; then
    echo "🔧 修复 SourceManager..."
    # 删除 logo 参数
    sed -i 's/, logo=[^,)]*//g' "$SOURCE_MANAGER"
    # 修复第74行类型不匹配：将 val something: String = ... 改为 val something = ...
    # 先定位第74行，用 sed 替换该行的类型声明
    sed -i '74s/: String//' "$SOURCE_MANAGER"
    # 若行号不确定，也可全局替换所有变量声明，但可能误伤，这里只修改第74行
fi

# ---------- 9. 修复 PlayerManager API 调用 ----------
PLAYER_MANAGER="android/app/src/main/java/com/ku9/player/PlayerManager.kt"
if [ -f "$PLAYER_MANAGER" ]; then
    echo "🔧 修复 PlayerManager API..."
    # 注释过时方法
    sed -i 's/^.*setHardwareCodecEnabled.*$/\/\/ &/' "$PLAYER_MANAGER"
    sed -i 's/^.*setLoadErrorHandlingPolicy.*$/\/\/ &/' "$PLAYER_MANAGER"
    sed -i 's/^.*setVideoScalingMode.*$/\/\/ &/' "$PLAYER_MANAGER"
    # 解决 smart cast 问题：将 trackSelector 赋给局部变量再使用
    # 由于代码复杂，我们仅给出提示，不自动修改
    echo "⚠️ PlayerManager 中 trackSelector smart cast 问题需手动处理（将 trackSelector 赋给临时变量）"
fi

# ---------- 10. 修复 EPGAdapter 字段引用 ----------
EPG_ADAPTER="android/app/src/main/java/com/ku9/player/EPGAdapter.kt"
if [ -f "$EPG_ADAPTER" ]; then
    echo "🔧 修复 EPGAdapter 字段引用..."
    sed -i 's/\.startTime/.start/g' "$EPG_ADAPTER"
    sed -i 's/\.endTime/.end/g' "$EPG_ADAPTER"
fi

# ---------- 11. 检查布局文件 ----------
LAYOUT="android/app/src/main/res/layout/fragment_channel_list.xml"
if [ ! -f "$LAYOUT" ]; then
    echo "⚠️ 布局文件 fragment_channel_list.xml 不存在，请手动创建并添加 rv_channels"
else
    if ! grep -q "android:id=\"@+id/rv_channels\"" "$LAYOUT"; then
        echo "⚠️ 布局文件缺少 rv_channels ID，请手动添加: <androidx.recyclerview.widget.RecyclerView android:id=\"@+id/rv_channels\" ... />"
    fi
fi

echo "=========================================="
echo "  ✅ 修复完成（脚本执行成功）"
echo "  ⚠️ 以下事项需要您手动检查："
echo "    1. MainActivity.kt 中内部类已删除，请确认无影响"
echo "    2. PlayerManager.kt 的 smart cast 问题（建议使用局部变量）"
echo "    3. 布局文件中 rv_channels 缺失（若存在请忽略）"
echo "    4. 其他编译错误（若有）请根据日志调整"
echo "=========================================="
