package com.ku9.player

import android.content.Context
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.source.MediaSource
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource
import com.google.android.exoplayer2.video.VideoSize

class PlayerManager {
    private var exoPlayer: ExoPlayer? = null
    private var currentUrl: String? = null
    private var backupUrls: List<String> = emptyList()
    private var retryCount = 0

    fun init(context: Context) {
        if (exoPlayer == null) {
            exoPlayer = ExoPlayer.Builder(context).build().apply {
                addListener(object : Player.Listener {
                    override fun onPlayerError(error: PlaybackException) {
                        // 断线重连：切换备用源
                        retryCount++
                        if (retryCount <= 3 && backupUrls.isNotEmpty()) {
                            val nextUrl = backupUrls.getOrNull(retryCount - 1)
                            nextUrl?.let { play(it, emptyMap()) }
                        }
                    }
                    override fun onVideoSizeChanged(videoSize: VideoSize) {
                        // 画面比例调整
                    }
                })
            }
        }
    }

    // 支持自定义Headers
    fun play(url: String, headers: Map<String, String> = emptyMap()) {
        currentUrl = url
        retryCount = 0
        exoPlayer?.let { player ->
            val dataSourceFactory = DefaultHttpDataSource.Factory()
                .setDefaultRequestProperties(headers)
            val mediaSource = if (url.endsWith(".m3u8") || url.contains(".m3u8?")) {
                HlsMediaSource.Factory(dataSourceFactory).createMediaSource(MediaItem.fromUri(url))
            } else {
                ProgressiveMediaSource.Factory(dataSourceFactory).createMediaSource(MediaItem.fromUri(url))
            }
            player.setMediaSource(mediaSource)
            player.prepare()
            player.playWhenReady = true
        }
    }

    // 切换硬解/软解
    fun setDecoderPriority(useHardware: Boolean) {
        // 需要重建播放器，此处略
    }

    // 设置画面比例
    fun setAspectRatio(aspectRatio: String) {
        // 1:1, 4:3, 16:9, etc.
        exoPlayer?.videoScalingMode = when (aspectRatio) {
            "16:9" -> C.VIDEO_SCALING_MODE_SCALE_TO_FIT
            "4:3" -> C.VIDEO_SCALING_MODE_SCALE_TO_FIT
            else -> C.VIDEO_SCALING_MODE_DEFAULT
        }
    }

    fun pause() { exoPlayer?.pause() }
    fun resume() { exoPlayer?.play() }
    fun release() { exoPlayer?.release(); exoPlayer = null }
}
