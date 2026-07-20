package com.ku9.player

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.bottomnavigation.BottomNavigationView

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // 初始化 SettingsManager（改为调用 init）
        SettingsManager.init(this)

        val bottomNav = findViewById<BottomNavigationView>(R.id.bottom_navigation)
        bottomNav.setOnItemSelectedListener { item ->
            when (item.itemId) {
                R.id.nav_channels -> {
                    supportFragmentManager.beginTransaction()
                        .replace(R.id.fragment_container, ChannelListFragment())
                        .commit()
                    true
                }
                R.id.nav_epg -> {
                    Toast.makeText(this, "EPG功能开发中", Toast.LENGTH_SHORT).show()
                    true
                }
                R.id.nav_settings -> {
                    Toast.makeText(this, "设置功能开发中", Toast.LENGTH_SHORT).show()
                    true
                }
                else -> false
            }
        }
        bottomNav.selectedItemId = R.id.nav_channels
    }
}
