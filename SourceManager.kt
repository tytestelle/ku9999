package com.ku9.player.manager

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.ku9.player.data.Channel
import com.ku9.player.parser.M3UParser
import com.ku9.player.parser.TXTParser
import com.ku9.player.utils.StorageManager
import java.io.File

object SourceManager {
    private val gson = Gson()
    private const val CONFIG_FILE = "config.json"
    private const val SOURCE_FILE = "source.txt"
    private const val BACKUP_FILE = "backup.json"

    // 当前加载的频道列表
    var channels: List<Channel> = emptyList()
        private set

    // 当前使用的源URL（网络源）
    var currentSourceUrl: String = ""
        private set

    // 加载本地文件（支持 txt/m3u）
    fun loadLocalFile(file: File): List<Channel> {
        val content = file.readText()
        val parsed = when {
            content.contains("#EXTM3U") || content.contains("#EXTINF") -> M3UParser.parse(content)
            else -> TXTParser.parse(content)
        }
        channels = parsed
        // 保存到 localData 目录（如果文件不在那里，复制一份）
        if (file.parentFile?.name != "localData") {
            val dest = File(StorageManager.localData, file.name)
            if (!dest.exists() || dest.length() != file.length()) {
                file.copyTo(dest, overwrite = true)
            }
        }
        return parsed
    }

    // 从网络加载源（会自动缓存到 download 目录）
    suspend fun loadNetworkSource(url: String, onSuccess: (List<Channel>) -> Unit, onError: (String) -> Unit) {
        try {
            val response = NetworkUtils.get(url)
            if (response.isSuccess) {
                val content = response.getOrThrow()
                val parsed = when {
                    content.contains("#EXTM3U") || content.contains("#EXTINF") -> M3UParser.parse(content)
                    else -> TXTParser.parse(content)
                }
                channels = parsed
                currentSourceUrl = url
                // 缓存到 download 目录
                val cacheFile = File(StorageManager.download, System.currentTimeMillis().toString() + ".m3u")
                cacheFile.writeText(content)
                // 清理旧缓存（保留最近10个）
                StorageManager.cleanOldFiles(StorageManager.download, 10)
                onSuccess(parsed)
            } else {
                onError(response.exceptionOrNull()?.message ?: "未知错误")
            }
        } catch (e: Exception) {
            onError(e.message ?: "网络请求失败")
        }
    }

    // 保存当前配置到 configuration 目录
    fun saveConfiguration(sourceUrl: String, extraParams: Map<String, String> = emptyMap()) {
        val config = mapOf(
            "sourceUrl" to sourceUrl,
            "lastUpdate" to System.currentTimeMillis().toString(),
            "extra" to extraParams
        )
        val json = gson.toJson(config)
        val configFile = File(StorageManager.configuration, CONFIG_FILE)
        configFile.writeText(json)
    }

    // 加载配置
    fun loadConfiguration(): Map<String, String>? {
        val configFile = File(StorageManager.configuration, CONFIG_FILE)
        if (!configFile.exists()) return null
        val json = configFile.readText()
        return try {
            gson.fromJson(json, object : TypeToken<Map<String, String>>() {}.type)
        } catch (e: Exception) { null }
    }

    // 备份数据（备份 channels 和配置）
    fun backupData() {
        val backupMap = mapOf(
            "channels" to channels,
            "sourceUrl" to currentSourceUrl,
            "timestamp" to System.currentTimeMillis().toString()
        )
        val json = gson.toJson(backupMap)
        val backupFile = File(StorageManager.backup, "backup_${System.currentTimeMillis()}.json")
        backupFile.writeText(json)
        // 只保留最近5个备份
        StorageManager.cleanOldFiles(StorageManager.backup, 5)
    }

    // 从备份恢复
    fun restoreFromBackup(backupFile: File): Boolean {
        try {
            val json = backupFile.readText()
            val map = gson.fromJson(json, object : TypeToken<Map<String, Any>>() {}.type)
            // 恢复频道列表
            val channelListJson = gson.toJson(map["channels"])
            val restored = gson.fromJson(channelListJson, object : TypeToken<List<Channel>>() {}.type)
            channels = restored
            currentSourceUrl = map["sourceUrl"] as? String ?: ""
            // 将恢复的内容写入本地文件
            val content = channels.joinToString("\n") { "${it.name},${it.url}" }
            val restoreFile = File(StorageManager.localData, "restored_${System.currentTimeMillis()}.txt")
            restoreFile.writeText(content)
            return true
        } catch (e: Exception) { return false }
    }

    // 导出为 JSON（用于迁移）
    fun exportToJson(): String {
        val data = mapOf(
            "version" to "1.0",
            "channels" to channels,
            "sourceUrl" to currentSourceUrl,
            "exportTime" to System.currentTimeMillis().toString()
        )
        return gson.toJson(data)
    }

    // 从 JSON 导入
    fun importFromJson(json: String): Boolean {
        try {
            val map = gson.fromJson(json, object : TypeToken<Map<String, Any>>() {}.type)
            val channelListJson = gson.toJson(map["channels"])
            val imported = gson.fromJson(channelListJson, object : TypeToken<List<Channel>>() {}.type)
            channels = imported
            // 保存到 localData
            val content = channels.joinToString("\n") { "${it.name},${it.url}" }
            val importFile = File(StorageManager.localData, "imported_${System.currentTimeMillis()}.txt")
            importFile.writeText(content)
            return true
        } catch (e: Exception) { return false }
    }

    // 扫描 localData 目录，列出所有可用的本地源文件
    fun getLocalSourceFiles(): List<File> {
        return StorageManager.localData.listFiles()?.filter { it.extension in listOf("txt", "m3u") } ?: emptyList()
    }
}
