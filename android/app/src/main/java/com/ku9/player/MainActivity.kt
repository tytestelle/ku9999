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
import kotlinx.coroutines.withContext

class ChannelListFragment : Fragment() {

    private lateinit var recyclerView: RecyclerView
    private lateinit var searchView: SearchView
    private lateinit var adapter: ChannelAdapter
    private val sourceManager = SourceManager(requireContext())
    private var allChannels: List<Channel> = emptyList()

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        return inflater.inflate(R.layout.fragment_channel_list, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        recyclerView = view.findViewById(R.id.channel_recycler)
        searchView = view.findViewById(R.id.search_view)

        adapter = ChannelAdapter { channel ->
            // 点击频道播放
            (activity as? MainActivity)?.let {
                // 通过PlayerManager播放
                val playerManager = (requireContext().applicationContext as? MyApplication)?.playerManager
                playerManager?.play(channel.url, mapOf("User-Agent" to "Ku9Player"))
            }
        }
        recyclerView.layoutManager = LinearLayoutManager(context)
        recyclerView.adapter = adapter

        // 搜索监听
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

        // 加载源（示例：可替换为你自己的源）
        loadSource()
    }

    private fun loadSource() {
        CoroutineScope(Dispatchers.Main).launch {
            // 添加一个测试源（实际应从设置或网络获取）
            val success = sourceManager.addSource(
                "默认源",
                "https://example.com/channels.m3u", // 替换为真实URL
                SourceManager.Source.SourceType.M3U
            )
            if (success) {
                val groups = sourceManager.loadSource(0)
                allChannels = groups.flatMap { it.channels }
                adapter.submitList(allChannels)
            }
        }
    }

    private fun filterChannels(query: String) {
        val filtered = if (query.isBlank()) {
            allChannels
        } else {
            allChannels.filter { it.name.contains(query, ignoreCase = true) }
        }
        adapter.submitList(filtered)
    }

    // 收藏功能：点击频道项的长按或图标，这里简化
    private fun toggleFavorite(channel: Channel) {
        val favorites = SettingsManager.getFavorites().toMutableSet()
        if (favorites.contains(channel.url)) {
            favorites.remove(channel.url)
        } else {
            favorites.add(channel.url)
        }
        SettingsManager.saveFavorites(favorites)
        // 刷新UI（adapter可刷新）
    }
}
