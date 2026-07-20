package com.ku9.player.parser

import com.ku9.player.data.Channel

object TXTParser {
    fun parse(content: String): List<Channel> {
        val channels = mutableListOf<Channel>()
        val lines = content.split("\n")
        var currentGroup = "未分组"
        for (line in lines) {
            val trimmed = line.trim()
            if (trimmed.isEmpty() || trimmed.startsWith("//") || trimmed.startsWith("#")) continue
            if (trimmed.contains(",#genre#")) {
                currentGroup = trimmed.split(",")[0].trim()
                continue
            }
            val parts = trimmed.split(",", limit = 2)
            if (parts.size == 2) {
                val name = parts[0].trim()
                val urlPart = parts[1].trim()
                // 处理多源
                val urls = urlPart.split("|").map { it.trim() }
                val primary = urls.firstOrNull() ?: urlPart
                val backups = urls.drop(1).toMutableList()
                if (primary.isNotEmpty()) {
                    channels.add(Channel(name, primary, currentGroup, "", "", backups))
                }
            }
        }
        return channels
    }
}
