package com.ku9.player

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.launch

// ---------- 扩展函数：显示 Toast ----------
fun MainActivity.showToast(msg: String) {
    Toast.makeText(this, msg, Toast.LENGTH_SHORT).show()
}

class MainActivity : AppCompatActivity() {

    private lateinit var channelAdapter: ChannelAdapter
    private lateinit var groupAdapter: GroupAdapter
    private val sourceManager = SourceManager()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // 初始化 RecyclerView 等 UI 组件（假设布局中有）
        val rvChannels = findViewById<RecyclerView>(R.id.rvChannels)
        val rvGroups = findViewById<RecyclerView>(R.id.rvGroups)

        channelAdapter = ChannelAdapter { channel ->
            // 点击频道逻辑
            lifecycleScope.launch {
                sourceManager.loadChannel(channel)
            }
        }
        groupAdapter = GroupAdapter { group ->
            // 点击分组逻辑
            lifecycleScope.launch {
                sourceManager.loadGroup(group)
            }
        }

        rvChannels.layoutManager = LinearLayoutManager(this)
        rvChannels.adapter = channelAdapter
        rvGroups.layoutManager = LinearLayoutManager(this)
        rvGroups.adapter = groupAdapter

        // 加载数据
        lifecycleScope.launch {
            sourceManager.loadData()
        }
    }

    // 示例：在其他地方调用 showToast
    private fun onError(msg: String) {
        showToast(msg)
    }
}
