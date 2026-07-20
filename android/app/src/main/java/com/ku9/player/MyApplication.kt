package com.ku9.player

import android.app.Application

class MyApplication : Application() {
    lateinit var playerManager: PlayerManager

    override fun onCreate() {
        super.onCreate()
        playerManager = PlayerManager(this)
    }
}
