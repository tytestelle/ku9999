package com.ku9.player

object M3UParser {
    fun parse(content: String): List<Group> {
        val groups = mutableMapOf<String, MutableList<Channel>>()
        var currentGroup = "默认"
        var channel: Channel? = null

        content.lines().forEach { line ->
            when {
                line.startsWith("#EXTINF:") -> {
                    val logo = line.substringAfter("tvg-logo=\"").substringBefore("\"")
                    val group = line.substringAfter("group-title=\"").substringBefore("\"")
                    val name = line.substringAfter(",").trim()
                    currentGroup = group.ifEmpty { "默认" }
                    channel = Channel(name, logo, "")
                }
                line.startsWith("http") && channel != null -> {
                    channel = channel!!.copy(url = line.trim())
                    groups.getOrPut(currentGroup) { mutableListOf() }.add(channel!!)
                    channel = null
                }
            }
        }
        return groups.map { Group(it.key, it.value) }
    }
}
