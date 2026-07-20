package com.ku9.player

import android.os.Bundle
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.PlaybackException
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.ui.PlayerView
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.ku9.player.data.Channel
import com.ku9.player.manager.SourceManager
import com.ku9.player.parser.*
import com.ku9.player.utils.Preferences
import com.ku9.player.utils.StorageManager
import com.ku9.player.utils.showToast
import kotlinx.coroutines.*

class MainActivity : AppCompatActivity() {

    private lateinit var playerView: PlayerView
    private lateinit var channelList: RecyclerView
    private lateinit var groupList: RecyclerView
    private lateinit var loadingOverlay: View
    private lateinit var loadingText: TextView
    private lateinit var tvNowPlaying: TextView
    private lateinit var tvChannelCount: TextView
    private lateinit var btnImport: ImageButton
    private lateinit var btnFullscreen: ImageButton
    private lateinit var seekBarVolume: SeekBar
    private lateinit var btnPrev: ImageButton
    private lateinit var btnPlayPause: ImageButton
    private lateinit var btnNext: ImageButton

    private lateinit var player: ExoPlayer
    private lateinit var channelAdapter: ChannelAdapter
    private lateinit var groupAdapter: GroupAdapter

    private var currentGroup = "全部"
    private var currentPosition = -1
    private val prefs by lazy { Preferences(this) }
    private val scope = CoroutineScope(Dispatchers.IO + Job())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        initViews()
        initPlayer()
        setupListeners()
        // 初始化存储目录（创建酷9目录结构）
        StorageManager.apply { 
            // 这些目录会在首次访问时自动创建
        }
        // 加载源
        loadDefaultSource()
    }

    private fun initViews() {
        playerView = findViewById(R.id.playerView)
        channelList = findViewById(R.id.channelList)
        groupList = findViewById(R.id.groupList)
        loadingOverlay = findViewById(R.id.loadingOverlay)
        loadingText = findViewById(R.id.loadingText)
        tvNowPlaying = findViewById(R.id.tvNowPlaying)
        tvChannelCount = findViewById(R.id.tvChannelCount)
        btnImport = findViewById(R.id.btnImport)
        btnFullscreen = findViewById(R.id.btnFullscreen)
        seekBarVolume = findViewById(R.id.seekBarVolume)
        btnPrev = findViewById(R.id.btnPrev)
        btnPlayPause = findViewById(R.id.btnPlayPause)
        btnNext = findViewById(R.id.btnNext)

        channelList.layoutManager = LinearLayoutManager(this)
        groupList.layoutManager = LinearLayoutManager(this)
    }

    private fun initPlayer() {
        player = ExoPlayer.Builder(this).build()
        playerView.player = player
        player.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(playbackState: Int) {
                if (playbackState == Player.STATE_READY) {
                    hideLoading()
                    btnPlayPause.setImageResource(android.R.drawable.ic_media_pause)
                }
            }
            override fun onPlayerError(error: PlaybackException) {
                hideLoading()
                showToast("播放错误: ${error.message}")
                if (prefs.getBoolean("reconnect", true)) {
                    switchToNextChannel()
                }
            }
        })
        seekBarVolume.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                if (fromUser) {
                    player.volume = progress / 100f
                    prefs.putInt("volume", progress)
                }
            }
            override fun onStartTrackingTouch(seekBar: SeekBar?) {}
            override fun onStopTrackingTouch(seekBar: SeekBar?) {}
        })
        val vol = prefs.getInt("volume", 100)
        seekBarVolume.progress = vol
        player.volume = vol / 100f
    }

    private fun setupListeners() {
        btnImport.setOnClickListener { showImportDialog() }
        btnFullscreen.setOnClickListener { toggleFullscreen() }
        btnPrev.setOnClickListener { switchToPrevChannel() }
        btnPlayPause.setOnClickListener { togglePlayPause() }
        btnNext.setOnClickListener { switchToNextChannel() }
    }

    private fun loadDefaultSource() {
        // 先尝试加载保存的配置
        val config = SourceManager.loadConfiguration()
        val savedUrl = config?.get("sourceUrl") ?: prefs.getString("source_url", "")
        if (savedUrl.isNotEmpty()) {
            loadNetworkSource(savedUrl)
            return
        }
        // 尝试加载本地文件（localData 目录下的文件）
        val localFiles = SourceManager.getLocalSourceFiles()
        if (localFiles.isNotEmpty()) {
            // 加载最近修改的那个
            val latest = localFiles.maxByOrNull { it.lastModified() }
            latest?.let {
                val channels = SourceManager.loadLocalFile(it)
                displayChannels(channels)
                showToast("加载本地源: ${it.name}")
                return
            }
        }
        // 都没有，使用内置测试源
        val builtin = """
            #EXTM3U
            #EXTINF:-1 group-title="测试",测试1
            https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8
            #EXTINF:-1 group-title="测试",测试2
            https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8
        """.trimIndent()
        val parsed = M3UParser.parse(builtin)
        SourceManager.channels = parsed
        displayChannels(parsed)
    }

    private fun loadNetworkSource(url: String) {
        showLoading("加载直播源...")
        scope.launch {
            SourceManager.loadNetworkSource(
                url = url,
                onSuccess = { channels ->
                    withContext(Dispatchers.Main) {
                        hideLoading()
                        displayChannels(channels)
                        SourceManager.saveConfiguration(url)
                        prefs.putString("source_url", url)
                        showToast("加载成功: ${channels.size} 个频道")
                    }
                },
                onError = { error ->
                    withContext(Dispatchers.Main) {
                        hideLoading()
                        showToast("加载失败: $error")
                    }
                }
            )
        }
    }

    private fun displayChannels(channels: List<Channel>) {
        // 更新分组
        val groups = channels.map { it.group }.distinct().sorted()
        val groupListData = listOf("全部") + groups
        if (::groupAdapter.isInitialized) {
            groupAdapter.updateData(groupListData)
        } else {
            groupAdapter = GroupAdapter(groupListData) { group ->
                currentGroup = group
                filterChannels()
            }
            groupList.adapter = groupAdapter
        }
        // 更新频道列表
        filterChannels()
        tvChannelCount.text = "共 ${channels.size} 个频道"
    }

    private fun filterChannels() {
        val filtered = if (currentGroup == "全部") SourceManager.channels else SourceManager.channels.filter { it.group == currentGroup }
        if (::channelAdapter.isInitialized) {
            channelAdapter.updateData(filtered)
        } else {
            channelAdapter = ChannelAdapter(filtered) { position ->
                val originalIndex = SourceManager.channels.indexOfFirst { it == filtered[position] }
                if (originalIndex >= 0) playChannel(originalIndex)
            }
            channelList.adapter = channelAdapter
        }
        tvChannelCount.text = "共 ${filtered.size} 个频道"
    }

    private fun playChannel(position: Int) {
        if (position !in SourceManager.channels.indices) return
        currentPosition = position
        val channel = SourceManager.channels[position]
        showLoading("加载 ${channel.name} ...")
        val mediaItem = MediaItem.fromUri(channel.url)
        player.setMediaItem(mediaItem)
        player.prepare()
        player.playWhenReady = true
        tvNowPlaying.text = channel.name
        prefs.putString("last_channel", channel.name)
        btnPlayPause.setImageResource(android.R.drawable.ic_media_pause)
        // 高亮当前频道
        channelAdapter.highlightItem(position)
    }

    private fun switchToPrevChannel() {
        if (SourceManager.channels.isEmpty()) return
        if (currentPosition <= 0) currentPosition = SourceManager.channels.size
        playChannel((currentPosition - 1) % SourceManager.channels.size)
    }

    private fun switchToNextChannel() {
        if (SourceManager.channels.isEmpty()) return
        playChannel((currentPosition + 1) % SourceManager.channels.size)
    }

    private fun togglePlayPause() {
        if (player.isPlaying) {
            player.pause()
            btnPlayPause.setImageResource(android.R.drawable.ic_media_play)
        } else {
            player.playWhenReady = true
            btnPlayPause.setImageResource(android.R.drawable.ic_media_pause)
        }
    }

    private fun showImportDialog() {
        val items = arrayOf("从网络加载", "从本地文件导入", "粘贴内容", "选择本地源文件")
        MaterialAlertDialogBuilder(this)
            .setTitle("导入直播源")
            .setItems(items) { _, which ->
                when (which) {
                    0 -> showUrlInputDialog()
                    1 -> showFilePicker()
                    2 -> showPasteDialog()
                    3 -> showLocalSourceSelector()
                }
            }
            .show()
    }

    private fun showUrlInputDialog() {
        val input = EditText(this)
        input.hint = "输入 M3U/TXT 网址"
        MaterialAlertDialogBuilder(this)
            .setTitle("输入网址")
            .setView(input)
            .setPositiveButton("加载") { _, _ ->
                val url = input.text.toString()
                if (url.isNotEmpty()) loadNetworkSource(url)
            }
            .setNegativeButton("取消", null)
            .show()
    }

    private fun showFilePicker() {
        val intent = android.content.Intent(android.content.Intent.ACTION_GET_CONTENT).apply {
            type = "*/*"
            addCategory(android.content.Intent.CATEGORY_OPENABLE)
        }
        startActivityForResult(intent, REQUEST_IMPORT_FILE)
    }

    private fun showPasteDialog() {
        val input = EditText(this)
        input.hint = "粘贴 M3U/TXT 内容"
        input.minLines = 10
        MaterialAlertDialogBuilder(this)
            .setTitle("粘贴内容")
            .setView(input)
            .setPositiveButton("解析") { _, _ ->
                val content = input.text.toString()
                if (content.isNotEmpty()) {
                    val parsed = when {
                        content.contains("#EXTM3U") || content.contains("#EXTINF") -> M3UParser.parse(content)
                        else -> TXTParser.parse(content)
                    }
                    SourceManager.channels = parsed
                    displayChannels(parsed)
                    SourceManager.saveConfiguration("")
                    showToast("解析成功: ${parsed.size} 个频道")
                }
            }
            .setNegativeButton("取消", null)
            .show()
    }

    private fun showLocalSourceSelector() {
        val files = SourceManager.getLocalSourceFiles()
        if (files.isEmpty()) {
            showToast("localData 目录中没有源文件")
            return
        }
        val fileNames = files.map { it.name }.toTypedArray()
        MaterialAlertDialogBuilder(this)
            .setTitle("选择本地源")
            .setItems(fileNames) { _, which ->
                val file = files[which]
                val channels = SourceManager.loadLocalFile(file)
                displayChannels(channels)
                showToast("加载: ${file.name}")
            }
            .show()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_IMPORT_FILE && resultCode == RESULT_OK) {
            val uri = data?.data ?: return
            val content = contentResolver.openInputStream(uri)?.bufferedReader()?.readText()
            if (content != null) {
                val parsed = when {
                    content.contains("#EXTM3U") || content.contains("#EXTINF") -> M3UParser.parse(content)
                    else -> TXTParser.parse(content)
                }
                SourceManager.channels = parsed
                displayChannels(parsed)
                // 保存到 localData
                val fileName = uri.lastPathSegment ?: "imported.txt"
                StorageManager.saveTextToFile(content, StorageManager.localData, fileName)
                showToast("导入成功: ${parsed.size} 个频道")
            } else {
                showToast("读取文件失败")
            }
        }
    }

    private fun toggleFullscreen() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
            if (window.decorView.systemUiVisibility and View.SYSTEM_UI_FLAG_FULLSCREEN == 0) {
                window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)
                supportActionBar?.hide()
            } else {
                window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
                supportActionBar?.show()
            }
        }
    }

    private fun showLoading(msg: String) {
        loadingOverlay.visibility = View.VISIBLE
        loadingText.text = msg
    }

    private fun hideLoading() {
        loadingOverlay.visibility = View.GONE
    }

    override fun onDestroy() {
        super.onDestroy()
        player.release()
    }

    companion object {
        private const val REQUEST_IMPORT_FILE = 1001
    }
}
