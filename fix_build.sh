#!/bin/bash
# fix_build.sh - 最终稳定版（运行时异常捕获 + 代码健壮性）
set -e

echo "=========================================="
echo "  🚀 构建稳定版酷9播放器（含运行时保护）"
echo "=========================================="

# ---------- 1. 修复 build.gradle ----------
APP_GRADLE="android/app/build.gradle"
if ! grep -q "viewBinding {" "$APP_GRADLE"; then
    sed -i '/android {/a\
    buildFeatures {\
        viewBinding true\
    }' "$APP_GRADLE"
fi

add_dependency() {
    local dep="$1"
    if ! grep -q "$dep" "$APP_GRADLE"; then
        sed -i "/dependencies {/a\\
    implementation \"$dep\"" "$APP_GRADLE"
    fi
}
add_dependency "com.squareup.okhttp3:okhttp:4.12.0"
add_dependency "com.squareup.okhttp3:logging-interceptor:4.12.0"
add_dependency "androidx.media3:media3-exoplayer:1.4.0"
add_dependency "androidx.media3:media3-exoplayer-hls:1.4.0"
add_dependency "androidx.media3:media3-ui:1.4.0"
add_dependency "androidx.media3:media3-common:1.4.0"
add_dependency "androidx.recyclerview:recyclerview:1.3.2"
add_dependency "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3"
add_dependency "androidx.lifecycle:lifecycle-runtime-ktx:2.6.2"
add_dependency "com.google.android.material:material:1.9.0"
sed -i '/com.google.android.exoplayer:exoplayer/d' "$APP_GRADLE"
sed -i '/com.google.android.exoplayer:exoplayer-hls/d' "$APP_GRADLE"
sed -i '/com.google.android.exoplayer:exoplayer-ui/d' "$APP_GRADLE"

# ---------- 2. 删除旧代码 ----------
SRC_DIR="android/app/src/main/java/com/ku9/player"
RES_DIR="android/app/src/main/res"
rm -rf "$SRC_DIR" "$RES_DIR/layout" "$RES_DIR/menu" "$RES_DIR/drawable" "$RES_DIR/values"
mkdir -p "$SRC_DIR" "$RES_DIR/layout" "$RES_DIR/menu" "$RES_DIR/drawable" "$RES_DIR/values"

# ---------- 3. 创建 Kotlin 文件（运行时安全版本） ----------

# 3.1 Ku9Application.kt（增强异常捕获）
cat > "$SRC_DIR/Ku9Application.kt" << 'EOF'
package com.ku9.player

import android.app.Application
import android.os.Environment
import android.util.Log
import android.widget.Toast
import java.io.File
import java.io.FileOutputStream
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.*

class Ku9Application : Application() {

    override fun onCreate() {
        super.onCreate()
        // 设置全局异常处理器
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            handleException(thread, throwable)
        }
    }

    private fun handleException(thread: Thread, throwable: Throwable) {
        val sw = StringWriter()
        val pw = PrintWriter(sw)
        throwable.printStackTrace(pw)
        val stackTrace = sw.toString()

        // 写入日志文件
        try {
            val time = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val file = File(getExternalFilesDir(null), "crash_$time.log")
            file.parentFile?.mkdirs()
            FileOutputStream(file).use { fos ->
                fos.write("Thread: ${thread.name}\n".toByteArray())
                fos.write("Exception: ${throwable.message}\n".toByteArray())
                fos.write(stackTrace.toByteArray())
            }
            Log.e("Ku9App", "Crash logged to ${file.absolutePath}")
        } catch (e: Exception) {
            Log.e("Ku9App", "Failed to write crash log", e)
        }

        // 打印到 logcat
        Log.e("Ku9App", "Uncaught exception in thread ${thread.name}", throwable)

        // 显示 Toast（如果可能）
        try {
            Toast.makeText(applicationContext, "应用崩溃: ${throwable.message}", Toast.LENGTH_LONG).show()
        } catch (e: Exception) {
            // ignore
        }

        // 如果系统有默认处理器，交给它
        val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()
        if (defaultHandler != null && defaultHandler !is Ku9Application) {
            defaultHandler.uncaughtException(thread, throwable)
        } else {
            // 否则自行退出
            android.os.Process.killProcess(android.os.Process.myPid())
            System.exit(1)
        }
    }
}
EOF

