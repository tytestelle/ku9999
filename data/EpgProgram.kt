package com.ku9.player.data

data class EpgProgram(
    val start: Long,
    val end: Long,
    val title: String,
    val description: String = "",
    val channelId: String = ""
)
