#!/bin/bash
# 修正 ku9999 项目所有编译错误，保留完整功能

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

echo "开始修正项目..."

# ========== 1. 删除重复的 ChannelListFragment ==========
find android/app/src -name "ChannelListFragment.kt" | while read -r f; do
    if [[ "$f" != "android/app/src/main/java/com/ku9/player/ChannelListFragment.kt" ]]; then
        echo "删除重复文件: $f"
        rm -f "$f"
    fi
done

# ========== 2. 覆盖 build.gradle (app级) ==========
cat > android/app/build.gradle <<'EOF'
plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'kotlin-kapt'
}

android {
    namespace 'com.ku9.player'
    compileSdk 34

    defaultConfig {
        applicationId "com.ku9.player"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildFeatures {
        dataBinding true
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = '1.8'
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.recyclerview:recyclerview:1.3.2'
    implementation 'androidx.cardview:cardview:1.0.0'
    implementation 'org.jetbrains.kotlin:kotlin-stdlib:1.9.0'

    // Media3 (匹配代码中的 import)
    implementation 'androidx.media3:media3-exoplayer:1.3.1'
    implementation 'androidx.media3:media3-exoplayer-hls:1.3.1'
    implementation 'androidx.media3:media3-ui:1.3.1'
    implementation 'androidx.media3:media3-datasource-okhttp:1.3.1'

    // OkHttp
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'

    // Gson
    implementation 'com.google.code.gson:gson:2.10.1'

    // Coroutines
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'
    implementation 'androidx.lifecycle:lifecycle-runtime-ktx:2.7.0'

    // Glide (台标)
    implementation 'com.github.bumptech.glide:glide:4.16.0'
    annotationProcessor 'com.github.bumptech.glide:compiler:4.16.0'
}
EOF

# ========== 3. 覆盖 gradle.properties ==========
cat > android/gradle.properties <<'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.suppressUnsupportedCompileSdk=34
EOF

# ========== 4. 覆盖 AndroidManifest.xml (移除图标引用) ==========
cat > android/app/src/main/AndroidManifest.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.ku9.player">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

    <application
        android:name=".MyApplication"
        android:allowBackup="true"
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:theme="@style/Theme.Ku9Player">
        <activity android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# ========== 5. 补充缺失的资源文件 ==========
# 颜色
mkdir -p android/app/src/main/res/values
cat > android/app/src/main/res/values/colors.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="purple_500">#6200EE</color>
    <color name="purple_700">#3700B3</color>
    <color name="teal_200">#03DAC5</color>
    <color name="teal_700">#018786</color>
    <color name="white">#FFFFFF</color>
    <color name="black">#000000</color>
</resources>
EOF

# 主题
cat > android/app/src/main/res/values/themes.xml <<'EOF'
<resources>
    <style name="Theme.Ku9Player" parent="Theme.MaterialComponents.DayNight.NoActionBar">
        <item name="colorPrimary">@color/purple_500</item>
        <item name="colorPrimaryVariant">@color/purple_700</item>
        <item name="colorOnPrimary">@color/white</item>
        <item name="colorSecondary">@color/teal_200</item>
        <item name="colorSecondaryVariant">@color/teal_700</item>
        <item name="colorOnSecondary">@color/black</item>
    </style>
</resources>
EOF

# 字符串
cat > android/app/src/main/res/values/strings.xml <<'EOF'
<resources>
    <string name="app_name">Ku9播放器</string>
</resources>
EOF

# 布局：activity_main
cat > android/app/src/main/res/layout/activity_main.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">

    <FrameLayout
        android:id="@+id/fragment_container"
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1" />

    <com.google.android.material.bottomnavigation.BottomNavigationView
        android:id="@+id/bottom_navigation"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        app:menu="@menu/bottom_nav_menu" />

</LinearLayout>
EOF

# 菜单
mkdir -p android/app/src/main/res/menu
cat > android/app/src/main/res/menu/bottom_nav_menu.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:id="@+id/nav_channels" android:icon="@android:drawable/ic_menu_agenda" android:title="频道" />
    <item android:id="@+id/nav_epg" android:icon="@android:drawable/ic_menu_week" android:title="节目单" />
    <item android:id="@+id/nav_settings" android:icon="@android:drawable/ic_menu_preferences" android:title="设置" />
</menu>
EOF

# Fragment 布局
mkdir -p android/app/src/main/res/layout
cat > android/app/src/main/res/layout/fragment_channel_list.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">

    <SearchView
        android:id="@+id/search_view"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:iconifiedByDefault="false"
        android:queryHint="搜索频道..." />

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/channel_recycler"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
</LinearLayout>
EOF

cat > android/app/src/main/res/layout/fragment_epg.xml <<'EOF'
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
        <Button android:id="@+id/prev_day" android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="前一天" />
        <TextView android:id="@+id/date_text" android:layout_width="0dp" android:layout_height="wrap_content" android:layout_weight="1" android:text="2026-07-20" android:textSize="18sp" android:gravity="center" />
        <Button android:id="@+id/next_day" android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="后一天" />
    </LinearLayout>

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/epg_recycler"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
</LinearLayout>
EOF

cat > android/app/src/main/res/layout/fragment_settings.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<ScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="vertical" android:padding="16dp">
        <Switch android:id="@+id/decoder_switch" android:layout_width="match_parent" android:layout_height="wrap_content" android:text="硬解开关" />
        <EditText android:id="@+id/epg_url_edit" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="EPG XML URL" />
        <Button android:id="@+id/save_epg_btn" android:layout_width="match_parent" android:layout_height="wrap_content" android:text="保存EPG地址" />
        <EditText android:id="@+id/source_url_edit" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="直播源 M3U/TXT URL" />
        <Button android:id="@+id/save_source_btn" android:layout_width="match_parent" android:layout_height="wrap_content" android:text="保存源地址" />
        <Button android:id="@+id/add_source_btn" android:layout_width="match_parent" android:layout_height="wrap_content" android:text="添加新源" />
    </LinearLayout>
</ScrollView>
EOF

cat > android/app/src/main/res/layout/dialog_add_source.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical" android:padding="16dp">
    <EditText android:id="@+id/source_name" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="源名称" />
    <EditText android:id="@+id/source_url" android:layout_width="match_parent" android:layout_height="wrap_content" android:hint="源URL" />
</LinearLayout>
EOF

cat > android/app/src/main/res/layout/item_channel.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="horizontal" android:padding="12dp"
    android:background="?selectableItemBackground">
    <TextView android:id="@+id/channel_name" android:layout_width="0dp" android:layout_height="wrap_content"
        android:layout_weight="1" android:textSize="16sp" android:text="频道名" />
</LinearLayout>
EOF

cat > android/app/src/main/res/layout/item_epg.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="vertical" android:padding="8dp">
    <TextView android:id="@+id/epg_title" android:layout_width="match_parent" android:layout_height="wrap_content" android:textSize="16sp" android:text="节目名" />
    <TextView android:id="@+id/epg_time" android:layout_width="match_parent" android:layout_height="wrap_content" android:textSize="14sp" android:textColor="#888" android:text="12:00 - 13:00" />
</LinearLayout>
EOF

# ========== 6. 覆盖所有 Kotlin 源文件（修正错误）==========
# 路径：android/app/src/main/java/com/ku9/player/

# 6.1 模型类（Channel, Group, EpgProgram）
cat > android/app/src/main/java/com/ku9/player/Channel.kt <<'EOF'
package com.ku9.player

data class Channel(
    val name: String,
    val logo: String = "",
    val url: String,
    val epgId: String = ""
)
EOF

cat > android/app/src/main/java/com/ku9/player/Group.kt <<'EOF'
package com.ku9.player

data class Group(
    val name: String,
    val channels: List<Channel>
)
EOF

cat > android/app/src/main/java/com/ku9/player/EpgProgram.kt <<'EOF'
package com.ku9.player

data class EpgProgram(
    val title: String,
    val startTime: Long,
    val endTime: Long,
    val desc: String
)
EOF

# 6.2 SettingsManager
cat > android/app/src/main/java/com/ku9/player/SettingsManager.kt <<'EOF'
package com.ku9.player

import android.content.Context
import android.content.SharedPreferences

object SettingsManager {
    private lateinit var prefs: SharedPreferences

    fun init(context: Context) {
        prefs = context.getSharedPreferences("ku9_settings", Context.MODE_PRIVATE)
    }

    fun isHardwareDecoder(): Boolean = prefs.getBoolean("hardware_decoder", true)
    fun setHardwareDecoder(enabled: Boolean) = prefs.edit().putBoolean("hardware_decoder", enabled).apply()
    fun getEpgUrl(): String = prefs.getString("epg_url", "") ?: ""
    fun saveEpgUrl(url: String) = prefs.edit().putString("epg_url", url).apply()
    fun getSourceUrl(): String = prefs.getString("source_url", "") ?: ""
    fun saveSourceUrl(url: String) = prefs.edit().putString("source_url", url).apply()
    fun getFavorites(): Set<String> = prefs.getStringSet("favorites", emptySet()) ?: emptySet()
    fun saveFavorites(set: Set<String>) = prefs.edit().putStringSet("favorites", set).apply()
}
EOF

# 6.3 MyApplication
cat > android/app/src/main/java/com/ku9/player/MyApplication.kt <<'EOF'
package com.ku9.player

import android.app.Application

class MyApplication : Application() {
    lateinit var playerManager: PlayerManager
        private set

    override fun onCreate() {
        super.onCreate()
        playerManager = PlayerManager(this)
        SettingsManager.init(this)
    }
}
EOF

# 6.4 PlayerManager (修正导入)
cat > android/app/src/main/java/com/ku9/player/PlayerManager.kt <<'EOF'
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
import androidx.media3.exoplayer.upstream.DefaultLoadErrorHandlingPolicy
import java.util.concurrent.atomic.AtomicBoolean

@UnstableApi
class PlayerManager(private val context: Context) {
    private var exoPlayer: ExoPlayer? = null
    private var trackSelector: DefaultTrackSelector? = null
    private var currentUrl: String? = null
    private var currentHeaders: Map<String, String> = emptyMap()
    private var isHardwareDecoder = true
    private var retryCount = 0
    private val mainHandler = Handler(Looper.getMainLooper())
    private val isReleased = AtomicBoolean(false)

    private val playerListener = object : Player.Listener {
        override fun onPlaybackStateChanged(playbackState: Int) {
            if (playbackState == Player.STATE_READY) retryCount = 0
        }
        override fun onPlayerError(error: PlaybackException) {
            if (retryCount < 3 && !isReleased.get()) {
                retryCount++
                mainHandler.postDelayed({
                    currentUrl?.let { play(it, currentHeaders) }
                }, 2000L * retryCount)
            }
        }
    }

    private fun initPlayer(): ExoPlayer {
        if (exoPlayer == null) {
            val dataSourceFactory = DefaultHttpDataSource.Factory()
                .setAllowCrossProtocolRedirects(true)
                .setConnectTimeoutMs(10000)
                .setReadTimeoutMs(10000)
                .setDefaultRequestProperties(currentHeaders)

            trackSelector = DefaultTrackSelector(context).apply {
                setParameters(
                    buildUponParameters()
                        .setHardwareCodecEnabled(isHardwareDecoder)
                        .setMaxVideoSize(1920, 1080)
                )
            }
            val loadErrorHandlingPolicy = DefaultLoadErrorHandlingPolicy(3)

            exoPlayer = ExoPlayer.Builder(context)
                .setTrackSelector(trackSelector)
                .setLoadErrorHandlingPolicy(loadErrorHandlingPolicy)
                .build()
                .apply {
                    addListener(playerListener)
                    setVideoScalingMode(C.VIDEO_SCALING_MODE_SCALE_TO_FIT)
                }
        }
        return exoPlayer!!
    }

    fun play(url: String, headers: Map<String, String> = emptyMap()) {
        if (isReleased.get()) return
        currentUrl = url
        currentHeaders = headers
        val player = initPlayer()
        val dataSourceFactory = DefaultHttpDataSource.Factory()
            .setAllowCrossProtocolRedirects(true)
            .setDefaultRequestProperties(headers)
        val mediaSource = HlsMediaSource.Factory(dataSourceFactory)
            .setAllowChunklessPreparation(true)
            .createMediaSource(MediaItem.fromUri(Uri.parse(url)))
        player.setMediaSource(mediaSource)
        player.prepare()
        player.play()
    }

    fun pause() { exoPlayer?.pause() }
    fun resume() { exoPlayer?.play() }
    fun stop() { exoPlayer?.stop() }
    fun release() {
        isReleased.set(true)
        mainHandler.removeCallbacksAndMessages(null)
        exoPlayer?.apply {
            removeListener(playerListener)
            release()
        }
        exoPlayer = null
        trackSelector = null
    }
    fun seekTo(positionMs: Long) { exoPlayer?.seekTo(positionMs) }
    fun getCurrentPosition(): Long = exoPlayer?.currentPosition ?: 0
    fun getDuration(): Long = exoPlayer?.duration ?: 0
    fun isPlaying(): Boolean = exoPlayer?.isPlaying ?: false

    fun switchDecoder(useHardware: Boolean) {
        if (isHardwareDecoder == useHardware) return
        isHardwareDecoder = useHardware
        currentUrl?.let { url ->
            val position = getCurrentPosition()
            release()
            isReleased.set(false)
            play(url, currentHeaders)
            if (position > 0) exoPlayer?.seekTo(position)
        }
    }

    fun setAspectRatio(ratio: String) {
        val player = exoPlayer ?: return
        val scalingMode = when (ratio) {
            "fill" -> C.VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING
            else -> C.VIDEO_SCALING_MODE_SCALE_TO_FIT
        }
        player.setVideoScalingMode(scalingMode)
    }

    fun isUsingHardwareDecoder(): Boolean = isHardwareDecoder
    fun addListener(listener: Player.Listener) { exoPlayer?.addListener(listener) }
    fun removeListener(listener: Player.Listener) { exoPlayer?.removeListener(listener) }
}
EOF

# 6.5 SourceManager
cat > android/app/src/main/java/com/ku9/player/SourceManager.kt <<'EOF'
package com.ku9.player

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.InputStream
import java.net.URL

class SourceManager(private val context: Context) {

    data class Source(val name: String, val url: String, val type: SourceType) {
        enum class SourceType { M3U, TXT }
    }

    private val sources = mutableListOf<Source>()
    private var currentSourceIndex = 0
    private var currentGroups: List<Group> = emptyList()

    suspend fun addSource(name: String, url: String, type: Source.SourceType): Boolean {
        return try {
            sources.add(Source(name, url, type))
            true
        } catch (e: Exception) {
            false
        }
    }

    suspend fun loadSource(index: Int): List<Group> {
        if (index !in sources.indices) return emptyList()
        currentSourceIndex = index
        val source = sources[index]
        return withContext(Dispatchers.IO) {
            try {
                val inputStream: InputStream = if (source.url.startsWith("http")) {
                    URL(source.url).openStream()
                } else {
                    File(source.url).inputStream()
                }
                val content = inputStream.bufferedReader().readText()
                inputStream.close()
                currentGroups = when (source.type) {
                    Source.SourceType.M3U -> M3UParser.parse(content)
                    Source.SourceType.TXT -> parseTXT(content)
                }
                currentGroups
            } catch (e: Exception) {
                e.printStackTrace()
                emptyList()
            }
        }
    }

    suspend fun switchToNextSource(): List<Group>? {
        if (sources.isEmpty()) return null
        val nextIndex = (currentSourceIndex + 1) % sources.size
        return loadSource(nextIndex)
    }

    fun getCurrentGroups(): List<Group> = currentGroups
    fun getSources(): List<Source> = sources
    fun getCurrentSourceIndex(): Int = currentSourceIndex

    private fun parseTXT(content: String): List<Group> {
        val channels = content.lines()
            .mapNotNull { line ->
                val trimmed = line.trim()
                if (trimmed.isEmpty() || trimmed.startsWith("#")) return@mapNotNull null
                val parts = trimmed.split(",", limit = 2)
                if (parts.size >= 2) {
                    Channel(name = parts[0].trim(), url = parts[1].trim(), logo = "")
                } else null
            }
        return listOf(Group("默认", channels))
    }
}
EOF

# 6.6 EPGManager
cat > android/app/src/main/java/com/ku9/player/EPGManager.kt <<'EOF'
package com.ku9.player

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*

class EPGManager {

    suspend fun loadEPG(xmlUrl: String, channelId: String, offsetDays: Int = 0): List<EpgProgram> =
        withContext(Dispatchers.IO) {
            try {
                val xml = URL(xmlUrl).readText()
                parseXMLTV(xml, channelId, offsetDays)
            } catch (e: Exception) {
                emptyList()
            }
        }

    private fun parseXMLTV(xml: String, channelId: String, offsetDays: Int): List<EpgProgram> {
        val list = mutableListOf<EpgProgram>()
        val regex = Regex("<programme[^>]*channel=\"$channelId\"[^>]*>.*?</programme>", RegexOption.DOTALL)
        val sdf = SimpleDateFormat("yyyyMMddHHmmss Z", Locale.getDefault())
        val calendar = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, offsetDays) }
        val dayStart = calendar.apply { set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0) }.timeInMillis
        val dayEnd = dayStart + 24 * 60 * 60 * 1000

        regex.findAll(xml).forEach { matchResult ->
            val block = matchResult.value
            val title = Regex("<title>(.*?)</title>").find(block)?.groupValues?.get(1) ?: ""
            val start = Regex("start=\"(.*?)\"").find(block)?.groupValues?.get(1) ?: ""
            val end = Regex("end=\"(.*?)\"").find(block)?.groupValues?.get(1) ?: ""
            val startTime = try { sdf.parse(start.replace("+0000", " +0000"))?.time ?: 0 } catch (_: Exception) { 0 }
            val endTime = try { sdf.parse(end.replace("+0000", " +0000"))?.time ?: 0 } catch (_: Exception) { 0 }
            if (startTime >= dayStart && startTime < dayEnd) {
                list.add(EpgProgram(title, startTime, endTime, ""))
            }
        }
        return list.sortedBy { it.startTime }
    }
}
EOF

