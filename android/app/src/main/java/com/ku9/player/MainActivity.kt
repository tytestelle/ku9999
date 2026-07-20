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
            // 从设置获取源URL，若为空则使用默认
            val url = SettingsManager.getSourceUrl()
            if (url.isNotEmpty()) {
                sourceManager.addSource("我的源", url, SourceManager.Source.SourceType.M3U)
                val groups = sourceManager.loadSource(0)
                allChannels = groups.flatMap { it.channels }
                adapter.submitList(allChannels)
            } else {
                // 可提示添加源
            }
        }
    }

    private fun filterChannels(query: String) {
        val filtered = if (query.isBlank()) allChannels
        else allChannels.filter { it.name.contains(query, ignoreCase = true) }
        adapter.submitList(filtered)
    }
}
