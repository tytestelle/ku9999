package com.ku9.player

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import java.text.SimpleDateFormat
import java.util.*

class EPGFragment : Fragment() {

    private lateinit var rvEpg: RecyclerView
    private lateinit var tvChannelName: TextView
    private val epgManager = EPGManager()

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

        // 示例：加载当前频道的 EPG（需从 MainActivity 获取当前播放频道）
        // 实际应通过接口传递，此处简化
        val channel = (activity as? MainActivity)?.getSourceManager()?.channels?.firstOrNull()
        tvChannelName.text = channel?.name ?: "未选择频道"
        val epgData = epgManager.loadEPG("https://example.com/epg.xml") // 替换真实地址
        val adapter = EPGAdapter(epgData)
        rvEpg.adapter = adapter
    }
}