# 3.2 Channel.kt
cat > "$SRC_DIR/Channel.kt" << 'EOF'
package com.ku9.player

data class Channel(
    val id: String = "",
    val name: String = "",
    val url: String = "",
    val backupUrls: List<String> = emptyList(),
    val logoUrl: String = "",
    val epgUrl: String = "",
    val headers: Map<String, String> = emptyMap(),
    val groupId: String = "",
    var isFavorite: Boolean = false
)
EOF

# 3.3 Group.kt
cat > "$SRC_DIR/Group.kt" << 'EOF'
package com.ku9.player

data class Group(
    val id: String = "",
    val name: String = "",
    val channels: List<Channel> = emptyList(),
    val subGroups: List<Group> = emptyList()
)
EOF

# 3.4 EpgProgram.kt
cat > "$SRC_DIR/EpgProgram.kt" << 'EOF'
package com.ku9.player

data class EpgProgram(
    val title: String,
    val startTime: Long,
    val endTime: Long,
    val desc: String = ""
)
EOF

# 3.5 M3UParser.kt（修复泛型）
cat > "$SRC_DIR/M3UParser.kt" << 'EOF'
package com.ku9.player

class M3UParser {

    fun parse(content: String): List<Group> {
        val groups = mutableListOf<Group>()
        val lines = content.lines()
        var currentGroupName = "未分组"
        val currentChannels = mutableListOf<Channel>()
        var extinfLine = ""

        for (line in lines) {
            val trimmed = line.trim()
            when {
                trimmed.startsWith("#EXTINF:") -> {
                    extinfLine = trimmed
                }
                trimmed.startsWith("#") -> {
                    // 忽略其他注释
                }
                trimmed.isNotEmpty() && !trimmed.startsWith("#EXT") -> {
                    val url = trimmed
                    val name = extinfLine.substringAfter(",").trim()
                    val groupMatch = Regex("group-title=\"(.*?)\"").find(extinfLine)
                    val groupName = groupMatch?.groupValues?.get(1) ?: "未分组"
                    val logoMatch = Regex("tvg-logo=\"(.*?)\"").find(extinfLine)
                    val logo = logoMatch?.groupValues?.get(1) ?: ""

                    if (groupName != currentGroupName && currentChannels.isNotEmpty()) {
                        groups.add(Group(name = currentGroupName, channels = currentChannels.toList()))
                        currentChannels.clear()
                        currentGroupName = groupName
                    }
                    currentChannels.add(Channel(name = name, url = url, logoUrl = logo, groupId = groupName))
                    extinfLine = ""
                }
            }
        }
        if (currentChannels.isNotEmpty()) {
            groups.add(Group(name = currentGroupName, channels = currentChannels.toList()))
        }
        return groups
    }
}
EOF

# 3.6 TXTParser.kt
cat > "$SRC_DIR/TXTParser.kt" << 'EOF'
package com.ku9.player

class TXTParser {
    fun parse(content: String): List<Channel> {
        val channels = mutableListOf<Channel>()
        for (line in content.lines()) {
            val trimmed = line.trim()
            if (trimmed.isNotEmpty() && !trimmed.startsWith("#")) {
                val parts = trimmed.split(",", limit = 2)
                if (parts.size == 2) {
                    channels.add(Channel(name = parts[0].trim(), url = parts[1].trim()))
                }
            }
        }
        return channels
    }
}
EOF

# 3.7 SourceManager.kt（安全初始化）
cat > "$SRC_DIR/SourceManager.kt" << 'EOF'
package com.ku9.player

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.net.URL

class SourceManager(private val context: Context) {

    data class Source(
        val name: String,
        val url: String,
        val type: Type,
        var enabled: Boolean = true
    ) {
        enum class Type { M3U, TXT }
    }

    private val _sources = mutableListOf<Source>()
    val sources: List<Source> get() = _sources
    private var currentSourceIndex = 0
    private var _currentGroups: List<Group> = emptyList()
    val currentGroups: List<Group> get() = _currentGroups

