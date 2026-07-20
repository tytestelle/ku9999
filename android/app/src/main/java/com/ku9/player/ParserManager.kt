package com.ku9.player

class ParserManager {

    fun parseM3U(content: String): List<Group> { // 添加泛型 <Group>
        return M3UParser().parse(content)
    }

    // 可添加其他格式解析
}
