#!/bin/bash
# fix_build.sh - 仅修复构建配置和缺失文件，业务逻辑请手动修改
set -e

echo "=========================================="
echo "  🔧 安全修复脚本（配置 + 缺失文件）"
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

# ---------- 2. 创建缺失的 EpgProgram ----------
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

# ---------- 3. 为 EPGManager 添加 import ----------
EPG_MANAGER="android/app/src/main/java/com/ku9/player/EPGManager.kt"
if [ -f "$EPG_MANAGER" ] && ! grep -q "import java.util.regex.Pattern" "$EPG_MANAGER"; then
    echo "📥 添加 import java.util.regex.Pattern"
    sed -i '/^package/a\
import java.util.regex.Pattern' "$EPG_MANAGER"
fi

# ---------- 4. 检查布局文件（提示） ----------
LAYOUT="android/app/src/main/res/layout/fragment_channel_list.xml"
if [ ! -f "$LAYOUT" ]; then
    echo "⚠️ 布局文件不存在，请手动创建并添加 rv_channels"
fi

echo "=========================================="
echo "  ✅ 配置修复完成"
echo "=========================================="
echo ""
echo "📌 以下编译错误需要您手动修复（按文件分类）："
echo ""
echo "1️⃣  MainActivity.kt 和 ChannelListFragment.kt"
echo "   - 错误：ChannelListFragment 重复定义"
echo "   - 修复：删除 MainActivity.kt 中的内部 class ChannelListFragment"
echo ""
echo "2️⃣  fragment_channel_list.xml"
echo "   - 错误：rv_channels 未找到"
echo "   - 修复：在布局中添加 RecyclerView，id 为 @+id/rv_channels"
echo ""
echo "3️⃣  ChannelAdapter.kt 和 ChannelListFragment.kt"
echo "   - 错误：ChannelAdapter 构造函数参数不匹配"
echo "   - 修复：将 ChannelAdapter 改为 class ChannelAdapter(private val channels: List<Channel>, private val onItemClick: (Channel) -> Unit)"
echo "         并在 ChannelListFragment 中传入 channels 列表"
echo ""
echo "4️⃣  EPGManager.kt"
echo "   - 错误：forEach 歧义，DOTALL 未解析"
echo "   - 修复：将 .forEach { 改为 .entries.forEach { (key, value) ->"
echo "         并将内部使用 it 的地方改为 value"
echo ""
echo "5️⃣  M3UParser.kt"
echo "   - 错误：第25行类型不匹配（MutableList<Channel> 赋值给 String）"
echo "   - 修复：去掉变量声明中的类型 ': String'，改为 val channels = ..."
echo ""
echo "6️⃣  ParserManager.kt"
echo "   - 错误：M3UParser() 不能作为函数调用"
echo "   - 修复：根据 M3UParser 的实际方法，改为 M3UParser().parse(content) 或 M3UParser.parse(content)"
echo ""
echo "7️⃣  PlayerManager.kt"
echo "   - 错误：setHardwareCodecEnabled 等方法不存在；trackSelector smart cast"
echo "   - 修复：注释掉这些过时方法；在调用 trackSelector 前添加 val selector = trackSelector，用 selector 操作"
echo ""
echo "8️⃣  SourceManager.kt"
echo "   - 错误：logo 参数不存在；类型不匹配"
echo "   - 修复：删除 Channel 构造中的 logo=... 参数；检查第74行变量类型，确保与右侧表达式一致"
echo ""
echo "💡 建议在 Android Studio 中逐个修复，利用 IDE 的快速修复功能。"
echo "   修复完成后，再次推送代码，CI 将重新构建。"
echo "=========================================="
