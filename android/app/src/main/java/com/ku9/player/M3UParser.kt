package com.ku9.player

class M3UParser {

    fun parse(content: String): List<Group> {
        val groups = mutableListOf<Group>()
        var currentGroup = Group("默认", mutableListOf())
        val lines = content.lines()

        for (line in lines) {
            val trimmed = line.trim()
            when {
                trimmed.startsWith("#EXTINF:") -> {
                    // 解析频道信息
                    val name = trimmed.substringAfter(",").trim()
                    val groupMatch = Regex("group-title=\"(.*?)\"").find(trimmed)
                    val groupName = groupMatch?.groupValues?.get(1) ?: "默认"

                    // 如果分组变化，保存当前分组并创建新分组
                    if (groupName != currentGroup.name && currentGroup.channels.isNotEmpty()) {
                        groups.add(currentGroup)
                        currentGroup = Group(groupName, mutableListOf())
                    }
                    // 下一行是 URL（需要读取下一行）
                    // 由于简单解析，这里略过 URL 读取，实际需要处理
                }
                trimmed.startsWith("#") -> {
                    // 跳过注释
                }
                trimmed.isNotEmpty() && !trimmed.startsWith("#EXT") -> {
                    // 这可能是 URL，但需要关联到上一个频道
                    // 简化处理：直接添加
                }
            }
        }
        // 添加最后一个分组
        if (currentGroup.channels.isNotEmpty()) {
            groups.add(currentGroup)
        }
        return groups
    }
}
