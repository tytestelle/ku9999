package com.ku9.player

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*

/**
 * EPG管理器：支持XMLTV格式，7天回看（通过日期偏移）
 */
class EPGManager {

    // 加载指定日期的EPG（offsetDays: 0今天，-1昨天，+1明天...）
    suspend fun loadEPG(xmlUrl: String, channelId: String, offsetDays: Int = 0): List<EpgProgram> =
        withContext(Dispatchers.IO) {
            try {
                val xml = URL(xmlUrl).readText()
                parseXMLTV(xml, channelId, offsetDays)
            } catch (e: Exception) {
                emptyList()
            }
        }

    private fun parseXMLTV(xml: String, channelId: String, offsetDays: Int): List<EpgProgram> {
        val list = mutableListOf<EpgProgram>()
        // 匹配指定频道的所有programme节点
        val regex = Regex("<programme[^>]*channel=\"$channelId\"[^>]*>.*?</programme>", RegexOption.DOTALL)
        val sdf = SimpleDateFormat("yyyyMMddHHmmss Z", Locale.getDefault())

        // 计算目标日期的起始和结束时间戳（用于过滤）
        val calendar = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, offsetDays) }
        val dayStart = calendar.apply { set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0) }.timeInMillis
        val dayEnd = dayStart + 24 * 60 * 60 * 1000

        regex.findAll(xml).forEach { match ->
            val block = match.value
            val title = Regex("<title>(.*?)</title>").find(block)?.groupValues?.get(1) ?: ""
            val start = Regex("start=\"(.*?)\"").find(block)?.groupValues?.get(1) ?: ""
            val end = Regex("end=\"(.*?)\"").find(block)?.groupValues?.get(1) ?: ""

            val startTime = try { sdf.parse(start.replace("+0000", " +0000"))?.time ?: 0 } catch (_: Exception) { 0 }
            val endTime = try { sdf.parse(end.replace("+0000", " +0000"))?.time ?: 0 } catch (_: Exception) { 0 }

            // 只保留当天的节目
            if (startTime >= dayStart && startTime < dayEnd) {
                list.add(EpgProgram(title, startTime, endTime, ""))
            }
        }
        return list.sortedBy { it.startTime }
    }
}