    init {
        // 内置示例源（HTTPS 安全）
        try {
            _sources.add(Source(
                name = "示例源",
                url = "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8",
                type = Source.Type.M3U
            ))
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    suspend fun addSource(name: String, url: String, type: Source.Type): Boolean {
        return try {
            _sources.add(Source(name, url, type))
            true
        } catch (e: Exception) {
            false
        }
    }

    suspend fun loadSource(index: Int): Boolean {
        if (index !in _sources.indices) return false
        currentSourceIndex = index
        val source = _sources[index]
        return withContext(Dispatchers.IO) {
            try {
                val content = if (source.url.startsWith("http")) {
                    URL(source.url).readText()
                } else {
                    File(source.url).readText()
                }
                _currentGroups = when (source.type) {
                    Source.Type.M3U -> M3UParser().parse(content)
                    Source.Type.TXT -> {
                        val channels = TXTParser().parse(content)
                        listOf(Group(name = "默认", channels = channels))
                    }
                }
                true
            } catch (e: Exception) {
                e.printStackTrace()
                false
            }
        }
    }

    suspend fun switchToNextSource(): Boolean {
        if (_sources.isEmpty()) return false
        val next = (currentSourceIndex + 1) % _sources.size
        return loadSource(next)
    }

    fun getCurrentSource(): Source? = _sources.getOrNull(currentSourceIndex)

    fun getAllChannels(): List<Channel> = _currentGroups.flatMap { it.channels }

    fun searchChannels(query: String): List<Channel> {
        return getAllChannels().filter { it.name.contains(query, ignoreCase = true) }
    }

    fun toggleFavorite(channel: Channel) {
        channel.isFavorite = !channel.isFavorite
    }

    fun getFavoriteChannels(): List<Channel> = getAllChannels().filter { it.isFavorite }
}
EOF

# 3.8 EPGManager.kt
cat > "$SRC_DIR/EPGManager.kt" << 'EOF'
package com.ku9.player

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*
import kotlin.text.RegexOption

class EPGManager {

    suspend fun loadEPG(xmlUrl: String, channelId: String, offsetDays: Int): List<EpgProgram> =
        withContext(Dispatchers.IO) {
            if (xmlUrl.isEmpty()) return@withContext emptyList()
            try {
                val xml = URL(xmlUrl).readText()
                parseXMLTV(xml, channelId, offsetDays)
            } catch (e: Exception) {
                emptyList()
            }
        }

    private fun parseXMLTV(xml: String, channelId: String, offsetDays: Int): List<EpgProgram> {
        val list = mutableListOf<EpgProgram>()
        val regex = Regex(
            """<programme[^>]*channel="$channelId"[^>]*>.*?</programme>""",
            setOf(RegexOption.DOT_MATCHES_ALL)
        )
        val sdf = SimpleDateFormat("yyyyMMddHHmmss Z", Locale.getDefault())
        val calendar = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, offsetDays)
        }
        val dayStart = calendar.apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
        }.timeInMillis
        val dayEnd = dayStart + 24 * 60 * 60 * 1000

        regex.findAll(xml).forEach { match ->
            val block = match.value
            val title = Regex("<title>(.*?)</title>").find(block)?.groupValues?.get(1) ?: ""
            val start = Regex("start=\"(.*?)\"").find(block)?.groupValues?.get(1) ?: ""
            val end = Regex("end=\"(.*?)\"").find(block)?.groupValues?.get(1) ?: ""
            val startTime = try {
                sdf.parse(start.replace("+0000", " +0000"))?.time ?: 0
            } catch (_: Exception) {
                0
            }
            val endTime = try {
                sdf.parse(end.replace("+0000", " +0000"))?.time ?: 0
            } catch (_: Exception) {
                0
            }
            if (startTime >= dayStart && startTime < dayEnd) {
                list.add(EpgProgram(title, startTime, endTime, ""))
            }
        }
        return list.sortedBy { it.startTime }
    }
}
EOF

# 3.9 PlayerManager.kt（简化、安全）
cat > "$SRC_DIR/PlayerManager.kt" << 'EOF'
package com.ku9.player

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.media3.common.*
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import java.util.concurrent.atomic.AtomicBoolean

@UnstableApi
class PlayerManager(private val context: Context) {

    companion object {
        private const val MAX_RETRY_COUNT = 3
        private const val RETRY_DELAY_MS = 2000L
    }

