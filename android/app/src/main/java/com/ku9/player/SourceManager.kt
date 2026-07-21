package com.ku9.player

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.net.URL

class SourceManager(private val context: Context) {
    data class Source(val name: String, val url: String, val type: Type, var enabled: Boolean = true) {
        enum class Type { M3U, TXT }
    }

    private val _sources = mutableListOf<Source>()
    val sources: List<Source> get() = _sources
    private var currentIndex = 0
    private var _groups: List<Group> = emptyList()
    val groups: List<Group> get() = _groups

    init {
        _sources.add(Source("Sintel测试", "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8", Source.Type.M3U))
        _sources.add(Source("BigBuckBunny", "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8", Source.Type.M3U))
    }

    suspend fun addSource(name: String, url: String, type: Source.Type): Boolean {
        return try { _sources.add(Source(name, url, type)); true } catch (_: Exception) { false }
    }

    suspend fun loadSource(index: Int): Boolean {
        if (index !in _sources.indices) return false
        currentIndex = index
        val src = _sources[index]
        return withContext(Dispatchers.IO) {
            try {
                val content = if (src.url.startsWith("http")) URL(src.url).readText() else File(src.url).readText()
                // 显式指定类型，避免推断歧义
                val parsedGroups: List<Group> = when (src.type) {
                    Source.Type.M3U -> M3UParser().parse(content)
                    Source.Type.TXT -> {
                        val chs: List<Channel> = TXTParser().parse(content)
                        listOf(Group("默认", chs))
                    }
                }
                _groups = parsedGroups
                true
            } catch (_: Exception) { false }
        }
    }

    suspend fun switchToNext(): Boolean {
        if (_sources.isEmpty()) return false
        val next = (currentIndex + 1) % _sources.size
        return loadSource(next)
    }

    fun getAllChannels(): List<Channel> = _groups.flatMap { it.channels }
    fun search(query: String): List<Channel> = getAllChannels().filter { it.name.contains(query, ignoreCase = true) }
    fun toggleFavorite(ch: Channel) { ch.isFavorite = !ch.isFavorite }
    fun getFavorites(): List<Channel> = getAllChannels().filter { it.isFavorite }
}
