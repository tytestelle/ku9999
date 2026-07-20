package com.ku9.player

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.Switch
import androidx.appcompat.app.AlertDialog
import androidx.fragment.app.Fragment

class SettingsFragment : Fragment() {

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        return inflater.inflate(R.layout.fragment_settings, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val decoderSwitch = view.findViewById<Switch>(R.id.decoder_switch)
        decoderSwitch.isChecked = SettingsManager.isHardwareDecoder()
        decoderSwitch.setOnCheckedChangeListener { _, isChecked ->
            SettingsManager.setHardwareDecoder(isChecked)
            val app = requireContext().applicationContext as MyApplication
            app.playerManager.switchDecoder(isChecked)
        }

        val epgUrlEdit = view.findViewById<EditText>(R.id.epg_url_edit)
        epgUrlEdit.setText(SettingsManager.getEpgUrl())
        view.findViewById<Button>(R.id.save_epg_btn).setOnClickListener {
            SettingsManager.saveEpgUrl(epgUrlEdit.text.toString())
        }

        val sourceUrlEdit = view.findViewById<EditText>(R.id.source_url_edit)
        sourceUrlEdit.setText(SettingsManager.getSourceUrl())
        view.findViewById<Button>(R.id.save_source_btn).setOnClickListener {
            SettingsManager.saveSourceUrl(sourceUrlEdit.text.toString())
        }

        view.findViewById<Button>(R.id.add_source_btn).setOnClickListener {
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
                // 可保存到设置或直接使用
                SettingsManager.saveSourceUrl(url)
            }
        }
        builder.setNegativeButton("取消", null)
        builder.show()
    }
}