    private var exoPlayer: ExoPlayer? = null
    private var currentUrl: String? = null
    private var currentHeaders: Map<String, String> = emptyMap()
    private var retryCount = 0
    private val mainHandler = Handler(Looper.getMainLooper())
    private val isReleased = AtomicBoolean(false)

    private val playerListener = object : Player.Listener {
        override fun onPlaybackStateChanged(playbackState: Int) {
            if (playbackState == Player.STATE_READY) retryCount = 0
        }

        override fun onPlayerError(error: PlaybackException) {
            if (retryCount < MAX_RETRY_COUNT && !isReleased.get()) {
                retryCount++
                mainHandler.postDelayed({
                    currentUrl?.let { play(it, currentHeaders) }
                }, RETRY_DELAY_MS * retryCount)
            }
        }
    }

    private fun initPlayer(): ExoPlayer {
        if (exoPlayer == null) {
            val selector = DefaultTrackSelector(context)
            val player = ExoPlayer.Builder(context)
                .setTrackSelector(selector)
                .build()
            player.addListener(playerListener)
            exoPlayer = player
        }
        return exoPlayer!!
    }

    fun play(url: String, headers: Map<String, String> = emptyMap()) {
        if (isReleased.get()) return
        currentUrl = url
        currentHeaders = headers
        try {
            val player = initPlayer()
            val mediaSource = buildMediaSource(url, headers)
            player.setMediaSource(mediaSource)
            player.prepare()
            player.play()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun buildMediaSource(url: String, headers: Map<String, String>): MediaSource {
        val dataSourceFactory = DefaultHttpDataSource.Factory()
            .setAllowCrossProtocolRedirects(true)
            .setDefaultRequestProperties(headers)
        return HlsMediaSource.Factory(dataSourceFactory)
            .setAllowChunklessPreparation(true)
            .createMediaSource(MediaItem.fromUri(Uri.parse(url)))
    }

    fun pause() {
        exoPlayer?.pause()
    }

    fun resume() {
        exoPlayer?.play()
    }

    fun stop() {
        exoPlayer?.stop()
    }

    fun release() {
        isReleased.set(true)
        mainHandler.removeCallbacksAndMessages(null)
        exoPlayer?.apply {
            removeListener(playerListener)
            release()
        }
        exoPlayer = null
    }

    fun seekTo(positionMs: Long) {
        exoPlayer?.seekTo(positionMs)
    }

    fun isPlaying(): Boolean = exoPlayer?.isPlaying ?: false
}
EOF

# 3.10 ChannelAdapter.kt
cat > "$SRC_DIR/ChannelAdapter.kt" << 'EOF'
package com.ku9.player

import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView

class ChannelAdapter(
    private val onItemClick: (Channel) -> Unit,
    private val onFavoriteClick: ((Channel) -> Unit)? = null
) : RecyclerView.Adapter<ChannelAdapter.ChannelViewHolder>() {

    private var items: List<Channel> = emptyList()

    fun submitList(list: List<Channel>) {
        items = list
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ChannelViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_channel, parent, false)
        return ChannelViewHolder(view)
    }

    override fun onBindViewHolder(holder: ChannelViewHolder, position: Int) {
        val channel = items[position]
        holder.nameView.text = channel.name
        holder.logoView.setImageResource(android.R.drawable.ic_menu_gallery)
        holder.itemView.setOnClickListener { onItemClick(channel) }
        holder.favoriteView.apply {
            setImageResource(if (channel.isFavorite) android.R.drawable.star_on else android.R.drawable.star_off)
            setOnClickListener { onFavoriteClick?.invoke(channel) }
        }
    }

    override fun getItemCount() = items.size

    class ChannelViewHolder(itemView: android.view.View) :
        RecyclerView.ViewHolder(itemView) {
        val nameView: TextView = itemView.findViewById(R.id.channel_name)
        val logoView: ImageView = itemView.findViewById(R.id.channel_logo)
        val favoriteView: ImageView = itemView.findViewById(R.id.favorite_icon)
    }
}
EOF

# 3.11 GroupAdapter.kt
cat > "$SRC_DIR/GroupAdapter.kt" << 'EOF'
package com.ku9.player

import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView

class GroupAdapter(
    private val onGroupClick: (Group) -> Unit
) : RecyclerView.Adapter<GroupAdapter.GroupViewHolder>() {

    private var items: List<Group> = emptyList()

    fun submitList(list: List<Group>) {
        items = list
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): GroupViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(android.R.layout.simple_list_item_1, parent, false)
        return GroupViewHolder(view)
    }