# 6.7 M3UParser
cat > android/app/src/main/java/com/ku9/player/M3UParser.kt <<'EOF'
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
EOF

# 6.8 NetworkUtils (修正 okhttp 导入)
cat > android/app/src/main/java/com/ku9/player/NetworkUtils.kt <<'EOF'
package com.ku9.player

import okhttp3.*
import java.io.IOException

object NetworkUtils {
    private val client = OkHttpClient.Builder()
        .connectTimeout(10, java.util.concurrent.TimeUnit.SECONDS)
        .readTimeout(10, java.util.concurrent.TimeUnit.SECONDS)
        .build()

    fun get(url: String, callback: (String?) -> Unit) {
        val request = Request.Builder().url(url).build()
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                callback(null)
            }
            override fun onResponse(call: Call, response: Response) {
                response.body?.string()?.let { callback(it) } ?: callback(null)
            }
        })
    }
}
EOF

# 6.9 MainActivity
cat > android/app/src/main/java/com/ku9/player/MainActivity.kt <<'EOF'
package com.ku9.player

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import com.google.android.material.bottomnavigation.BottomNavigationView

class MainActivity : AppCompatActivity() {

    private lateinit var bottomNav: BottomNavigationView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        bottomNav = findViewById(R.id.bottom_navigation)

