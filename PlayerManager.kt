package com.ku9.player

import android.content.Context
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.PlaybackException
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource

class PlayerManager {
    private var exoPlayer: ExoPlayer? = null

    fun init(context: Context) {
        if (exoPlayer == null) {
            exoPlayer = ExoPlayer.Builder(context).build()
            exoPlayer?.addListener(object : Player.Listener {
                override fun onPlayerError(error: PlaybackException) {
                    // 处理错误
                }
            })
        }
    }

    fun play(url: String) {
        exoPlayer?.let { player ->
            val dataSourceFactory = DefaultHttpDataSource.Factory()
            val mediaSource = HlsMediaSource.Factory(dataSourceFactory)
                .createMediaSource(MediaItem.fromUri(url))
            player.setMediaSource(mediaSource)
            player.prepare()
            player.playWhenReady = true
        }
    }

    fun pause() {
        exoPlayer?.pause()
    }

    fun release() {
        exoPlayer?.release()
        exoPlayer = null
    }
}
