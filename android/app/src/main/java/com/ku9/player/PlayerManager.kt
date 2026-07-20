// 文件路径：android/app/src/main/java/com/ku9/player/PlayerManager.kt
package com.ku9.player

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.media3.common.*
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.exoplayer.trackselection.TrackSelector
import androidx.media3.exoplayer.upstream.DefaultLoadErrorHandlingPolicy
import java.util.concurrent.atomic.AtomicBoolean

@UnstableApi
class PlayerManager(private val context: Context) {

    companion object {
        private const val MAX_RETRY_COUNT = 3
        private const val RETRY_DELAY_MS = 2000L
    }

    private var exoPlayer: ExoPlayer? = null
    private var trackSelector: DefaultTrackSelector? = null
    private var currentUrl: String? = null
    private var currentHeaders: Map<String, String> = emptyMap()
    private var isHardwareDecoder = true          // 默认硬解
    private var aspectRatio = AspectRatio.RESIZE_FIT  // 默认自适应
    private var retryCount = 0
    private val mainHandler = Handler(Looper.getMainLooper())
    private val isReleased = AtomicBoolean(false)

    // 播放器状态监听器
    private val playerListener = object : Player.Listener {
        override fun onPlaybackStateChanged(playbackState: Int) {
            when (playbackState) {
                Player.STATE_READY -> {
                    retryCount = 0 // 重置重试计数
                }
                Player.STATE_ENDED -> {
                    // 自动重播或停止
                }
                Player.STATE_BUFFERING -> {
                    // 缓冲中，可以显示加载动画
                }
            }
        }

        override fun onPlayerError(error: PlaybackException) {
            // 断线重连逻辑
            if (retryCount < MAX_RETRY_COUNT && !isReleased.get()) {
                retryCount++
                mainHandler.postDelayed({
                    currentUrl?.let { play(it, currentHeaders) }
                }, RETRY_DELAY_MS * retryCount)
            } else {
                // 通知UI播放失败
            }
        }
    }

    /**
     * 初始化播放器（如果未初始化则创建）
     */
    private fun initPlayer(): ExoPlayer {
        if (exoPlayer == null) {
            // 构建数据源工厂（支持自定义Headers）
            val dataSourceFactory = DefaultHttpDataSource.Factory()
                .setAllowCrossProtocolRedirects(true)
                .setConnectTimeoutMs(10000)
                .setReadTimeoutMs(10000)
                .setDefaultRequestProperties(currentHeaders)

            // Track选择器（硬解/软解）
            trackSelector = DefaultTrackSelector(context).apply {
                setParameters(
                    buildUponParameters()
                        .setHardwareCodecEnabled(isHardwareDecoder)
                        .setMaxVideoSize(1920, 1080)
                )
            }

            // 加载错误处理（断线重试策略）
            val loadErrorHandlingPolicy = DefaultLoadErrorHandlingPolicy(MAX_RETRY_COUNT)

            exoPlayer = ExoPlayer.Builder(context)
                .setTrackSelector(trackSelector)
                .setLoadErrorHandlingPolicy(loadErrorHandlingPolicy)
                .build()
                .apply {
                    addListener(playerListener)
                    setVideoScalingMode(C.VIDEO_SCALING_MODE_SCALE_TO_FIT)
                }
        }
        return exoPlayer!!
    }

    /**
     * 播放指定URL
     * @param url 视频流地址
     * @param headers 自定义请求头（如User-Agent、Referer等）
     */
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

    /**
     * 构建MediaSource，目前支持HLS（可扩展其他格式）
     */
    private fun buildMediaSource(url: String, headers: Map<String, String>): MediaSource {
        val dataSourceFactory = DefaultHttpDataSource.Factory()
            .setAllowCrossProtocolRedirects(true)
            .setDefaultRequestProperties(headers)

        return HlsMediaSource.Factory(dataSourceFactory)
            .setAllowChunklessPreparation(true)
            .createMediaSource(MediaItem.fromUri(Uri.parse(url)))
    }

    /**
     * 暂停
     */
    fun pause() {
        exoPlayer?.pause()
    }

    /**
     * 恢复播放
     */
    fun resume() {
        exoPlayer?.play()
    }

    /**
     * 停止播放（保留播放器）
     */
    fun stop() {
        exoPlayer?.stop()
    }

    /**
     * 释放播放器资源
     */
    fun release() {
        isReleased.set(true)
        mainHandler.removeCallbacksAndMessages(null)
        exoPlayer?.apply {
            removeListener(playerListener)
            release()
        }
        exoPlayer = null
        trackSelector = null
    }

    /**
     * 跳转到指定位置（毫秒）
     */
    fun seekTo(positionMs: Long) {
        exoPlayer?.seekTo(positionMs)
    }

    /**
     * 获取当前播放位置（毫秒）
     */
    fun getCurrentPosition(): Long = exoPlayer?.currentPosition ?: 0

    /**
     * 获取视频总时长（毫秒）
     */
    fun getDuration(): Long = exoPlayer?.duration ?: 0

    /**
     * 是否正在播放
     */
    fun isPlaying(): Boolean = exoPlayer?.isPlaying ?: false

    /**
     * 切换硬解/软解
     * @param useHardware true=硬解，false=软解
     */
    fun switchDecoder(useHardware: Boolean) {
        if (isHardwareDecoder == useHardware) return
        isHardwareDecoder = useHardware
        // 需要重建播放器才能生效
        currentUrl?.let { url ->
            // 保存当前播放位置
            val position = getCurrentPosition()
            // 重建
            release()
            isReleased.set(false)
            // 重新初始化并播放
            play(url, currentHeaders)
            // 恢复位置
            if (position > 0) {
                exoPlayer?.seekTo(position)
            }
        }
    }

    /**
     * 设置画面比例
     * @param ratio 可选值： "fit"（自适应），"16:9"，"4:3"，"fill"（拉伸全屏）
     */
    fun setAspectRatio(ratio: String) {
        val player = exoPlayer ?: return
        val videoSize = player.videoSize
        if (videoSize.width == 0 || videoSize.height == 0) return

        val targetAspect = when (ratio) {
            "16:9" -> 16f / 9f
            "4:3" -> 4f / 3f
            "fill" -> 1f // 拉伸，实际在View层处理
            else -> videoSize.width.toFloat() / videoSize.height // 自适应
        }

        // 通过修改视频缩放模式来实现比例调整
        // 实际还需要配合View的LayoutParams，这里仅设置缩放模式
        val scalingMode = when (ratio) {
            "fill" -> C.VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING
            else -> C.VIDEO_SCALING_MODE_SCALE_TO_FIT
        }
        player.setVideoScalingMode(scalingMode)
        // 通知外部（Activity/Fragment）通过调整SurfaceView的宽高比来实现
        // 这里只保留接口，具体UI适配由外部处理
    }

    /**
     * 获取当前使用的解码器类型
     */
    fun isUsingHardwareDecoder(): Boolean = isHardwareDecoder

    /**
     * 添加播放器事件监听
     */
    fun addListener(listener: Player.Listener) {
        exoPlayer?.addListener(listener)
    }

    /**
     * 移除监听
     */
    fun removeListener(listener: Player.Listener) {
        exoPlayer?.removeListener(listener)
    }
}

/**
 * 比例枚举（方便内部使用）
 */
enum class AspectRatio {
    RESIZE_FIT,      // 自适应
    RESIZE_16_9,
    RESIZE_4_3,
    RESIZE_FILL      // 拉伸全屏
}
