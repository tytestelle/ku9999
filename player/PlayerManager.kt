package com.ku9.player.player

import android.content.Context
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.PlaybackException
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.source.dash.DashMediaSource
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource
import com.google.android.exoplayer2.ui.PlayerView

class PlayerManager(private val context: Context, private val playerView: PlayerView) {
    private val player: ExoPlayer = ExoPlayer.Builder(context).build()
    private var listener: PlayerListener? = null

    init {
        playerView.player = player
        player.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(playbackState: Int) {
                when (playbackState) {
                    Player.STATE_READY -> listener?.onReady()
                    Player.STATE_ENDED -> { /* 可处理 */ }
                }
            }
            override fun onPlayerError(error: PlaybackException) {
                listener?.onError(error)
            }
        })
    }

    fun play(url: String) {
        val mediaSource = when {
            url.contains(".m3u8") || url.contains("m3u") -> {
                HlsMediaSource.Factory(DefaultHttpDataSource.Factory())
                    .createMediaSource(MediaItem.fromUri(url))
            }
            url.contains(".mpd") -> {
                DashMediaSource.Factory(DefaultHttpDataSource.Factory())
                    .createMediaSource(MediaItem.fromUri(url))
            }
            else -> {
                ProgressiveMediaSource.Factory(DefaultHttpDataSource.Factory())
                    .createMediaSource(MediaItem.fromUri(url))
            }
        }
        player.setMediaSource(mediaSource)
        player.prepare()
        player.playWhenReady = true
    }

    fun pause() = player.pause()
    fun resume() = player.playWhenReady = true
    fun stop() = player.stop()
    fun release() = player.release()
    fun setVolume(vol: Float) { player.volume = vol }
    val isPlaying: Boolean get() = player.isPlaying

    fun setPlayerListener(listener: PlayerListener) {
        this.listener = listener
    }

    interface PlayerListener {
        fun onReady()
        fun onError(error: PlaybackException)
        fun onPlaybackStateChanged(state: Int)
    }
}
