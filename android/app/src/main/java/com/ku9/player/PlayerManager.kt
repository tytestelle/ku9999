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
    private var currentHeaders: Map<String, String> = emptyMap() // 添加泛型 <String, String>
    private var isHardwareDecoder = true
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
            val dataSourceFactory = DefaultHttpDataSource.Factory()
                .setAllowCrossProtocolRedirects(true)
                .setConnectTimeoutMs(10000)
                .setReadTimeoutMs(10000)
                .setDefaultRequestProperties(currentHeaders)

            // media3 中使用 DefaultTrackSelector.Builder 设置硬件解码
            trackSelector = DefaultTrackSelector(context)
            // 注意：media3 中 setHardwareCodecEnabled 已移至 Parameters.Builder
            // 使用 buildUponParameters 来设置
            trackSelector?.setParameters(
                trackSelector?.buildUponParameters()?.apply {
                    // 硬件解码在 media3 中通过 setMaxVideoSize 等方式控制
                    // 或使用 DefaultTrackSelector.Parameters.Builder
                }?.build() ?: DefaultTrackSelector.Parameters.Builder(context).build()
            )

            val loadErrorHandlingPolicy = DefaultLoadErrorHandlingPolicy(MAX_RETRY_COUNT)

            exoPlayer = ExoPlayer.Builder(context)
                .setTrackSelector(trackSelector)
                .setLoadErrorHandlingPolicy(loadErrorHandlingPolicy)
                .build()
                .apply {
                    addListener(playerListener)
                    // setVideoScalingMode 在 media3 中已移至 VideoSize 或通过 TrackSelector 控制
                }
        }
        return exoPlayer!!
    }

    fun play(url: String, headers: Map<String, String> = emptyMap()) { // 添加泛型 <String, String>
        if (isReleased.get()) return
        currentUrl = url
        currentHeaders = headers
        val player = initPlayer()
        val mediaSource = buildMediaSource(url, headers)
        player.setMediaSource(mediaSource)
        player.prepare()
        player.play()
    }

    private fun buildMediaSource(url: String, headers: Map<String, String>): MediaSource { // 添加泛型 <String, String>
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
        trackSelector = null
    }

    fun seekTo(positionMs: Long) {
        exoPlayer?.seekTo(positionMs)
    }
}
