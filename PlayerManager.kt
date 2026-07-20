package com.ku9.player

// 假设代码中有类似以下错误：
// val player = exoPlayer  // 如果只是赋值，不需要括号
// 只需确保赋值语句不是表达式即可。具体根据原始代码修正。

// 示例修正：
class PlayerManager {
    private var player: ExoPlayer? = null

    fun initPlayer(context: Context) {
        // 正确赋值
        player = ExoPlayer.Builder(context).build()
    }
}
