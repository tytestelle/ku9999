package com.ku9.player

import org.xmlpull.v1.XmlPullParserFactory
import java.io.InputStream
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*

data class EPGProgram(val title: String, val startTime: Date, val endTime: Date, val desc: String = "")

class EPGManager {
    suspend fun loadEPG(url: String): List<EPGProgram> {
        return if (url.isEmpty()) {
            // 模拟数据
            listOf(
                EPGProgram("新闻联播", Date(), Date(System.currentTimeMillis() + 30*60*1000), "今日新闻")
            )
        } else {
            try {
                val inputStream = URL(url).openStream()
                parseXML(inputStream)
            } catch (e: Exception) {
                e.printStackTrace()
                emptyList()
            }
        }
    }

    private fun parseXML(inputStream: InputStream): List<EPGProgram> {
        val programs = mutableListOf<EPGProgram>()
        val factory = XmlPullParserFactory.newInstance()
        val parser = factory.newPullParser()
        parser.setInput(inputStream, "UTF-8")
        var eventType = parser.eventType
        var currentTitle = ""
        var currentStart = ""
        var currentEnd = ""
        var currentDesc = ""
        while (eventType != org.xmlpull.v1.XmlPullParser.END_DOCUMENT) {
            when (eventType) {
                org.xmlpull.v1.XmlPullParser.START_TAG -> {
                    when (parser.name) {
                        "programme" -> {
                            currentStart = parser.getAttributeValue(null, "start")
                            currentEnd = parser.getAttributeValue(null, "stop")
                        }
                        "title" -> currentTitle = parser.nextText()
                        "desc" -> currentDesc = parser.nextText()
                    }
                }
                org.xmlpull.v1.XmlPullParser.END_TAG -> {
                    if (parser.name == "programme") {
                        val sdf = SimpleDateFormat("yyyyMMddHHmmss Z", Locale.getDefault())
                        val start = sdf.parse(currentStart.replace(" ", "+"))
                        val end = sdf.parse(currentEnd.replace(" ", "+"))
                        start?.let { end?.let {
                            programs.add(EPGProgram(currentTitle, it, end, currentDesc))
                        } }
                        currentTitle = ""
                        currentStart = ""
                        currentEnd = ""
                        currentDesc = ""
                    }
                }
            }
            eventType = parser.next()
        }
        return programs
    }
}
