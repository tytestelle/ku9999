package com.ku9.player

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.IOException

class SourceManager {
    // 公开可变的列表，便于外部更新
    var channels: List<Channel> = emptyList()
    var groups: List<Group> = emptyList()

    private val gson = Gson()

    suspend fun loadData() = withContext(Dispatchers.IO) {
        try {
            // 请替换为实际的 API 地址
            val json = NetworkUtils.fetchJson("https://example.com/source.json")
            // 假设返回格式为 { "channels": [...], "groups": [...] }
            val type = object : TypeToken<Map<String, List<Any>>>() {}.type
            val result: Map<String, List<Any>> = gson.fromJson(json, type)

            // 解析 channels（假设 Channel 有 id, name, url）
            val channelList = result["channels"]?.mapNotNull {
                try {
                    gson.fromJson(gson.toJson(it), Channel::class.java)
                } catch (e: Exception) { null }
            } ?: emptyList()

            // 解析 groups（假设 Group 有 id, name, channels）
            val groupList = result["groups"]?.mapNotNull {
                try {
                    gson.fromJson(gson.toJson(it), Group::class.java)
                } catch (e: Exception) { null }
            } ?: emptyList()

            channels = channelList
            groups = groupList
        } catch (e: IOException) {
            e.printStackTrace()
        }
    }
}
