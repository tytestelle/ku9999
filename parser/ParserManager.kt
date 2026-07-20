package com.ku9.player.parser

import com.ku9.player.data.Channel

object ParserManager {
    fun parse(content: String): List<Channel> {
        return when {
            content.contains("#EXTM3U") || content.contains("#EXTINF") -> M3UParser.parse(content)
            else -> TXTParser.parse(content)
        }
    }
}