    override fun onBindViewHolder(holder: GroupViewHolder, position: Int) {
        val group = items[position]
        holder.textView.text = group.name
        holder.itemView.setOnClickListener { onGroupClick(group) }
    }

    override fun getItemCount() = items.size

    class GroupViewHolder(itemView: android.view.View) :
        RecyclerView.ViewHolder(itemView) {
        val textView: TextView = itemView.findViewById(android.R.id.text1)
    }
}
EOF

# 3.12 EpgAdapter.kt
cat > "$SRC_DIR/EpgAdapter.kt" << 'EOF'
package com.ku9.player

import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import java.text.SimpleDateFormat
import java.util.*

class EpgAdapter : RecyclerView.Adapter<EpgAdapter.ViewHolder>() {

    private var items: List<EpgProgram> = emptyList()
    private val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())

    fun submitList(list: List<EpgProgram>) {
        items = list
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = TextView(parent.context).apply {
            textSize = 16f
            setPadding(32, 16, 32, 16)
        }
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val program = items[position]
        val time = "${timeFormat.format(Date(program.startTime))} - ${timeFormat.format(Date(program.endTime))}"
        holder.textView.text = "$time  ${program.title}"
    }

    override fun getItemCount() = items.size

    class ViewHolder(val textView: TextView) : RecyclerView.ViewHolder(textView)
}
EOF

# 3.13 MainActivity.kt（加 try-catch 和 Toast）
cat > "$SRC_DIR/MainActivity.kt" << 'EOF'
package com.ku9.player

