package com.ku9.player

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView

class ChannelAdapter(
    private val channels: List<Channel>,
    private val onItemClick: (Channel) -> Unit
) : RecyclerView.Adapter<ChannelAdapter.ViewHolder>() {
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_channel, parent, false)
        return ViewHolder(view)
    }
    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val channel = channels[position]
        holder.tvName.text = channel.name
        holder.ivLogo.setImageResource(android.R.drawable.ic_menu_gallery) // 占位图标
        holder.itemView.setOnClickListener { onItemClick(channel) }
    }
    override fun getItemCount() = channels.size

    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val tvName: TextView = view.findViewById(R.id.tvChannelName)
        val ivLogo: ImageView = view.findViewById(R.id.ivLogo)
    }
}
