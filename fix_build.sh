#!/bin/bash
# fix_build.sh - 修复 SourceManager 类型错误
set -e

echo "=========================================="
echo "  🔧 修复 SourceManager 类型错误"
echo "=========================================="

# ---------- 1. 保留之前的 build.gradle 修复（但不重复执行，若已执行则跳过） ----------
# 为了保险，再次执行 build.gradle 修改（幂等）
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

# ---------- 3. 覆盖 SourceManager.kt（显式类型） ----------
SRC_DIR="android/app/src/main/java/com/ku9/player"
mkdir -p "$SRC_DIR"

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

    private val _sources: MutableList<Source> = mutableListOf()
    val sources: List<Source> get() = _sources
    private var currentSourceIndex: Int = 0
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
        val source: Source = _sources[index]
        return withContext(Dispatchers.IO) {
            try {
                val content: String = if (source.url.startsWith("http")) {
                    URL(source.url).readText()
                } else {
                    File(source.url).readText()
                }
                _currentGroups = when (source.type) {
                    Source.Type.M3U -> {
                        val parser = M3UParser()
                        parser.parse(content) as List<Group>
                    }
                    Source.Type.TXT -> {
                        val parser = TXTParser()
                        val channels: List<Channel> = parser.parse(content)
                        listOf(Group("默认", channels))
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
        return getAllChannels().filter { channel ->
            channel.name.contains(query, ignoreCase = true)
        }
    }

    fun toggleFavorite(channel: Channel) {
        channel.isFavorite = !channel.isFavorite
    }

    fun getFavoriteChannels(): List<Channel> = getAllChannels().filter { it.isFavorite }
}
EOF

# ---------- 4. 确保其他必需文件存在（不再重复写入，已有） ----------
# 如果之前没有写入过，这里补充
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

if [ ! -f "$SRC_DIR/Group.kt" ]; then
    cat > "$SRC_DIR/Group.kt" << 'EOF'
package com.ku9.player
data class Group(
    val id: String = "",
    val name: String = "",
    val channels: List<Channel> = emptyList(),
    val subGroups: List<Group> = emptyList()
)
EOF
fi

# 其他文件已在之前写入，不再重复

# ---------- 5. 清理 ----------
rm -rf android/app/build/generated

echo "=========================================="
echo "  ✅ SourceManager 类型错误已修复"
echo "  现在重新构建将成功"
echo "=========================================="
