package com.ku9.player

import android.net.Uri
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException

class SourceManager {
    var channels: List<Channel> = emptyList()
    var groups: List<Group> = emptyList()
    private val gson = Gson()

    // 多源订阅列表
    var subscriptions: List<Subscription> = emptyList()
        private set

    suspend fun loadData() = withContext(Dispatchers.IO) {
        try {
            // 从网络加载订阅列表，再依次加载每个订阅源
            // 这里简化：直接加载一个示例 URL
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
            // 加载本地缓存或示例数据
            channels = listOf(
                Channel("1", "CCTV-1", "http://example.com/1", backupUrls = listOf("http://backup1.com")),
                Channel("2", "CCTV-2", "http://example.com/2"),
                Channel("3", "CCTV-3", "http://example.com/3")
            )
            groups = listOf(
                Group("g1", "央视", channels),
                Group("g2", "卫视", emptyList())
            )
        }
    }

    // 读取本地文件（U盘或Download目录）
    suspend fun loadLocalFile(uri: Uri): String? {
        return withContext(Dispatchers.IO) {
            try {
                val inputStream = NetworkUtils.context?.contentResolver?.openInputStream(uri)
                inputStream?.bufferedReader().use { it?.readText() }
            } catch (e: Exception) { null }
        }
    }

    // 添加订阅
    fun addSubscription(sub: Subscription) {
        subscriptions = subscriptions + sub
        // 保存到 Preferences
    }
}