        if (savedInstanceState == null) {
            switchFragment(ChannelListFragment())
        }

        bottomNav.setOnItemSelectedListener { item ->
            when (item.itemId) {
                R.id.nav_channels -> { switchFragment(ChannelListFragment()); true }
                R.id.nav_epg -> { switchFragment(EPGFragment()); true }
                R.id.nav_settings -> { switchFragment(SettingsFragment()); true }
                else -> false
            }
        }
    }

    private fun switchFragment(fragment: Fragment) {
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, fragment)
            .commit()
    }
}
EOF

# 6.10 ChannelListFragment
cat > android/app/src/main/java/com/ku9/player/ChannelListFragment.kt <<'EOF'
package com.ku9.player

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.SearchView
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class ChannelListFragment : Fragment() {

    private lateinit var recyclerView: RecyclerView
    private lateinit var searchView: SearchView
    private lateinit var adapter: ChannelAdapter
    private val sourceManager by lazy { SourceManager(requireContext()) }
    private var allChannels: List<Channel> = emptyList()

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        return inflater.inflate(R.layout.fragment_channel_list, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        recyclerView = view.findViewById(R.id.channel_recycler)
        searchView = view.findViewById(R.id.search_view)

        adapter = ChannelAdapter { channel ->
            val app = requireContext().applicationContext as MyApplication
            app.playerManager.play(channel.url, mapOf("User-Agent" to "Ku9Player"))
        }
        recyclerView.layoutManager = LinearLayoutManager(context)
        recyclerView.adapter = adapter

        searchView.setOnQueryTextListener(object : SearchView.OnQueryTextListener {
            override fun onQueryTextSubmit(query: String?): Boolean {
                filterChannels(query ?: "")
                return true
            }
            override fun onQueryTextChange(newText: String?): Boolean {
                filterChannels(newText ?: "")
                return true
            }
        })

        loadSource()
    }

    private fun loadSource() {
        CoroutineScope(Dispatchers.Main).launch {
            val url = SettingsManager.getSourceUrl()
            if (url.isNotEmpty()) {
                sourceManager.addSource("我的源", url, SourceManager.Source.SourceType.M3U)
                val groups = sourceManager.loadSource(0)
                allChannels = groups.flatMap { it.channels }
                adapter.submitList(allChannels)
            } else {
                // 默认测试源
                val testUrl = "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8"
                sourceManager.addSource("测试", testUrl, SourceManager.Source.SourceType.M3U)
                val groups = sourceManager.loadSource(0)
                allChannels = groups.flatMap { it.channels }
                adapter.submitList(allChannels)
            }
        }
    }

    private fun filterChannels(query: String) {
        val filtered = if (query.isBlank()) allChannels
        else allChannels.filter { it.name.contains(query, ignoreCase = true) }
        adapter.submitList(filtered)
    }
}
EOF

