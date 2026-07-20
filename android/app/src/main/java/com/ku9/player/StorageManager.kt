package com.ku9.player.utils

import android.content.Context
import android.os.Environment
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

object StorageManager {
    private const val ROOT_DIR = "酷9"
    
    // 所有子目录
    val localData: File by lazy { getOrCreateSubDir("localData") }
    val backup: File by lazy { getOrCreateSubDir("backup") }
    val download: File by lazy { getOrCreateSubDir("download") }
    val videoFile: File by lazy { getOrCreateSubDir("videoFile") }
    val configuration: File by lazy { getOrCreateSubDir("configuration") }
    val logo: File by lazy { getOrCreateSubDir("logo") }
    val epgCache: File by lazy { getOrCreateSubDir("epgCache") }
    val js: File by lazy { getOrCreateSubDir("js") }
    val py: File by lazy { getOrCreateSubDir("py") }
    val webviewJscode: File by lazy { getOrCreateSubDir("webviewJscode") }

    private fun getOrCreateSubDir(subDir: String): File {
        val dir = File(Environment.getExternalStorageDirectory(), "$ROOT_DIR/$subDir")
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    // 保存文本文件到指定目录
    fun saveTextToFile(content: String, dir: File, fileName: String): Boolean {
        return try {
            val file = File(dir, fileName)
            file.writeText(content)
            true
        } catch (e: Exception) {
            false
        }
    }

    // 从文件读取文本
    fun readTextFromFile(file: File): String? {
        return try {
            file.readText()
        } catch (e: Exception) { null }
    }

    // 复制资源文件到目录（例如从 assets 复制默认配置）
    fun copyAssetToFile(context: Context, assetPath: String, targetDir: File, targetFileName: String): Boolean {
        return try {
            val inputStream = context.assets.open(assetPath)
            val outFile = File(targetDir, targetFileName)
            outFile.outputStream().use { output ->
                inputStream.copyTo(output)
            }
            true
        } catch (e: Exception) { false }
    }

    // 获取目录下所有文件（按修改时间排序）
    fun listFilesSortedByDate(dir: File): List<File> {
        return dir.listFiles()?.sortedByDescending { it.lastModified() } ?: emptyList()
    }

    // 删除过期缓存（保留最近 N 个）
    fun cleanOldFiles(dir: File, maxCount: Int) {
        val files = dir.listFiles()?.sortedBy { it.lastModified() } ?: return
        if (files.size > maxCount) {
            files.take(files.size - maxCount).forEach { it.delete() }
        }
    }
}
