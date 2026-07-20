package com.ku9.player

import android.os.Bundle
import android.view.MenuItem
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.viewpager2.adapter.FragmentStateAdapter
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.google.android.material.tabs.TabLayoutMediator
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {

    private lateinit var bottomNav: BottomNavigationView
    private val sourceManager = SourceManager()
    private val playerManager = PlayerManager()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

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
                    Toast.makeText(this, "设置页面待开发", Toast.LENGTH_SHORT).show()
                    true
                }
                else -> false
            }
        }
        // 默认显示频道列表
        bottomNav.selectedItemId = R.id.nav_channels

        // 初始化数据
        lifecycleScope.launch {
            sourceManager.loadData()
        }
    }

    // 提供给 Fragment 调用的方法
    fun getSourceManager() = sourceManager
    fun getPlayerManager() = playerManager

    override fun onDestroy() {
        playerManager.release()
        super.onDestroy()
    }
}
