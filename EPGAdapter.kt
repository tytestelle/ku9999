package com.ku9.player

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import java.text.SimpleDateFormat
import java.util.*

class EPGAdapter(private val programs: List<EPGProgram>) :
    RecyclerView.Adapter<EPGAdapter.ViewHolder>() {

    private val dateFormat = SimpleDateFormat("HH:mm", Locale.getDefault())

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_epg, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val program = programs[position]
        holder.tvTitle.text = program.title
        holder.tvTime.text = "${dateFormat.format(program.startTime)} - ${dateFormat.format(program.endTime)}"
        holder.tvDesc.text = program.desc
    }

    override fun getItemCount() = programs.size

    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val tvTitle: TextView = view.findViewById(R.id.tv_epg_title)
        val tvTime: TextView = view.findViewById(R.id.tv_epg_time)
        val tvDesc: TextView = view.findViewById(R.id.tv_epg_desc)
    }
}
