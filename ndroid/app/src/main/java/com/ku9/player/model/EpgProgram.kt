package com.ku9.player

data class EpgProgram(
    val title: String,
    val startTime: Long,
    val endTime: Long,
    val desc: String
)
