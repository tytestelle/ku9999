package com.ku9.player

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.IOException

class SourceManager {
    // 改为 public var，允许外部赋值
    var channels: List<Channel> = emptyList()
    var groups: List<Group> = emptyList()

    private val gson = Gson()

    suspend fun loadData() = withContext(Dispatchers.IO) {
        try {
            val json = NetworkUtils.fetchJson("https://example.com/source.json") // 替换为真实地址
            val type = object : TypeToken<Map<String, List<Any>>>() {}.type
            val result: Map<String, List<Any>> = gson.fromJson(json, type)
            // 解析 channels 和 groups
            // 示例：
            // channels = result["channels"]?.map { Gson().fromJson(it.toString(), Channel::class.java) } ?: emptyList()
            // groups = result["groups"]?.map { Gson().fromJson(it.toString(), Group::class.java) } ?: emptyList()
        } catch (e: IOException) {
            e.printStackTrace()
        }
    }

    // 其他方法...
}
