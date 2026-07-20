package com.ku9.player.data

data class Channel(
    var name: String,
    var url: String,
    var group: String = "未分组",
    var logo: String = "",
    var epg: String = "",
    var backupUrls: MutableList<String> = mutableListOf()   // 备用源
)
