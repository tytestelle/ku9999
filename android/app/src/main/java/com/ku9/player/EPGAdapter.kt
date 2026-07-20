package com.ku9.player

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.ku9.player.databinding.ItemEpgBinding
import java.text.SimpleDateFormat
import java.util.*

class EpgAdapter : RecyclerView.Adapter<EpgAdapter.ViewHolder>() {

    private var items: List<EpgProgram> = emptyList()
    private val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())

    fun submitList(list: List<EpgProgram>) {
        items = list
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemEpgBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val program = items[position]
        holder.binding.epgTitle.text = program.title
        val startStr = timeFormat.format(Date(program.startTime))
        val endStr = timeFormat.format(Date(program.endTime))
        holder.binding.epgTime.text = "$startStr - $endStr"
    }

    override fun getItemCount() = items.size

    class ViewHolder(val binding: ItemEpgBinding) : RecyclerView.ViewHolder(binding.root)
}
