package com.ku9.player

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Spinner
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.launch

class ChannelListFragment : Fragment() {

    private lateinit var rvChannels: RecyclerView
    private lateinit var spinnerGroups: Spinner
    private lateinit var adapter: ChannelAdapter
    private val mainActivity by lazy { activity as MainActivity }
    private val sourceManager by lazy { mainActivity.getSourceManager() }

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

        rvChannels.layoutManager = LinearLayoutManager(requireContext())

        adapter = ChannelAdapter { channel ->
            // 点击播放
            mainActivity.getPlayerManager().play(channel.url)
            Toast.makeText(requireContext(), "播放: ${channel.name}", Toast.LENGTH_SHORT).show()
        }
        rvChannels.adapter = adapter

        // 加载分组下拉
        lifecycleScope.launch {
            sourceManager.groups.let { groups ->
                val groupNames = groups.map { it.name }.toMutableList()
                groupNames.add(0, "全部")
                val spinnerAdapter = ArrayAdapter(requireContext(), android.R.layout.simple_spinner_item, groupNames)
                spinnerAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
                spinnerGroups.adapter = spinnerAdapter
                spinnerGroups.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                    override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                        val selectedGroup = if (position == 0) null else groups[position - 1]
                        adapter.setData(if (selectedGroup == null) sourceManager.channels else selectedGroup.channels)
                    }
                    override fun onNothingSelected(parent: AdapterView<*>?) {}
                }
            }
        }
    }
}
