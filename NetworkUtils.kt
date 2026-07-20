package com.ku9.player

import okhttp3.*
import java.io.IOException

object NetworkUtils {
    private val client = OkHttpClient()

    suspend fun fetchJson(url: String): String {
        return suspendCancellableCoroutine { continuation ->
            val request = Request.Builder()
                .url(url)
                .build()
            client.newCall(request).enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    continuation.resumeWithException(e)
                }
                override fun onResponse(call: Call, response: Response) {
                    response.use {
                        if (!it.isSuccessful) {
                            continuation.resumeWithException(IOException("Unexpected code $it"))
                        } else {
                            continuation.resume(it.body?.string() ?: "")
                        }
                    }
                }
            })
        }
    }
}
