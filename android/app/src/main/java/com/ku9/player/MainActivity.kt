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

        // 初始化设置
        SettingsManager.init(this)

        bottomNav = findViewById(R.id.bottom_navigation)

        // 默认显示频道列表
        if (savedInstanceState == null) {
            switchFragment(ChannelListFragment())
        }

        bottomNav.setOnItemSelectedListener { item ->
            when (item.itemId) {
                R.id.nav_channels -> {
                    switchFragment(ChannelListFragment())
                    true
                }
                R.id.nav_epg -> {
                    switchFragment(EPGFragment())
                    true
                }
                R.id.nav_settings -> {
                    switchFragment(SettingsFragment())
                    true
                }
                else -> false
            }
        }
    }

    private fun switchFragment(fragment: Fragment) {
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, fragment)
            .commit()
    }

    // 提供全局访问PlayerManager（若需要）
    // 建议通过单例或依赖注入，这里简单在Application中持有
}
