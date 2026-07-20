package com.ku9.player

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView

class GroupAdapter(
    private val groups: List<Group>,
    private val onItemClick: (Group) -> Unit
) : RecyclerView.Adapter<GroupAdapter.ViewHolder>() {
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_group, parent, false)
        return ViewHolder(view)
    }
    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val group = groups[position]
        holder.tvName.text = group.name
        holder.itemView.setOnClickListener { onItemClick(group) }
    }
    override fun getItemCount() = groups.size

    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val tvName: TextView = view.findViewById(R.id.tv_group_name)  // 与布局ID一致
    }
}
