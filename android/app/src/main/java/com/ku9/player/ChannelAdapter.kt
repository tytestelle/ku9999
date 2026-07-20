package com.ku9.player

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.ku9.player.databinding.ItemChannelBinding

class ChannelAdapter(private val onItemClick: (Channel) -> Unit) :
    RecyclerView.Adapter<ChannelAdapter.ViewHolder>() {

    private var items: List<Channel> = emptyList()

    fun submitList(list: List<Channel>) {
        items = list
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemChannelBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val channel = items[position]
        holder.binding.channelName.text = channel.name
        holder.binding.root.setOnClickListener { onItemClick(channel) }
    }

    override fun getItemCount() = items.size

    class ViewHolder(val binding: ItemChannelBinding) : RecyclerView.ViewHolder(binding.root)
}