# 6.11 EPGFragment
cat > android/app/src/main/java/com/ku9/player/EPGFragment.kt <<'EOF'
package com.ku9.player

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

class EPGFragment : Fragment() {

    private lateinit var recyclerView: RecyclerView
    private lateinit var dateTextView: TextView
    private lateinit var prevDayBtn: Button
    private lateinit var nextDayBtn: Button
    private lateinit var adapter: EpgAdapter

    private val epgManager = EPGManager()
    private var currentOffset = 0

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        return inflater.inflate(R.layout.fragment_epg, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        recyclerView = view.findViewById(R.id.epg_recycler)
        dateTextView = view.findViewById(R.id.date_text)
        prevDayBtn = view.findViewById(R.id.prev_day)
        nextDayBtn = view.findViewById(R.id.next_day)

        adapter = EpgAdapter()
        recyclerView.layoutManager = LinearLayoutManager(context)
        recyclerView.adapter = adapter

        loadEPG(currentOffset)

        prevDayBtn.setOnClickListener {
            currentOffset--
            loadEPG(currentOffset)
        }
        nextDayBtn.setOnClickListener {
            currentOffset++
            loadEPG(currentOffset)
        }
    }

    private fun loadEPG(offset: Int) {
        val calendar = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, offset) }
        val dateStr = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(calendar.time)
        dateTextView.text = dateStr

        CoroutineScope(Dispatchers.Main).launch {
            val epgUrl = SettingsManager.getEpgUrl()
            if (epgUrl.isNotEmpty()) {
                val programs = epgManager.loadEPG(epgUrl, "channel123", offset)
                adapter.submitList(programs)
            }
        }
    }
}
EOF

