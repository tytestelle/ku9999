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
    private var currentHeaders: Map<String, String> = emptyMap()
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

            trackSelector = DefaultTrackSelector(context).apply {
                setParameters(
                    buildUponParameters()
                        .setHardwareCodecEnabled(isHardwareDecoder)
                        .setMaxVideoSize(1920, 1080)
                )
            }
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

    fun pause() { exoPlayer?.pause() }
    fun resume() { exoPlayer?.play() }
    fun stop() { exoPlayer?.stop() }
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
    fun seekTo(positionMs: Long) { exoPlayer?.seekTo(positionMs) }
    fun getCurrentPosition(): Long = exoPlayer?.currentPosition ?: 0
    fun getDuration(): Long = exoPlayer?.duration ?: 0
    fun isPlaying(): Boolean = exoPlayer?.isPlaying ?: false

    fun switchDecoder(useHardware: Boolean) {
        if (isHardwareDecoder == useHardware) return
        isHardwareDecoder = useHardware
        currentUrl?.let { url ->
            val position = getCurrentPosition()
            release()
            isReleased.set(false)
            play(url, currentHeaders)
            if (position > 0) exoPlayer?.seekTo(position)
        }
    }

    fun setAspectRatio(ratio: String) {
        val player = exoPlayer ?: return
        val scalingMode = when (ratio) {
            "fill" -> C.VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING
            else -> C.VIDEO_SCALING_MODE_SCALE_TO_FIT
        }
        player.setVideoScalingMode(scalingMode)
    }

    fun isUsingHardwareDecoder(): Boolean = isHardwareDecoder
    fun addListener(listener: Player.Listener) { exoPlayer?.addListener(listener) }
    fun removeListener(listener: Player.Listener) { exoPlayer?.removeListener(listener) }
}
