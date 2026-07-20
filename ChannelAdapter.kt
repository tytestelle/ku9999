package com.ku9.player

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide

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
        // 加载台标
        if (item.logoUrl.isNotEmpty()) {
            Glide.with(holder.itemView.context)
                .load(item.logoUrl)
                .into(holder.ivLogo)
        }
        holder.itemView.setOnClickListener { onItemClick(item) }
        // 收藏状态
        val isFav = SettingsManager.isFavorite(item.id)
        holder.ivFavorite.setImageResource(
            if (isFav) android.R.drawable.star_on else android.R.drawable.star_off
        )
        holder.ivFavorite.setOnClickListener {
            onFavoriteClick?.invoke(item)
        }
    }

    override fun getItemCount() = items.size

    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val tvName: TextView = view.findViewById(R.id.tv_channel_name)
        val ivLogo: ImageView = view.findViewById(R.id.iv_logo)
        val ivFavorite: ImageView = view.findViewById(R.id.iv_favorite)
    }
}
