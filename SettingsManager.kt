package com.ku9.player

import android.content.Context
import android.content.SharedPreferences

object SettingsManager {
    private const val PREF_NAME = "ku9_prefs"
    private lateinit var prefs: SharedPreferences

    fun init(context: Context) {
        prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    }

    fun isFavorite(channelId: String): Boolean {
        return prefs.getBoolean("fav_$channelId", false)
    }

    fun toggleFavorite(channelId: String) {
        val current = isFavorite(channelId)
        prefs.edit().putBoolean("fav_$channelId", !current).apply()
    }
}