# 6.12 SettingsFragment
cat > android/app/src/main/java/com/ku9/player/SettingsFragment.kt <<'EOF'
package com.ku9.player

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.Switch
import androidx.appcompat.app.AlertDialog
import androidx.fragment.app.Fragment

class SettingsFragment : Fragment() {

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        return inflater.inflate(R.layout.fragment_settings, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val decoderSwitch = view.findViewById<Switch>(R.id.decoder_switch)
        decoderSwitch.isChecked = SettingsManager.isHardwareDecoder()
        decoderSwitch.setOnCheckedChangeListener { _, isChecked ->
            SettingsManager.setHardwareDecoder(isChecked)
            val app = requireContext().applicationContext as MyApplication
            app.playerManager.switchDecoder(isChecked)
        }

        val epgUrlEdit = view.findViewById<EditText>(R.id.epg_url_edit)
        epgUrlEdit.setText(SettingsManager.getEpgUrl())
        view.findViewById<Button>(R.id.save_epg_btn).setOnClickListener {
            SettingsManager.saveEpgUrl(epgUrlEdit.text.toString())
        }

        val sourceUrlEdit = view.findViewById<EditText>(R.id.source_url_edit)
        sourceUrlEdit.setText(SettingsManager.getSourceUrl())
        view.findViewById<Button>(R.id.save_source_btn).setOnClickListener {
            SettingsManager.saveSourceUrl(sourceUrlEdit.text.toString())
        }

        view.findViewById<Button>(R.id.add_source_btn).setOnClickListener {
            showAddSourceDialog()
        }
    }

