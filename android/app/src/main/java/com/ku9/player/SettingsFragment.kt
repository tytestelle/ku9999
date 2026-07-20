package com.ku9.player

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.Switch
import androidx.fragment.app.Fragment
import androidx.appcompat.app.AlertDialog

class SettingsFragment : Fragment() {

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        return inflater.inflate(R.layout.fragment_settings, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // 硬解/软解开关
        val decoderSwitch = view.findViewById<Switch>(R.id.decoder_switch)
        decoderSwitch.isChecked = SettingsManager.isHardwareDecoder()
        decoderSwitch.setOnCheckedChangeListener { _, isChecked ->
            SettingsManager.setHardwareDecoder(isChecked)
            // 通知播放器切换
            (activity as? MainActivity)?.let {
                // 获取PlayerManager并切换
                val playerManager = (requireContext().applicationContext as? MyApplication)?.playerManager
                playerManager?.switchDecoder(isChecked)
            }
        }

        // 设置EPG URL
        val epgUrlEdit = view.findViewById<EditText>(R.id.epg_url_edit)
        epgUrlEdit.setText(SettingsManager.getEpgUrl())

        val saveEpgBtn = view.findViewById<Button>(R.id.save_epg_btn)
        saveEpgBtn.setOnClickListener {
            val url = epgUrlEdit.text.toString()
            SettingsManager.saveEpgUrl(url)
        }

        // 添加直播源（弹出对话框输入URL）
        val addSourceBtn = view.findViewById<Button>(R.id.add_source_btn)
        addSourceBtn.setOnClickListener {
            showAddSourceDialog()
        }
    }

    private fun showAddSourceDialog() {
        val builder = AlertDialog.Builder(requireContext())
        builder.setTitle("添加直播源")
        val view = layoutInflater.inflate(R.layout.dialog_add_source, null)
        val nameEdit = view.findViewById<EditText>(R.id.source_name)
        val urlEdit = view.findViewById<EditText>(R.id.source_url)
        builder.setView(view)
        builder.setPositiveButton("添加") { _, _ ->
            val name = nameEdit.text.toString()
            val url = urlEdit.text.toString()
            if (name.isNotBlank() && url.isNotBlank()) {
                // 将源保存到SourceManager（需获取实例）
                // 实际可保存到SharedPreferences或数据库
                // 此处略
            }
        }
        builder.setNegativeButton("取消", null)
        builder.show()
    }
}
