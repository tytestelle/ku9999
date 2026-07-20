package com.ku9.player

import android.os.Bundle
import android.view.*
import android.widget.*
import androidx.appcompat.widget.SearchView
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.launch

class ChannelListFragment : Fragment() {

    private lateinit var rvChannels: RecyclerView
    private lateinit var spinnerGroups: Spinner
    private lateinit var searchView: SearchView
    private lateinit var adapter: ChannelAdapter
    private val mainActivity by lazy { activity as MainActivity }
    private val sourceManager by lazy { mainActivity.getSourceManager() }
    private val playerManager by lazy { mainActivity.getPlayerManager() }
    private val settingsManager by lazy { mainActivity.getSettingsManager() }
    private var allChannels: List<Channel> = emptyList()

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_channel_list, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        rvChannels = view.findViewById(R.id.rv_channels)
        spinnerGroups = view.findViewById(R.id.spinner_groups)
        searchView = view.findViewById(R.id.search_view)

        rvChannels.layoutManager = LinearLayoutManager(requireContext())

        adapter = ChannelAdapter(
            onItemClick = { channel ->
                playerManager.play(channel.url, channel.headers)
                Toast.makeText(requireContext(), "播放: ${channel.name}", Toast.LENGTH_SHORT).show()
            },
            onFavoriteClick = { channel ->
                settingsManager.toggleFavorite(channel.id)
                adapter.notifyDataSetChanged()
            }
        )
        rvChannels.adapter = adapter

        // 加载分组下拉
        lifecycleScope.launch {
            sourceManager.groups.let { groups ->
                allChannels = sourceManager.channels
                val groupNames = groups.map { it.name }.toMutableList()
                groupNames.add(0, "全部")
                val spinnerAdapter = ArrayAdapter(requireContext(), android.R.layout.simple_spinner_item, groupNames)
                spinnerAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
                spinnerGroups.adapter = spinnerAdapter
                spinnerGroups.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                    override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                        val selectedGroup = if (position == 0) null else groups[position - 1]
                        val filtered = if (selectedGroup == null) allChannels else selectedGroup.channels
                        adapter.setData(filtered)
                    }
                    override fun onNothingSelected(parent: AdapterView<*>?) {}
                }
                // 默认显示全部
                adapter.setData(allChannels)
            }
        }

        // 搜索功能
        searchView.setOnQueryTextListener(object : SearchView.OnQueryTextListener {
            override fun onQueryTextSubmit(query: String?): Boolean {
                filterChannels(query)
                return true
            }
            override fun onQueryTextChange(newText: String?): Boolean {
                filterChannels(newText)
                return true
            }
        })
    }

    private fun filterChannels(query: String?) {
        if (query.isNullOrEmpty()) {
            adapter.setData(allChannels)
        } else {
            val filtered = allChannels.filter { it.name.contains(query, ignoreCase = true) }
            adapter.setData(filtered)
        }
    }
}
