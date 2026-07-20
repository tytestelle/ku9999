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
import com.ku9.player.parser.*
import com.ku9.player.player.PlayerManager
import com.ku9.player.ui.*
import com.ku9.player.utils.Preferences
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

    private lateinit var playerManager: PlayerManager
    private lateinit var channelAdapter: ChannelAdapter
    private lateinit var groupAdapter: GroupAdapter

    private var channels = mutableListOf<Channel>()
    private var currentGroup = "全部"
    private var currentPosition = -1
    private val prefs by lazy { Preferences(this) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        initViews()
        initPlayer()
        setupListeners()
        loadSettings()
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
        playerManager = PlayerManager(this, playerView)
        playerManager.setPlayerListener(object : PlayerManager.PlayerListener {
            override fun onReady() {
                hideLoading()
                btnPlayPause.setImageResource(android.R.drawable.ic_media_pause)
            }
            override fun onError(error: PlaybackException) {
                hideLoading()
                showToast("播放错误: ${error.message}")
                if (prefs.getBoolean("reconnect", true)) {
                    switchToNextChannel()
                }
            }
            override fun onPlaybackStateChanged(playbackState: Int) {
                if (playbackState == Player.STATE_ENDED || playbackState == Player.STATE_IDLE) {
                    btnPlayPause.setImageResource(android.R.drawable.ic_media_play)
                }
            }
        })
        seekBarVolume.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                if (fromUser) {
                    playerManager.setVolume(progress / 100f)
                    prefs.putInt("volume", progress)
                }
            }
            override fun onStartTrackingTouch(seekBar: SeekBar?) {}
            override fun onStopTrackingTouch(seekBar: SeekBar?) {}
        })
        val vol = prefs.getInt("volume", 100)
        seekBarVolume.progress = vol
        playerManager.setVolume(vol / 100f)
    }

    private fun setupListeners() {
        btnImport.setOnClickListener { showImportDialog() }
        btnFullscreen.setOnClickListener { toggleFullscreen() }
        btnPrev.setOnClickListener { switchToPrevChannel() }
        btnPlayPause.setOnClickListener { togglePlayPause() }
        btnNext.setOnClickListener { switchToNextChannel() }
    }

    private fun loadDefaultSource() {
        val savedSource = prefs.getString("source_url", "")
        if (savedSource.isNotEmpty()) {
            loadSource(savedSource)
        } else {
            // 内置测试源（与之前相同，保证开箱可用）
            val builtin = """
                #EXTM3U
                #EXTINF:-1 group-title="测试",测试1
                https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8
                #EXTINF:-1 group-title="测试",测试2
                https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8
            """.trimIndent()
            parseAndDisplay(builtin)
        }
    }

    private fun loadSource(url: String) {
        showLoading("加载直播源...")
        NetworkUtils.get(url) { result ->
            runOnUiThread {
                hideLoading()
                if (result.isSuccess) {
                    parseAndDisplay(result.getOrNull() ?: "")
                    prefs.putString("source_url", url)
                    showToast("加载成功: ${channels.size} 个频道")
                } else {
                    showToast("加载失败: ${result.exceptionOrNull()?.message}")
                }
            }
        }
    }

    private fun parseAndDisplay(content: String) {
        if (content.isEmpty()) return
        channels.clear()
        channels.addAll(ParserManager.parse(content))
        if (channels.isEmpty()) {
            showToast("未解析到频道")
        }
        updateUI()
        // 如果有保存的上次播放频道，自动播放
        val lastChannel = prefs.getString("last_channel", "")
        if (lastChannel.isNotEmpty()) {
            val idx = channels.indexOfFirst { it.name == lastChannel }
            if (idx >= 0) playChannel(idx)
        } else if (channels.isNotEmpty() && prefs.getBoolean("autoplay", false)) {
            playChannel(0)
        }
    }

    private fun updateUI() {
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

        filterChannels()
        tvChannelCount.text = "共 ${channels.size} 个频道"
    }

    private fun filterChannels() {
        val filtered = if (currentGroup == "全部") channels else channels.filter { it.group == currentGroup }
        if (::channelAdapter.isInitialized) {
            channelAdapter.updateData(filtered)
        } else {
            channelAdapter = ChannelAdapter(filtered) { position ->
                // 在点击时找到原始索引
                val originalIndex = channels.indexOfFirst { it == filtered[position] }
                if (originalIndex >= 0) playChannel(originalIndex)
            }
            channelList.adapter = channelAdapter
        }
        tvChannelCount.text = "共 ${filtered.size} 个频道"
    }

    private fun playChannel(position: Int) {
        if (position !in channels.indices) return
        currentPosition = position
        val channel = channels[position]
        showLoading("加载 ${channel.name} ...")
        playerManager.play(channel.url)
        tvNowPlaying.text = channel.name
        prefs.putString("last_channel", channel.name)
        btnPlayPause.setImageResource(android.R.drawable.ic_media_pause)
        // 高亮当前频道
        channelAdapter.highlightItem(position)
    }

    private fun switchToPrevChannel() {
        if (channels.isEmpty()) return
        if (currentPosition <= 0) currentPosition = channels.size
        playChannel((currentPosition - 1) % channels.size)
    }

    private fun switchToNextChannel() {
        if (channels.isEmpty()) return
        playChannel((currentPosition + 1) % channels.size)
    }

    private fun togglePlayPause() {
        if (playerManager.isPlaying) {
            playerManager.pause()
            btnPlayPause.setImageResource(android.R.drawable.ic_media_play)
        } else {
            playerManager.resume()
            btnPlayPause.setImageResource(android.R.drawable.ic_media_pause)
        }
    }

    private fun showImportDialog() {
        val items = arrayOf("从网络加载", "从本地文件导入", "粘贴内容")
        MaterialAlertDialogBuilder(this)
            .setTitle("导入直播源")
            .setItems(items) { _, which ->
                when (which) {
                    0 -> showUrlInputDialog()
                    1 -> showFilePicker()
                    2 -> showPasteDialog()
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
                if (url.isNotEmpty()) loadSource(url)
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
                if (content.isNotEmpty()) parseAndDisplay(content)
            }
            .setNegativeButton("取消", null)
            .show()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_IMPORT_FILE && resultCode == RESULT_OK) {
            val uri = data?.data ?: return
            val content = contentResolver.openInputStream(uri)?.bufferedReader()?.readText()
            if (content != null) {
                parseAndDisplay(content)
                prefs.putString("source_url", uri.toString())
                showToast("导入成功: ${channels.size} 个频道")
            } else {
                showToast("读取文件失败")
            }
        }
    }

    private fun toggleFullscreen() {
        // 实现全屏切换
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

    private fun loadSettings() {
        // 自动播放、断线重连等设置可从Preferences读取
        // 这里省略，可在设置界面中实现
    }

    companion object {
        private const val REQUEST_IMPORT_FILE = 1001
    }
}
