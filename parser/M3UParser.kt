package com.ku9.player.parser

import com.ku9.player.data.Channel

object M3UParser {
    fun parse(content: String): List<Channel> {
        val channels = mutableListOf<Channel>()
        val lines = content.split("\n")
        var currentName = ""
        var currentGroup = "未分组"
        var currentLogo = ""
        var currentEpg = ""
        var currentBackups = mutableListOf<String>()
        var isParsingUrl = false
        var currentLine = 0

        while (currentLine < lines.size) {
            val line = lines[currentLine].trim()
            when {
                line.startsWith("#EXTINF:") -> {
                    currentName = extractName(line)
                    currentGroup = extractAttribute(line, "group-title") ?: "未分组"
                    currentLogo = extractAttribute(line, "tvg-logo") ?: ""
                    currentEpg = extractAttribute(line, "tvg-id") ?: ""
                    currentBackups.clear()
                    isParsingUrl = true
                }
                line.startsWith("#") -> { /* 忽略其他注释 */ }
                line.isNotEmpty() && isParsingUrl -> {
                    // 处理多源：URL可能用'|'分隔
                    val urls = line.split("|").map { it.trim() }
                    val primary = urls.firstOrNull() ?: line
                    val backups = urls.drop(1).toMutableList()
                    channels.add(Channel(
                        name = currentName,
                        url = primary,
                        group = currentGroup,
                        logo = currentLogo,
                        epg = currentEpg,
                        backupUrls = backups
                    ))
                    isParsingUrl = false
                }
            }
            currentLine++
        }
        return channels
    }

    private fun extractName(line: String): String {
        val match = Regex(""",([^,]+)$""").find(line)
        return match?.groupValues?.get(1)?.trim() ?: "未知"
    }

    private fun extractAttribute(line: String, attr: String): String? {
        val regex = Regex("""$attr="([^"]*)"""")
        return regex.find(line)?.groupValues?.get(1)
    }
}
