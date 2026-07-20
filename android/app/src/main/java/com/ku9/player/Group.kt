package com.ku9.player

data class Group(
    val id: String = "",
    val name: String = "",
    val channels: List<Channel> = emptyList(), // 添加泛型 <Channel>
    val subGroups: List<Group> = emptyList() // 二级分组 - 添加泛型 <Group>
)
