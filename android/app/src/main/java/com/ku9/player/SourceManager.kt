package com.ku9.player

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.InputStream
import java.net.URL

/**
 * 直播源管理器：支持多源（M3U/TXT），本地文件/网络URL，源切换
 */
class SourceManager(private val context: Context) {

    data class Source(val name: String, val url: String, val type: SourceType) {
        enum class SourceType { M3U, TXT }
    }

    private val sources = mutableListOf<Source>()
    private var currentSourceIndex = 0
    private var currentGroups: List<Group> = emptyList()

    // 添加源
    suspend fun addSource(name: String, url: String, type: Source.SourceType): Boolean {
        return try {
            sources.add(Source(name, url, type))
            true
        } catch (e: Exception) {
            false
        }
    }

    // 加载指定索引的源
    suspend fun loadSource(index: Int): List<Group> {
        if (index !in sources.indices) return emptyList()
        currentSourceIndex = index
        val source = sources[index]
        return withContext(Dispatchers.IO) {
            try {
                val inputStream: InputStream = if (source.url.startsWith("http")) {
                    URL(source.url).openStream()
                } else {
                    File(source.url).inputStream()
                }
                val content = inputStream.bufferedReader().readText()
                inputStream.close()
                currentGroups = when (source.type) {
                    Source.SourceType.M3U -> M3UParser.parse(content)
                    Source.SourceType.TXT -> parseTXT(content)
                }
                currentGroups
            } catch (e: Exception) {
                e.printStackTrace()
                emptyList()
            }
        }
    }

    // 切换到下一个源（循环）
    suspend fun switchToNextSource(): List<Group>? {
        if (sources.isEmpty()) return null
        val nextIndex = (currentSourceIndex + 1) % sources.size
        return loadSource(nextIndex)
    }

    // 获取所有分组
    fun getCurrentGroups(): List<Group> = currentGroups

    // 获取所有源列表
    fun getSources(): List<Source> = sources

    // 获取当前源索引
    fun getCurrentSourceIndex(): Int = currentSourceIndex

    // 解析TXT格式（频道名,url）
    private fun parseTXT(content: String): List<Group> {
        val channels = content.lines()
            .mapNotNull { line ->
                val trimmed = line.trim()
                if (trimmed.isEmpty() || trimmed.startsWith("#")) return@mapNotNull null
                val parts = trimmed.split(",", limit = 2)
                if (parts.size >= 2) {
                    Channel(name = parts[0].trim(), url = parts[1].trim(), logo = "")
                } else null
            }
        return listOf(Group("默认", channels))
    }
}
