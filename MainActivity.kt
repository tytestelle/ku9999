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

        // 假设布局中有两个 RecyclerView，ID 分别为 rv_channels 和 rv_groups
        val rvChannels = findViewById<RecyclerView>(R.id.rv_channels)
        val rvGroups = findViewById<RecyclerView>(R.id.rv_groups)

        channelAdapter = ChannelAdapter { channel ->
            lifecycleScope.launch {
                // 处理频道点击，例如加载播放
                showToast("点击频道：${channel.name}")
            }
        }
        groupAdapter = GroupAdapter { group ->
            lifecycleScope.launch {
                // 处理分组点击
                showToast("点击分组：${group.name}")
            }
        }

        rvChannels.layoutManager = LinearLayoutManager(this)
        rvChannels.adapter = channelAdapter
        rvGroups.layoutManager = LinearLayoutManager(this)
        rvGroups.adapter = groupAdapter

        // 加载数据
        lifecycleScope.launch {
            sourceManager.loadData()
            // 假设 sourceManager 有 channels 和 groups 公开属性
            channelAdapter.setData(sourceManager.channels)
            groupAdapter.setData(sourceManager.groups)
        }
    }
}
