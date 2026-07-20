// 在 PlayerManager.kt 中添加/替换以下方法

private var useHardwareDecoder = true

fun setDecoderPriority(useHardware: Boolean) {
    this.useHardwareDecoder = useHardware
    // 需要重建播放器才能生效
    currentUrl?.let { url ->
        release()
        init(context)
        play(url, emptyMap())
    }
}

// 修改 init 方法，加入解码器配置
fun init(context: Context) {
    if (exoPlayer == null) {
        val trackSelector = DefaultTrackSelector(context).apply {
            setParameters(
                buildUponParameters()
                    .setHardwareCodecEnabled(useHardwareDecoder)
            )
        }
        exoPlayer = ExoPlayer.Builder(context)
            .setTrackSelector(trackSelector)
            .build()
            .apply {
                addListener(object : Player.Listener {
                    // ... 你现有的监听器代码 ...
                })
            }
    }
}
