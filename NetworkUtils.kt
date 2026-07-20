package com.ku9.player

import kotlinx.coroutines.suspendCancellableCoroutine
import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import java.io.IOException
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

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
                            continuation.resumeWithException(IOException("Unexpected code ${it.code()}"))
                        } else {
                            val body = it.body?.string()
                            if (body != null) {
                                continuation.resume(body)
                            } else {
                                continuation.resumeWithException(IOException("Response body is null"))
                            }
                        }
                    }
                }
            })
        }
    }
}
