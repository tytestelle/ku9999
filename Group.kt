package com.ku9.player

data class Group(
    val id: String = "",
    val name: String = "",
    val channels: List<Channel> = emptyList()
)
