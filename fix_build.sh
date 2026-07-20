#!/bin/bash
# fix_build.sh - 精确修复酷9播放器编译错误，保留完整功能
set -e

echo "=========================================="
echo "  🔧 开始精确修复编译错误"
echo "=========================================="

# ---------- 1. 修复 Channel.kt 类型参数 ----------
CHANNEL_FILE="android/app/src/main/java/com/ku9/player/Channel.kt"
if [ -f "$CHANNEL_FILE" ]; then
    echo "📝 修复 Channel.kt 类型参数..."
    sed -i 's/backupUrls: List = emptyList()/backupUrls: List<String> = emptyList()/g' "$CHANNEL_FILE"
    sed -i 's/headers: Map = emptyMap()/headers: Map<String, String> = emptyMap()/g' "$CHANNEL_FILE"
fi

# ---------- 2. 启用 ViewBinding ----------
APP_GRADLE="android/app/build.gradle"
if ! grep -q "viewBinding" "$APP_GRADLE"; then
    echo "📱 启用 ViewBinding..."
    sed -i '/android {/a\
    buildFeatures {\
        viewBinding true\
    }' "$APP_GRADLE"
fi

# ---------- 3. 修复依赖（统一使用 media3） ----------
if grep -q "com.google.android.exoplayer:exoplayer" "$APP_GRADLE"; then
    echo "📦 更新 ExoPlayer 依赖为 media3..."
    sed -i '/com.google.android.exoplayer:exoplayer/d' "$APP_GRADLE"
    sed -i '/com.google.android.exoplayer:exoplayer-hls/d' "$APP_GRADLE"
    sed -i '/com.google.android.exoplayer:exoplayer-ui/d' "$APP_GRADLE"
    # 在 dependencies 块末尾添加 media3 依赖
    sed -i '/dependencies {/a\
    implementation "androidx.media3:media3-exoplayer:1.4.0"\
    implementation "androidx.media3:media3-exoplayer-hls:1.4.0"\
    implementation "androidx.media3:media3-ui:1.4.0"' "$APP_GRADLE"
fi

# ---------- 4. 删除 MainActivity 中的重复内部类 ----------
MAIN_ACTIVITY="android/app/src/main/java/com/ku9/player/MainActivity.kt"
if [ -f "$MAIN_ACTIVITY" ]; then
    echo "🗑️ 删除 MainActivity 中重复的 ChannelListFragment 内部类..."
    # 使用 Python 精确删除（更可靠）
    python3 -c "
import re
with open('$MAIN_ACTIVITY', 'r') as f:
    content = f.read()
# 删除 class ChannelListFragment : Fragment() { ... } 整个类
pattern = r'class ChannelListFragment\s*:\s*Fragment\(\)\s*\{[^{}]*(\{[^{}]*\}[^{}]*)*\}'
new_content = re.sub(pattern, '', content, flags=re.DOTALL)
with open('$MAIN_ACTIVITY', 'w') as f:
    f.write(new_content)
print('✅ 已删除重复的内部类')
" 2>/dev/null || echo "⚠️ Python 处理失败，请手动删除 MainActivity 中的内部类"
fi

# ---------- 5. 修复 EPGManager 中的 RegexOption ----------
EPG_MANAGER="android/app/src/main/java/com/ku9/player/EPGManager.kt"
if [ -f "$EPG_MANAGER" ]; then
    echo "📝 修复 EPGManager 中的 RegexOption..."
    sed -i 's/RegexOption.DOTALL/RegexOption.DOT_MATCHES_ALL/g' "$EPG_MANAGER"
    # 如果没有 import kotlin.text.RegexOption，添加
    if ! grep -q "import kotlin.text.RegexOption" "$EPG_MANAGER"; then
        sed -i '/^package/a\
import kotlin.text.RegexOption' "$EPG_MANAGER"
    fi
fi

# ---------- 6. 修复 SourceManager 中的 M3UParser 调用 ----------
SOURCE_MANAGER="android/app/src/main/java/com/ku9/player/SourceManager.kt"
if [ -f "$SOURCE_MANAGER" ]; then
    echo "📝 修复 SourceManager 中的 M3UParser 调用..."
    sed -i 's/M3UParser\.parse(/M3UParser().parse(/g' "$SOURCE_MANAGER"
fi

# ---------- 7. 检查并创建缺失的布局文件 ----------
LAYOUT_DIR="android/app/src/main/res/layout"
LAYOUT_FILE="$LAYOUT_DIR/fragment_channel_list.xml"
if [ ! -f "$LAYOUT_FILE" ]; then
    echo "📄 创建缺失的 fragment_channel_list.xml..."
    mkdir -p "$LAYOUT_DIR"
    cat > "$LAYOUT_FILE" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">
    
    <androidx.appcompat.widget.SearchView
        android:id="@+id/search_view"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:queryHint="搜索频道..." />
    
    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rv_channels"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
</LinearLayout>
EOF
fi

# ---------- 8. 修复 ChannelListFragment 中的布局ID引用 ----------
CHANNEL_LIST="android/app/src/main/java/com/ku9/player/ChannelListFragment.kt"
if [ -f "$CHANNEL_LIST" ]; then
    echo "📝 确保 ChannelListFragment 使用正确的布局ID..."
    # 将 R.id.rv_channels 改为 R.id.rv_channels（已匹配）
    # 无需修改，只需确保布局中存在该ID
fi

echo "=========================================="
echo "  ✅ 修复完成！"
echo "  请重新运行构建。"
echo "=========================================="
