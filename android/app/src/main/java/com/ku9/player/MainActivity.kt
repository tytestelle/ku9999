package com.ku9.player

import android.os.Bundle
import android.view.MenuItem
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import com.google.android.material.bottomnavigation.BottomNavigationView
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {

    private lateinit var bottomNav: BottomNavigationView
    private val sourceManager = SourceManager()
    private val playerManager = PlayerManager()
    private val settingsManager = SettingsManager()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // 初始化设置管理器
        settingsManager.init(this)

        bottomNav = findViewById(R.id.bottom_navigation)
        bottomNav.setOnItemSelectedListener { item ->
            when (item.itemId) {
                R.id.nav_channels -> {
                    supportFragmentManager.beginTransaction()
                        .replace(R.id.fragment_container, ChannelListFragment())
                        .commit()
                    true
                }
                R.id.nav_epg -> {
                    supportFragmentManager.beginTransaction()
                        .replace(R.id.fragment_container, EPGFragment())
                        .commit()
                    true
                }
                R.id.nav_settings -> {
                    supportFragmentManager.beginTransaction()
                        .replace(R.id.fragment_container, SettingsFragment())
                        .commit()
                    true
                }
                else -> false
            }
        }
        bottomNav.selectedItemId = R.id.nav_channels

        // 初始化播放器
        playerManager.init(this)

        // 加载数据
        lifecycleScope.launch {
            sourceManager.loadData()
        }
    }

    fun getSourceManager() = sourceManager
    fun getPlayerManager() = playerManager
    fun getSettingsManager() = settingsManager

    override fun onDestroy() {
        playerManager.release()
        super.onDestroy()
    }
}
