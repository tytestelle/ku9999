package com.ku9.player.ui

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.ku9.player.R
import com.ku9.player.data.Channel

class ChannelAdapter(
    private var items: List<Channel>,
    private val onItemClick: (Int) -> Unit
) : RecyclerView.Adapter<ChannelAdapter.ViewHolder>() {

    private var highlightPosition = -1

    fun updateData(newItems: List<Channel>) {
        items = newItems
        highlightPosition = -1
        notifyDataSetChanged()
    }

    fun highlightItem(position: Int) {
        highlightPosition = position
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_channel, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val channel = items[position]
        holder.tvName.text = channel.name
        holder.itemView.setBackgroundColor(
            if (position == highlightPosition) 0x33000000 else 0x00000000
        )
        holder.itemView.setOnClickListener { onItemClick(position) }
    }

    override fun getItemCount() = items.size

    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val tvName: TextView = itemView.findViewById(R.id.tvChannelName)
    }
}
