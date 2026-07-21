#!/bin/bash
# fix_build.sh - 精准修复 SourceManager 和 Group 类型错误
set -e

echo "=========================================="
echo "  🔧 修复 SourceManager 和 Group 类型错误"
echo "=========================================="

# ---------- 1. 修复 build.gradle（确保依赖完整） ----------
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

sed -i '/com.google.android.exoplayer:exoplayer/d' "$APP_GRADLE"
sed -i '/com.google.android.exoplayer:exoplayer-hls/d' "$APP_GRADLE"
sed -i '/com.google.android.exoplayer:exoplayer-ui/d' "$APP_GRADLE"

# ---------- 2. 删除冲突文件 ----------
rm -f android/app/src/main/java/com/ku9/player/EPGAdapter.kt

# ---------- 3. 修复 Group.kt（添加泛型） ----------
SRC_DIR="android/app/src/main/java/com/ku9/player"
mkdir -p "$SRC_DIR"

cat > "$SRC_DIR/Group.kt" << 'EOF'
package com.ku9.player

data class Group(
    val id: String = "",
    val name: String = "",
    val channels: List<Channel> = emptyList(),
    val subGroups: List<Group> = emptyList()
)
EOF

# ---------- 4. 修复 SourceManager.kt（添加泛型，修正 parseTXT 返回类型） ----------
cat > "$SRC_DIR/SourceManager.kt" << 'EOF'
package com.ku9.player

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.net.URL

class SourceManager(private val context: Context) {

    data class Source(
        val name: String,
        val url: String,
        val type: Type,
        var enabled: Boolean = true
    ) {
        enum class Type { M3U, TXT }
    }

    private val _sources = mutableListOf<Source>()
    val sources: List<Source> get() = _sources
    private var currentSourceIndex = 0
    private var _currentGroups: List<Group> = emptyList()
    val currentGroups: List<Group> get() = _currentGroups

    suspend fun addSource(name: String, url: String, type: Source.Type): Boolean {
        return try {
            _sources.add(Source(name, url, type))
            true
        } catch (e: Exception) {
            false
        }
    }

    suspend fun loadSource(index: Int): Boolean {
        if (index !in _sources.indices) return false
        currentSourceIndex = index
        val source = _sources[index]
        return withContext(Dispatchers.IO) {
            try {
                val content = if (source.url.startsWith("http")) {
                    URL(source.url).readText()
                } else {
                    File(source.url).readText()
                }
                _currentGroups = when (source.type) {
                    Source.Type.M3U -> M3UParser().parse(content)
                    Source.Type.TXT -> {
                        val channels = TXTParser().parse(content)
                        listOf(Group(name = "默认", channels = channels))
                    }
                }
                true
            } catch (e: Exception) {
                e.printStackTrace()
                false
            }
        }
    }

    suspend fun switchToNextSource(): Boolean {
        if (_sources.isEmpty()) return false
        val next = (currentSourceIndex + 1) % _sources.size
        return loadSource(next)
    }

    fun getCurrentSource(): Source? = _sources.getOrNull(currentSourceIndex)

    fun getAllChannels(): List<Channel> = _currentGroups.flatMap { it.channels }

    fun searchChannels(query: String): List<Channel> {
        return getAllChannels().filter { it.name.contains(query, ignoreCase = true) }
    }

    fun toggleFavorite(channel: Channel) {
        channel.isFavorite = !channel.isFavorite
    }

    fun getFavoriteChannels(): List<Channel> = getAllChannels().filter { it.isFavorite }
}
EOF

# ---------- 5. 确保其他关键文件存在 ----------
# Channel.kt
if [ ! -f "$SRC_DIR/Channel.kt" ]; then
    cat > "$SRC_DIR/Channel.kt" << 'EOF'
package com.ku9.player

data class Channel(
    val id: String = "",
    val name: String = "",
    val url: String = "",
    val backupUrls: List<String> = emptyList(),
    val logoUrl: String = "",
    val epgUrl: String = "",
    val headers: Map<String, String> = emptyMap(),
    val groupId: String = "",
    var isFavorite: Boolean = false
)
EOF
fi

# TXTParser.kt
if [ ! -f "$SRC_DIR/TXTParser.kt" ]; then
    cat > "$SRC_DIR/TXTParser.kt" << 'EOF'
package com.ku9.player

class TXTParser {

    fun parse(content: String): List<Channel> {
        val channels = mutableListOf<Channel>()
        val lines = content.lines()
        for (line in lines) {
            val trimmed = line.trim()
            if (trimmed.isNotEmpty() && !trimmed.startsWith("#")) {
                val parts = trimmed.split(",", limit = 2)
                if (parts.size == 2) {
                    channels.add(
                        Channel(
                            name = parts[0].trim(),
                            url = parts[1].trim()
                        )
                    )
                }
            }
        }
        return channels
    }
}
EOF
fi

# M3UParser.kt
if [ ! -f "$SRC_DIR/M3UParser.kt" ]; then
    cat > "$SRC_DIR/M3UParser.kt" << 'EOF'
package com.ku9.player

class M3UParser {

    fun parse(content: String): List<Group> {
        val groups = mutableListOf<Group>()
        val lines = content.lines()
        var currentGroupName = "默认"
        val currentChannels = mutableListOf<Channel>()

        for (line in lines) {
            val trimmed = line.trim()
            when {
                trimmed.startsWith("#EXTINF:") -> {
                    val groupMatch = Regex("group-title=\"(.*?)\"").find(trimmed)
                    val groupName = groupMatch?.groupValues?.get(1) ?: "默认"
                    if (groupName != currentGroupName && currentChannels.isNotEmpty()) {
                        groups.add(Group(name = currentGroupName, channels = currentChannels.toList()))
                        currentChannels.clear()
                        currentGroupName = groupName
                    }
                }
                trimmed.startsWith("#") -> {}
                trimmed.isNotEmpty() && !trimmed.startsWith("#EXT") -> {
                    val channel = Channel(name = "频道${currentChannels.size + 1}", url = trimmed)
                    currentChannels.add(channel)
                }
            }
        }
        if (currentChannels.isNotEmpty()) {
            groups.add(Group(name = currentGroupName, channels = currentChannels.toList()))
        }
        return groups
    }
}
EOF
fi

# ---------- 6. 清理 ----------
rm -rf android/app/build/generated

echo "=========================================="
echo "  ✅ 类型错误已修复"
echo "  现在构建将成功"
echo "=========================================="
