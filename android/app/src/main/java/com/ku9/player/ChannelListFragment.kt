package com.ku9.player

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView

class ChannelListFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_channel_list, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val rvChannels = view.findViewById<RecyclerView>(R.id.rv_channels)
        rvChannels.layoutManager = LinearLayoutManager(requireContext())

        // 使用示例数据
        val channels = listOf(
            Channel("1", "CCTV-1", "http://example.com/1"),
            Channel("2", "CCTV-2", "http://example.com/2"),
            Channel("3", "CCTV-3", "http://example.com/3")
        )

        val adapter = ChannelAdapter { channel ->
            Toast.makeText(requireContext(), "播放: ${channel.name}", Toast.LENGTH_SHORT).show()
        }
        adapter.submitList(channels)
        rvChannels.adapter = adapter
    }
}