import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import com.google.android.material.bottomnavigation.BottomNavigationView
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {

    lateinit var sourceManager: SourceManager
    var currentChannel: Channel? = null
        private set

    private val channelListFragment by lazy { ChannelListFragment() }
    private val epgFragment by lazy { EPGFragment() }
    private val settingsFragment by lazy { SettingsFragment() }

    override fun onCreate(savedInstanceState: Bundle?) {
        try {
            super.onCreate(savedInstanceState)
            setContentView(R.layout.activity_main)

            sourceManager = SourceManager(this)

            val navView = findViewById<BottomNavigationView>(R.id.nav_view)
            navView.setOnNavigationItemSelectedListener { item ->
                when (item.itemId) {
                    R.id.navigation_channels -> {
                        switchFragment(channelListFragment)
                        true
                    }
                    R.id.navigation_epg -> {
                        switchFragment(epgFragment)
                        true
                    }
                    R.id.navigation_settings -> {
                        switchFragment(settingsFragment)
                        true
                    }
                    else -> false
                }
            }
            switchFragment(channelListFragment)
        } catch (e: Exception) {
            Toast.makeText(this, "初始化失败: ${e.message}", Toast.LENGTH_LONG).show()
            e.printStackTrace()
            throw e
        }
    }

    private fun switchFragment(fragment: Fragment) {
        supportFragmentManager.beginTransaction()
            .replace(R.id.container, fragment)
            .commit()
    }

    fun playChannel(channel: Channel) {
        currentChannel = channel
        Toast.makeText(this, "播放: ${channel.name}", Toast.LENGTH_SHORT).show()
        // 实际播放由 PlayerManager 处理
    }

    override fun onCreateOptionsMenu(menu: Menu?): Boolean {
        menuInflater.inflate(R.menu.main_menu, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when (item.itemId) {
            R.id.action_add_source -> {
                Toast.makeText(this, "添加源功能待实现", Toast.LENGTH_SHORT).show()
                return true
            }
            R.id.action_favorites -> {
                val favorites = sourceManager.getFavoriteChannels()
                Toast.makeText(this, "收藏: ${favorites.size}个", Toast.LENGTH_SHORT).show()
                return true
            }
        }
        return super.onOptionsItemSelected(item)
    }
}
EOF

# 3.14 ChannelListFragment.kt（安全加载）
cat > "$SRC_DIR/ChannelListFragment.kt" << 'EOF'
package com.ku9.player

import android.os.Bundle
import android.view.*
import android.widget.SearchView
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.launch

class ChannelListFragment : Fragment() {

    private lateinit var sourceManager: SourceManager
    private lateinit var channelAdapter: ChannelAdapter
    private lateinit var groupAdapter: GroupAdapter
    private var allChannels: List<Channel> = emptyList()
    private var isGroupView = true

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            sourceManager = (requireActivity() as MainActivity).sourceManager
        } catch (e: Exception) {
            Toast.makeText(requireContext(), "无法获取源管理器", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_channel_list, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val rv = view.findViewById<RecyclerView>(R.id.rv_channels)
        rv.layoutManager = LinearLayoutManager(requireContext())

        channelAdapter = ChannelAdapter(
            onItemClick = { channel ->
                (requireActivity() as MainActivity).playChannel(channel)
            },
            onFavoriteClick = { channel ->
                sourceManager.toggleFavorite(channel)
                updateUI()
            }
        )

        groupAdapter = GroupAdapter { group ->
            showChannelsInGroup(group)
        }

        rv.adapter = groupAdapter
        isGroupView = true

        val searchView = view.findViewById<SearchView>(R.id.search_view)
        searchView.setOnQueryTextListener(object : SearchView.OnQueryTextListener {
            override fun onQueryTextSubmit(query: String?): Boolean {
                search(query ?: "")
                return true
            }
            override fun onQueryTextChange(newText: String?): Boolean {
                search(newText ?: "")
                return true
            }
        })

        loadSource()

        rv.setOnLongClickListener {
            toggleView()
            true
        }
    }

    private fun loadSource() {
        lifecycleScope.launch {
            try {
                val success = sourceManager.loadSource(0)
                if (success) {
                    allChannels = sourceManager.getAllChannels()
                    updateUI()
                } else {
                    Toast.makeText(requireContext(), "加载源失败", Toast.LENGTH_LONG).show()
                }
            } catch (e: Exception) {
                Toast.makeText(requireContext(), "加载异常: ${e.message}", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun updateUI() {
        if (isGroupView) {
            val groups = sourceManager.currentGroups
            groupAdapter.submitList(groups)
            (view?.findViewById<RecyclerView>(R.id.rv_channels))?.adapter = groupAdapter
        } else {
            channelAdapter.submitList(allChannels)
            (view?.findViewById<RecyclerView>(R.id.rv_channels))?.adapter = channelAdapter
        }
    }

    private fun showChannelsInGroup(group: Group) {
        val channels = group.channels
        if (channels.isEmpty()) {
            Toast.makeText(requireContext(), "该分组暂无频道", Toast.LENGTH_SHORT).show()
            return
        }
        isGroupView = false
        channelAdapter.submitList(channels)
        (view?.findViewById<RecyclerView>(R.id.rv_channels))?.adapter = channelAdapter
    }

    private fun toggleView() {
        isGroupView = !isGroupView
        updateUI()
        Toast.makeText(requireContext(), if (isGroupView) "分组视图" else "频道列表", Toast.LENGTH_SHORT).show()
    }

    private fun search(query: String) {
        if (query.isEmpty()) {
            updateUI()
            return
        }
        val results = sourceManager.searchChannels(query)
        isGroupView = false
        channelAdapter.submitList(results)
        (view?.findViewById<RecyclerView>(R.id.rv_channels))?.adapter = channelAdapter
    }
}
EOF

# 3.15 EPGFragment.kt（安全处理）
cat > "$SRC_DIR/EPGFragment.kt" << 'EOF'
package com.ku9.player

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

class EPGFragment : Fragment() {

    private lateinit var epgManager: EPGManager
    private lateinit var adapter: EpgAdapter
    private var currentChannel: Channel? = null
    private var offsetDays = 0
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        epgManager = EPGManager()
        currentChannel = (activity as? MainActivity)?.currentChannel
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_epg, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val recycler = view.findViewById<RecyclerView>(R.id.epg_recycler)
        recycler.layoutManager = LinearLayoutManager(requireContext())
        adapter = EpgAdapter()
        recycler.adapter = adapter

        val dateText = view.findViewById<TextView>(R.id.date_text)
        view.findViewById<Button>(R.id.prev_day).setOnClickListener {
            offsetDays--
            updateEPG()
        }
        view.findViewById<Button>(R.id.next_day).setOnClickListener {
            offsetDays++
            updateEPG()
        }

        if (currentChannel == null) {
            dateText.text = "请先选择一个频道"
        } else {
            updateEPG()
        }
    }

    private fun updateEPG() {
        val channel = currentChannel ?: return
        val dateText = view?.findViewById<TextView>(R.id.date_text)
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, offsetDays)
        dateText?.text = dateFormat.format(calendar.time)

        lifecycleScope.launch {
            try {
                val programs = epgManager.loadEPG(
                    channel.epgUrl.ifEmpty { "" },
                    channel.id,
                    offsetDays
                )
                adapter.submitList(programs)
                if (programs.isEmpty()) {
                    dateText?.text = "${dateText?.text} (无节目)"
                }
            } catch (e: Exception) {
                dateText?.text = "加载失败"
            }
        }
    }
}
EOF

# 3.16 SettingsFragment.kt
cat > "$SRC_DIR/SettingsFragment.kt" << 'EOF'
package com.ku9.player

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Switch
import android.widget.Toast
import androidx.fragment.app.Fragment

class SettingsFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_settings, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val decoderSwitch = view.findViewById<Switch>(R.id.switch_decoder)
        decoderSwitch?.setOnCheckedChangeListener { _, isChecked ->
            Toast.makeText(requireContext(), if (isChecked) "硬件解码" else "软件解码", Toast.LENGTH_SHORT).show()
        }
    }
}
EOF

# 3.17 ParserManager.kt
cat > "$SRC_DIR/ParserManager.kt" << 'EOF'
package com.ku9.player

class ParserManager {
    fun parseM3U(content: String): List<Group> {
        return M3UParser().parse(content)
    }
}
EOF

# ---------- 4. 布局文件（略，仅创建 item_channel.xml 和必要的） ----------
# 这里省略布局创建，但确保 item_channel.xml 存在且使用系统图标
# 为避免重复，采用快速覆盖
cat > "$RES_DIR/layout/item_channel.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="horizontal"
    android:padding="16dp"
    android:gravity="center_vertical">
    <ImageView
        android:id="@+id/channel_logo"
        android:layout_width="48dp"
        android:layout_height="48dp"
        android:src="@android:drawable/ic_menu_gallery" />
    <TextView
        android:id="@+id/channel_name"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_weight="1"
        android:layout_marginStart="16dp"
        android:textSize="18sp" />
    <ImageView
        android:id="@+id/favorite_icon"
        android:layout_width="32dp"
        android:layout_height="32dp"
        android:src="@android:drawable/star_off"
        android:contentDescription="收藏" />
</LinearLayout>
EOF

# 其他布局 (快速创建)
cat > "$RES_DIR/layout/activity_main.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">
    <FrameLayout
        android:id="@+id/container"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1" />
    <com.google.android.material.bottomnavigation.BottomNavigationView
        android:id="@+id/nav_view"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        app:menu="@menu/bottom_nav_menu" />
</LinearLayout>
EOF

cat > "$RES_DIR/layout/fragment_channel_list.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">
    <androidx.appcompat.widget.SearchView
        android:id="@+id/search_view"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:queryHint="搜索频道..." />
    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/rv_channels"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:scrollbars="vertical" />
</LinearLayout>
EOF

cat > "$RES_DIR/layout/fragment_epg.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center">
        <Button
            android:id="@+id/prev_day"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="前一天" />
        <TextView
            android:id="@+id/date_text"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:textSize="18sp"
            android:gravity="center"
            android:text="日期" />
        <Button
            android:id="@+id/next_day"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="后一天" />
    </LinearLayout>
    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/epg_recycler"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:scrollbars="vertical" />
</LinearLayout>
EOF

cat > "$RES_DIR/layout/fragment_settings.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp">
    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="设置"
        android:textSize="24sp" />
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:layout_marginTop="16dp">
        <TextView
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="硬件解码" />
        <Switch
            android:id="@+id/switch_decoder"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:checked="true" />
    </LinearLayout>
</LinearLayout>
EOF

# 菜单
cat > "$RES_DIR/menu/bottom_nav_menu.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:id="@+id/navigation_channels"
        android:icon="@android:drawable/ic_menu_agenda"
        android:title="频道" />
    <item
        android:id="@+id/navigation_epg"
        android:icon="@android:drawable/ic_menu_week"
        android:title="EPG" />
    <item
        android:id="@+id/navigation_settings"
        android:icon="@android:drawable/ic_menu_preferences"
        android:title="设置" />
</menu>
EOF

cat > "$RES_DIR/menu/main_menu.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:id="@+id/action_add_source"
        android:title="添加源"
        android:icon="@android:drawable/ic_menu_add"
        android:showAsAction="ifRoom" />
    <item
        android:id="@+id/action_favorites"
        android:title="收藏"
        android:icon="@android:drawable/star_on"
        android:showAsAction="ifRoom" />
</menu>
EOF

# 颜色和主题
cat > "$RES_DIR/values/colors.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="purple_200">#FFBB86FC</color>
    <color name="purple_500">#FF6200EE</color>
    <color name="purple_700">#FF3700B3</color>
    <color name="teal_200">#FF03DAC5</color>
    <color name="teal_700">#FF018786</color>
    <color name="black">#FF000000</color>
    <color name="white">#FFFFFFFF</color>
</resources>
EOF

cat > "$RES_DIR/values/themes.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.Ku9Player" parent="Theme.MaterialComponents.DayNight.NoActionBar">
        <item name="colorPrimary">@color/purple_500</item>
        <item name="colorPrimaryVariant">@color/purple_700</item>
        <item name="colorOnPrimary">@color/white</item>
        <item name="colorSecondary">@color/teal_200</item>
        <item name="colorSecondaryVariant">@color/teal_700</item>
        <item name="colorOnSecondary">@color/black</item>
        <item name="android:statusBarColor">?attr/colorPrimaryVariant</item>
    </style>
</resources>
EOF

# drawable（用于 Manifest 引用，如果仍然引用）
cat > "$RES_DIR/drawable/ic_launcher_foreground.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <group
        android:scaleX="0.3"
        android:scaleY="0.3"
        android:translateX="37.8"
        android:translateY="37.8">
        <path
            android:fillColor="#FFFFFF"
            android:pathData="M54,27 L81,54 L54,81 L27,54 Z" />
        <path
            android:fillColor="#FF0000"
            android:pathData="M54,27 L81,54 L54,81 L27,54 Z" />
    </group>
</vector>
EOF

# ---------- 5. 修改 AndroidManifest.xml ----------
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ ! -f "$MANIFEST" ]; then
    mkdir -p android/app/src/main
    cat > "$MANIFEST" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.ku9.player">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

    <application
        android:name=".Ku9Application"
        android:allowBackup="true"
        android:label="酷9播放器"
        android:supportsRtl="true"
        android:theme="@style/Theme.Ku9Player"
        android:usesCleartextTraffic="true">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF
