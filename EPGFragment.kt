package com.ku9.player

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class EPGFragment : Fragment() {

    private lateinit var rvEpg: RecyclerView
    private lateinit var tvChannelName: TextView
    private val epgManager = EPGManager()
    private val mainActivity by lazy { activity as MainActivity }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_epg, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        rvEpg = view.findViewById(R.id.rv_epg)
        tvChannelName = view.findViewById(R.id.tv_epg_channel_name)

        rvEpg.layoutManager = LinearLayoutManager(requireContext())

        // 获取当前选中的频道（示例取第一个）
        val channel = mainActivity.getSourceManager().channels.firstOrNull()
        tvChannelName.text = channel?.name ?: "未选择频道"

        // 加载 EPG（支持多格式）
        CoroutineScope(Dispatchers.IO).launch {
            val epgData = epgManager.loadEPG(channel?.epgUrl ?: "")
            withContext(Dispatchers.Main) {
                val adapter = EPGAdapter(epgData)
                rvEpg.adapter = adapter
            }
        }
    }
}
