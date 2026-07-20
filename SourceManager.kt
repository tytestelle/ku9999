package com.ku9.player

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.IOException

class SourceManager {
    var channels: List<Channel> = emptyList()
    var groups: List<Group> = emptyList()

    private val gson = Gson()

    suspend fun loadData() = withContext(Dispatchers.IO) {
        try {
            // 这里替换为你的真实源地址，例如 M3U 或 JSON
            val json = NetworkUtils.fetchJson("https://example.com/source.json")
            val type = object : TypeToken<Map<String, List<Any>>>() {}.type
            val result: Map<String, List<Any>> = gson.fromJson(json, type)

            val channelList = result["channels"]?.mapNotNull {
                try { gson.fromJson(gson.toJson(it), Channel::class.java) } catch (e: Exception) { null }
            } ?: emptyList()
            val groupList = result["groups"]?.mapNotNull {
                try { gson.fromJson(gson.toJson(it), Group::class.java) } catch (e: Exception) { null }
            } ?: emptyList()

            channels = channelList
            groups = groupList
        } catch (e: IOException) {
            e.printStackTrace()
            // 加载失败时提供示例数据，让界面有内容
            channels = listOf(
                Channel("1", "CCTV-1", "http://example.com/1"),
                Channel("2", "CCTV-2", "http://example.com/2"),
                Channel("3", "CCTV-3", "http://example.com/3")
            )
            groups = listOf(
                Group("g1", "央视", channels),
                Group("g2", "卫视", emptyList())
            )
        }
    }
}
