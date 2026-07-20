package com.ku9.player

data class Subscription(val name: String, val url: String, val type: String = "m3u") // type: m3u, txt, json

class SubscriptionManager {
    private val subscriptions = mutableListOf<Subscription>()

    fun addSubscription(sub: Subscription) {
        subscriptions.add(sub)
        // 保存到文件或SharedPreferences
    }

    fun getSubscriptions(): List<Subscription> = subscriptions
}
