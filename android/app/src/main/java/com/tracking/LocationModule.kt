package com.tracking

import android.content.Intent
import android.os.Build
import com.facebook.react.bridge.*
import android.util.Log

class LocationModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName() = "LocationModule"

    @ReactMethod
    fun startLogging(a1: String, a2: String, a3: Int, promise: Promise) {
        try {
            val intent = Intent(reactContext, LocationService::class.java)
            intent.putExtra("arg1", a1)
            intent.putExtra("arg2", a2)
            intent.putExtra("arg3", a3.toLong())

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                reactContext.startForegroundService(intent)
            } else {
                reactContext.startService(intent)
            }

            promise.resolve("Background service started")
        } catch (e: Exception) {
            promise.reject("START_FAILED", e)
        }
    }

    @ReactMethod
    fun stopLogging(promise: Promise) {
        try {
            val intent = Intent(reactContext, LocationService::class.java)
            reactContext.stopService(intent)
            promise.resolve("Background service stopped")
        } catch (e: Exception) {
            promise.reject("STOP_FAILED", e)
        }
    }
}
