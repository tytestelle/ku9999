package com.ku9.player

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView

class ChannelAdapter(
    private val onItemClick: (Channel) -> Unit,
    private val onFavoriteClick: ((Channel) -> Unit)? = null
) : RecyclerView.Adapter<ChannelAdapter.ViewHolder>() {

    private var items: List<Channel> = emptyList()

    fun setData(data: List<Channel>) {
        items = data
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_channel, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val item = items[position]
        holder.tvName.text = item.name
        holder.itemView.setOnClickListener { onItemClick(item) }
        holder.ivFavorite.setOnClickListener {
            onFavoriteClick?.invoke(item)
        }
        // 根据收藏状态更新图标（需配合 SettingsManager）
        holder.ivFavorite.setImageResource(
            if (SettingsManager.isFavorite(item.id)) android.R.drawable.star_on
            else android.R.drawable.star_off
        )
    }

    override fun getItemCount() = items.size

    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val tvName: TextView = view.findViewById(R.id.tv_channel_name)
        val ivFavorite: ImageView = view.findViewById(R.id.iv_favorite)
    }
}
