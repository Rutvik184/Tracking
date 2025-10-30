package com.tracking.data.repository

import com.tracking.data.api.LocationApi
import com.tracking.data.api.LocationRequest
import android.util.Log
import java.text.SimpleDateFormat
import java.util.*

class LocationRepository(private val api: LocationApi) {

    suspend fun requestSendLocation(userId: Int, lat: Double, lng: Double) {
        try {
            val timestamp = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())
            val response = api.requestSendLocation(LocationRequest(userId, lat, lng))
            if (response.isSuccessful) {
                Log.d("LocationRepo", "✅ Location sent: ${response.body()?.db_save}")
            } else {
                Log.e("LocationRepo", "❌ API Error: ${response.code()} - ${response.message()}")
            }
        } catch (e: Exception) {
            Log.e("LocationRepo", "🚨 Exception: ${e.localizedMessage}")
        }
    }
}
