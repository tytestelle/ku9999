package com.ku9.player

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.launch

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

        val rvChannels = findViewById<RecyclerView>(R.id.rv_channels)
        val rvGroups = findViewById<RecyclerView>(R.id.rv_groups)

        channelAdapter = ChannelAdapter { channel ->
            lifecycleScope.launch {
                showToast("点击频道: ${channel.name}")
                // 这里可以调用播放器
            }
        }
        groupAdapter = GroupAdapter { group ->
            lifecycleScope.launch {
                showToast("点击分组: ${group.name}")
            }
        }

        rvChannels.layoutManager = LinearLayoutManager(this)
        rvChannels.adapter = channelAdapter
        rvGroups.layoutManager = LinearLayoutManager(this)
        rvGroups.adapter = groupAdapter

        lifecycleScope.launch {
            sourceManager.loadData()
            channelAdapter.setData(sourceManager.channels)
            groupAdapter.setData(sourceManager.groups)
        }
    }
}
