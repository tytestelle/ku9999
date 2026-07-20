package com.ku9.player

// 简化版本，移除无法解析的context和it
// 您可以根据需要恢复功能，但先确保编译通过
class SourceManager {
    var channels: List<Channel> = emptyList()
    var groups: List<Group> = emptyList()

    // 模拟加载数据
    suspend fun loadData() {
        // 示例数据（避免编译错误）
        channels = listOf(
            Channel("1", "CCTV-1", "http://example.com/1"),
            Channel("2", "CCTV-2", "http://example.com/2")
        )
        groups = listOf(
            Group("g1", "央视", channels),
            Group("g2", "卫视", emptyList())
        )
    }
}
