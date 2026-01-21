package com.airplane.vpn

object VpnServiceManager {
    private var currentState: String = "disconnected"
    private var bytesIn: Long = 0
    private var bytesOut: Long = 0
    private var eventListener: ((Map<String, Any?>) -> Unit)? = null

    fun setEventListener(listener: ((Map<String, Any?>) -> Unit)?) {
        eventListener = listener
    }

    fun updateState(state: String) {
        currentState = state
        eventListener?.invoke(mapOf(
            "type" to "state_changed",
            "state" to state
        ))
    }

    fun updateStats(inBytes: Long, outBytes: Long) {
        bytesIn = inBytes
        bytesOut = outBytes
        eventListener?.invoke(mapOf(
            "type" to "stats_updated",
            "bytesIn" to bytesIn,
            "bytesOut" to bytesOut
        ))
    }

    fun sendError(message: String) {
        eventListener?.invoke(mapOf(
            "type" to "error",
            "message" to message
        ))
    }

    fun getCurrentState(): String = currentState
    fun getBytesIn(): Long = bytesIn
    fun getBytesOut(): Long = bytesOut

    fun resetStats() {
        bytesIn = 0
        bytesOut = 0
    }
}
