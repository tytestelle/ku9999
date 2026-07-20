package com.ku9.player

import android.content.Context
import android.content.SharedPreferences

object SettingsManager {
    private lateinit var prefs: SharedPreferences

    fun init(context: Context) {
        prefs = context.getSharedPreferences("ku9_settings", Context.MODE_PRIVATE)
    }

    fun isHardwareDecoder(): Boolean = prefs.getBoolean("hardware_decoder", true)
    fun setHardwareDecoder(enabled: Boolean) = prefs.edit().putBoolean("hardware_decoder", enabled).apply()

    fun getEpgUrl(): String = prefs.getString("epg_url", "") ?: ""
    fun saveEpgUrl(url: String) = prefs.edit().putString("epg_url", url).apply()

    fun getFavorites(): Set<String> = prefs.getStringSet("favorites", emptySet()) ?: emptySet()
    fun saveFavorites(set: Set<String>) = prefs.edit().putStringSet("favorites", set).apply()

    fun getSourceUrl(): String = prefs.getString("source_url", "") ?: ""
    fun saveSourceUrl(url: String) = prefs.edit().putString("source_url", url).apply()
}
