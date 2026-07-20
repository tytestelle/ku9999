package com.ku9.player

class TXTParser {
    fun parse(content: String): List<Channel> {
        val channels = mutableListOf<Channel>()
        val lines = content.lines()
        for (line in lines) {
            val trimmed = line.trim()
            if (trimmed.isNotEmpty()) {
                val parts = trimmed.split("#")
                if (parts.size == 2) {
                    channels.add(Channel(name = parts[0].trim(), url = parts[1].trim()))
                }
            }
        }
        return channels
    }
}
