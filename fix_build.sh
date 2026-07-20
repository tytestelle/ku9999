#!/bin/bash
# fix_build.sh - 最终修正（简化 PlayerManager，移除问题 API）
set -e

echo "=========================================="
echo "  🔧 执行最终修正（简化 PlayerManager）"
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
add_dependency "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3"
add_dependency "androidx.lifecycle:lifecycle-runtime-ktx:2.6.2"

sed -i '/com.google.android.exoplayer:exoplayer/d' "$APP_GRADLE"
sed -i '/com.google.android.exoplayer:exoplayer-hls/d' "$APP_GRADLE"
sed -i '/com.google.android.exoplayer:exoplayer-ui/d' "$APP_GRADLE"

# ---------- 2. 修正 PlayerManager.kt（简化版） ----------
SRC_DIR="android/app/src/main/java/com/ku9/player"

cat > "$SRC_DIR/PlayerManager.kt" << 'EOF'
package com.ku9.player

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.media3.common.*
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import java.util.concurrent.atomic.AtomicBoolean

@UnstableApi
class PlayerManager(private val context: Context) {

    companion object {
        private const val MAX_RETRY_COUNT = 3
        private const val RETRY_DELAY_MS = 2000L
    }

    private var exoPlayer: ExoPlayer? = null
    private var currentUrl: String? = null
    private var currentHeaders: Map<String, String> = emptyMap()
    private var retryCount = 0
    private val mainHandler = Handler(Looper.getMainLooper())
    private val isReleased = AtomicBoolean(false)

    private val playerListener = object : Player.Listener {
        override fun onPlaybackStateChanged(playbackState: Int) {
            if (playbackState == Player.STATE_READY) retryCount = 0
        }

        override fun onPlayerError(error: PlaybackException) {
            if (retryCount < MAX_RETRY_COUNT && !isReleased.get()) {
                retryCount++
                mainHandler.postDelayed({
                    currentUrl?.let { play(it, currentHeaders) }
                }, RETRY_DELAY_MS * retryCount)
            }
        }
    }

    private fun initPlayer(): ExoPlayer {
        if (exoPlayer == null) {
            val selector = DefaultTrackSelector(context)
            // 简化构建，避免使用可能不兼容的 API
            val player = ExoPlayer.Builder(context)
                .setTrackSelector(selector)
                .build()
            // 监听器在 build 后添加
            player.addListener(playerListener)
            exoPlayer = player
        }
        return exoPlayer!!
    }

    fun play(url: String, headers: Map<String, String> = emptyMap()) {
        if (isReleased.get()) return
        currentUrl = url
        currentHeaders = headers
        val player = initPlayer()
        val mediaSource = buildMediaSource(url, headers)
        player.setMediaSource(mediaSource)
        player.prepare()
        player.play()
    }

    private fun buildMediaSource(url: String, headers: Map<String, String>): MediaSource {
        val dataSourceFactory = DefaultHttpDataSource.Factory()
            .setAllowCrossProtocolRedirects(true)
            .setDefaultRequestProperties(headers)
        return HlsMediaSource.Factory(dataSourceFactory)
            .setAllowChunklessPreparation(true)
            .createMediaSource(MediaItem.fromUri(Uri.parse(url)))
    }

    fun pause() {
        exoPlayer?.pause()
    }

    fun resume() {
        exoPlayer?.play()
    }

    fun stop() {
        exoPlayer?.stop()
    }

    fun release() {
        isReleased.set(true)
        mainHandler.removeCallbacksAndMessages(null)
        exoPlayer?.apply {
            removeListener(playerListener)
            release()
        }
        exoPlayer = null
    }

    fun seekTo(positionMs: Long) {
        exoPlayer?.seekTo(positionMs)
    }
}
EOF

# ---------- 3. 确保其他文件存在且正确（之前已修复，无需重复） ----------
# 但为了保险，补全可能缺失的 EpgProgram、EpgAdapter 等
cat > "$SRC_DIR/EpgProgram.kt" << 'EOF'
package com.ku9.player

data class EpgProgram(
    val title: String,
    val startTime: Long,
    val endTime: Long,
    val desc: String = ""
)
EOF

cat > "$SRC_DIR/EpgAdapter.kt" << 'EOF'
package com.ku9.player

import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView

class EpgAdapter : RecyclerView.Adapter<EpgAdapter.ViewHolder>() {

    private var items: List<EpgProgram> = emptyList()

    fun submitList(list: List<EpgProgram>) {
        items = list
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = TextView(parent.context).apply {
            textSize = 16f
            setPadding(32, 16, 32, 16)
        }
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val program = items[position]
        holder.textView.text = "${program.title} (${program.startTime} - ${program.endTime})"
    }

    override fun getItemCount() = items.size

    class ViewHolder(val textView: TextView) : RecyclerView.ViewHolder(textView)
}
EOF

# ---------- 4. 清理 ----------
rm -rf android/app/build/generated

echo "=========================================="
echo "  ✅ 修复完成（PlayerManager 已简化）"
echo "  现在构建应该成功"
echo "=========================================="
