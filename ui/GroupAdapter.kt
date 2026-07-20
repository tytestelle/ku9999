package com.ku9.player.ui

import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.ku9.player.R

class GroupAdapter(
    private var items: List<String>,
    private val onItemClick: (String) -> Unit
) : RecyclerView.Adapter<GroupAdapter.ViewHolder>() {

    fun updateData(newItems: List<String>) {
        items = newItems
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_group, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val group = items[position]
        holder.tvGroup.text = group
        holder.itemView.setOnClickListener { onItemClick(group) }
    }

    override fun getItemCount() = items.size

    class ViewHolder(itemView: android.view.View) : RecyclerView.ViewHolder(itemView) {
        val tvGroup: TextView = itemView.findViewById(R.id.tvGroupName)
    }
}
