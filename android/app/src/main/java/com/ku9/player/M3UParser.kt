package com.ku9.player

class M3UParser {
    fun parse(content: String): List<Channel> {
        val channels = mutableListOf<Channel>()
        val lines = content.lines()
        var currentName = ""
        for (line in lines) {
            if (line.startsWith("#EXTINF:")) {
                val namePart = line.substringAfter(",")
                currentName = namePart.trim()
            } else if (line.isNotEmpty() && !line.startsWith("#")) {
                val url = line.trim()
                if (url.isNotEmpty() && currentName.isNotEmpty()) {
                    channels.add(Channel(name = currentName, url = url))
                    currentName = ""
                }
            }
        }
        return channels
    }
}
