package com.ku9.player

data class Channel(
    val id: String = "",
    val name: String = "",
    val url: String = "",
    val backupUrls: List<String> = emptyList(),  // 备用源
    val logoUrl: String = "",                    // 台标
    val epgUrl: String = "",                     // EPG URL
    val headers: Map<String, String> = emptyMap(), // 自定义请求头
    val groupId: String = ""                     // 所属分组
)
