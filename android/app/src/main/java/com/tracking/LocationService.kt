package com.tracking

import android.Manifest
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.*
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat

class LocationService : Service() {

    private lateinit var handler: Handler
    private var runnable: Runnable? = null
    private var locationManager: LocationManager? = null
    private var activeListeners = mutableListOf<LocationListener>()
    private var arg1: String? = null
    private var arg2: String? = null
    private var arg3: Long = 1000L

    companion object {
        private var instance: LocationService? = null

        fun stopServiceManually(context: Context) {
            instance?.stopLogging()
            val intent = Intent(context, LocationService::class.java)
            context.stopService(intent)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        handler = Handler(Looper.getMainLooper())
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        arg1 = intent?.getStringExtra("arg1")
        arg2 = intent?.getStringExtra("arg2")
        arg3 = intent?.getLongExtra("arg3", 1000L) ?: 1000L

        startForegroundService()
        startLocationLoop(arg3)
        return START_STICKY
    }

    private fun startForegroundService() {
        val channelId = "LocationChannel"
        val channelName = "Location Background Service"
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW)
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Location Active")
            .setContentText("Logging location every ${arg3 / 1000} seconds")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .build()

        startForeground(1, notification)
    }

    private fun startLocationLoop(interval: Long) {
        runnable = object : Runnable {
            override fun run() {
                try {
                    if (ActivityCompat.checkSelfPermission(
                            this@LocationService,
                            Manifest.permission.ACCESS_FINE_LOCATION
                        ) == PackageManager.PERMISSION_GRANTED
                    ) {
                        val listener = object : LocationListener {
                            override fun onLocationChanged(location: Location) {
                                Log.d(
                                    "LocationService",
                                    "Arg1: $arg1, Arg2: $arg2, Interval: $interval, " +
                                            "Lat: ${location.latitude}, Lng: ${location.longitude}"
                                )
                                // remove this listener once it receives a single update
                                try {
                                    locationManager?.removeUpdates(this)
                                    activeListeners.remove(this)
                                } catch (ex: Exception) {
                                    Log.e("LocationService", "removeUpdates failed: ${ex.message}")
                                }
                            }
                        }

                        activeListeners.add(listener)

                        locationManager?.requestSingleUpdate(
                            LocationManager.GPS_PROVIDER,
                            listener,
                            Looper.getMainLooper()
                        )
                    } else {
                        Log.e("LocationService", "Permission not granted")
                    }
                } catch (e: Exception) {
                    Log.e("LocationService", "Error: ${e.message}")
                }

                handler.postDelayed(this, interval)
            }
        }
        handler.post(runnable!!)
    }

    private fun stopLogging() {
        Log.d("LocationService", "Stopping location updates")

        // 1️⃣ Stop periodic runnable
        runnable?.let {
            handler.removeCallbacks(it)
            runnable = null
        }

        // 2️⃣ Remove all active listeners
        for (listener in activeListeners) {
            try {
                locationManager?.removeUpdates(listener)
            } catch (e: Exception) {
                Log.e("LocationService", "Error removing listener: ${e.message}")
            }
        }
        activeListeners.clear()

        // 3️⃣ Stop service
        stopForeground(true)
        stopSelf()
    }

    override fun onDestroy() {
        Log.d("LocationService", "Service destroyed")
        stopLogging()
        instance = null
        super.onDestroy()
    }
}