    private fun showAddSourceDialog() {
        val builder = AlertDialog.Builder(requireContext())
        builder.setTitle("添加直播源")
        val view = layoutInflater.inflate(R.layout.dialog_add_source, null)
        val nameEdit = view.findViewById<EditText>(R.id.source_name)
        val urlEdit = view.findViewById<EditText>(R.id.source_url)
        builder.setView(view)
        builder.setPositiveButton("添加") { _, _ ->
            val name = nameEdit.text.toString()
            val url = urlEdit.text.toString()
            if (name.isNotBlank() && url.isNotBlank()) {
                SettingsManager.saveSourceUrl(url)
            }
        }
        builder.setNegativeButton("取消", null)
        builder.show()
    }
}
EOF

# 6.13 ChannelAdapter
cat > android/app/src/main/java/com/ku9/player/ChannelAdapter.kt <<'EOF'
package com.ku9.player

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.ku9.player.databinding.ItemChannelBinding

class ChannelAdapter(private val onItemClick: (Channel) -> Unit) :
    RecyclerView.Adapter<ChannelAdapter.ViewHolder>() {

    private var items: List<Channel> = emptyList()

    fun submitList(list: List<Channel>) {
        items = list
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemChannelBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val channel = items[position]
        holder.binding.channelName.text = channel.name
        holder.binding.root.setOnClickListener { onItemClick(channel) }
    }

    override fun getItemCount() = items.size

    class ViewHolder(val binding: ItemChannelBinding) : RecyclerView.ViewHolder(binding.root)
}
EOF

# 6.14 EpgAdapter
cat > android/app/src/main/java/com/ku9/player/EpgAdapter.kt <<'EOF'
package com.ku9.player

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.ku9.player.databinding.ItemEpgBinding
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
        val binding = ItemEpgBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val program = items[position]
        holder.binding.epgTitle.text = program.title
        val startStr = timeFormat.format(Date(program.startTime))
        val endStr = timeFormat.format(Date(program.endTime))
        holder.binding.epgTime.text = "$startStr - $endStr"
    }

    override fun getItemCount() = items.size

    class ViewHolder(val binding: ItemEpgBinding) : RecyclerView.ViewHolder(binding.root)
}
EOF

# ========== 7. 赋予执行权限 ==========
chmod +x android/gradlew 2>/dev/null || true

echo "所有修正已完成！请提交并运行 GitHub Actions。"
