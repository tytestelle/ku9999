package com.ku9.player

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

class EPGFragment : Fragment() {

    private lateinit var recyclerView: RecyclerView
    private lateinit var dateTextView: TextView
    private lateinit var prevDayBtn: Button
    private lateinit var nextDayBtn: Button
    private lateinit var adapter: EpgAdapter

    private val epgManager = EPGManager()
    private var currentOffset = 0 // 0=今天
    private var currentChannelId = "channel123" // 应从当前播放频道获取

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        return inflater.inflate(R.layout.fragment_epg, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        recyclerView = view.findViewById(R.id.epg_recycler)
        dateTextView = view.findViewById(R.id.date_text)
        prevDayBtn = view.findViewById(R.id.prev_day)
        nextDayBtn = view.findViewById(R.id.next_day)

        adapter = EpgAdapter()
        recyclerView.layoutManager = LinearLayoutManager(context)
        recyclerView.adapter = adapter

        // 加载今天EPG
        loadEPG(currentOffset)

        prevDayBtn.setOnClickListener {
            currentOffset--
            loadEPG(currentOffset)
        }
        nextDayBtn.setOnClickListener {
            currentOffset++
            loadEPG(currentOffset)
        }
    }

    private fun loadEPG(offset: Int) {
        // 更新日期显示
        val calendar = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, offset) }
        val dateStr = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(calendar.time)
        dateTextView.text = dateStr

        CoroutineScope(Dispatchers.Main).launch {
            // 从设置中获取EPG URL
            val epgUrl = SettingsManager.getEpgUrl() // 假设有此方法
            if (epgUrl.isNotEmpty()) {
                val programs = epgManager.loadEPG(epgUrl, currentChannelId, offset)
                adapter.submitList(programs)
            }
        }
    }
}
