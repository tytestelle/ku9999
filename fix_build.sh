#!/bin/bash
# fix_build.sh - 仅修复构建配置和缺失类，不修改业务代码
set -e

echo "=========================================="
echo "  🔧 安全修复脚本（仅配置和缺失文件）"
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

# ---------- 2. 创建缺失的 EpgProgram 类 ----------
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
echo "📄 已创建 EpgProgram.kt"

# ---------- 3. 为 EPGManager 添加 import（如果缺失） ----------
EPG_MANAGER="android/app/src/main/java/com/ku9/player/EPGManager.kt"
if [ -f "$EPG_MANAGER" ]; then
    if ! grep -q "import java.util.regex.Pattern" "$EPG_MANAGER"; then
        echo "📥 添加 import java.util.regex.Pattern"
        sed -i '/^package/a\
import java.util.regex.Pattern' "$EPG_MANAGER"
    fi
fi

# ---------- 4. 检查布局文件（仅提示） ----------
LAYOUT="android/app/src/main/res/layout/fragment_channel_list.xml"
if [ ! -f "$LAYOUT" ]; then
    echo "⚠️ 布局文件 fragment_channel_list.xml 不存在，请手动创建并添加 id 为 rv_channels 的 RecyclerView"
else
    if ! grep -q "android:id=\"@+id/rv_channels\"" "$LAYOUT"; then
        echo "⚠️ 布局文件缺少 rv_channels ID，请手动添加: <androidx.recyclerview.widget.RecyclerView android:id=\"@+id/rv_channels\" ... />"
    fi
fi

echo "=========================================="
echo "  ✅ 安全修复完成"
echo "=========================================="
echo ""
echo "📌 剩余的编译错误需要您手动处理，常见解决方法："
echo ""
echo "1. ChannelListFragment 重复定义"
echo "   → 删除 MainActivity.kt 中的内部 class ChannelListFragment"
echo ""
echo "2. rv_channels 未找到"
echo "   → 在 fragment_channel_list.xml 中添加 RecyclerView，ID 设为 @+id/rv_channels"
echo ""
echo "3. EPGManager 中的 forEach 歧义"
echo "   → 将 .forEach { 改为 .entries.forEach { (key, value) -> 并替换内部 it"
echo ""
echo "4. M3UParser 返回类型错误"
echo "   → 检查第25行，确保变量类型正确（可能是 val channels = ...）"
echo ""
echo "5. SourceManager 中 logo 参数不存在"
echo "   → 删除 Channel 构造中的 logo=... 参数"
echo ""
echo "6. PlayerManager 中 trackSelector smart cast"
echo "   → 在使用前将 trackSelector 赋值给局部变量 val selector = trackSelector"
echo ""
echo "7. ParserManager 中 M3UParser 调用缺少参数"
echo "   → 改为 M3UParser().parse(content) 或类似正确用法"
echo ""
echo "建议在本地 IDE 中修复上述问题，然后重新运行构建。"
echo "=========================================="