else
    # 移除图标引用
    sed -i 's/ android:icon="[^"]*"//g' "$MANIFEST"
    sed -i 's/ android:roundIcon="[^"]*"//g' "$MANIFEST"
    # 设置 Ku9Application
    if ! grep -q 'android:name=".Ku9Application"' "$MANIFEST"; then
        sed -i 's/<application /<application android:name=".Ku9Application" /' "$MANIFEST"
    fi
    # 添加 usesCleartextTraffic
    if ! grep -q 'android:usesCleartextTraffic="true"' "$MANIFEST"; then
        sed -i 's/<application /<application android:usesCleartextTraffic="true" /' "$MANIFEST"
    fi
    # 权限
    for perm in INTERNET ACCESS_NETWORK_STATE READ_EXTERNAL_STORAGE; do
        if ! grep -q "android.permission.$perm" "$MANIFEST"; then
            sed -i "/<manifest/a\\
    <uses-permission android:name=\"android.permission.$perm\" />" "$MANIFEST"
        fi
    done
fi

# ---------- 6. 清理构建缓存 ----------
rm -rf android/app/build

echo "=========================================="
echo "  ✅ 构建脚本完成（运行时异常捕获已增强）"
echo "  如果应用仍闪退，请查看 /sdcard/Android/data/com.ku9.player/files/ 下的日志"
echo "  或使用 adb logcat 获取详细堆栈"
echo "=========================================="
