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
    private lateinit var runnable: Runnable
    private var locationManager: LocationManager? = null
    private var arg1: String? = null
    private var arg2: String? = null
    private var arg3: Long = 1000L

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
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
            .setContentText("Logging location every 10 seconds")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .build()

        startForeground(1, notification)
    }

    private fun startLocationLoop(arg3: Long) {
        runnable = object : Runnable {
            override fun run() {
                try {
                    if (ActivityCompat.checkSelfPermission(
                            this@LocationService,
                            Manifest.permission.ACCESS_FINE_LOCATION
                        ) == PackageManager.PERMISSION_GRANTED
                    ) {
                        locationManager?.requestSingleUpdate(
                            LocationManager.GPS_PROVIDER,
                            object : LocationListener {
                                override fun onLocationChanged(location: Location) {
                                    Log.d("LocationService",
                                        "Arg1: $arg1, Arg2: $arg2, Arg3: $arg3, " +
                                                "Lat: ${location.latitude}, Lng: ${location.longitude}"
                                    )
                                }
                            },
                            Looper.getMainLooper()
                        )
                    } else {
                        Log.e("LocationService", "Location permission not granted")
                    }
                } catch (e: Exception) {
                    Log.e("LocationService", "Error: ${e.message}")
                }
                handler.postDelayed(this, arg3)
            }
        }
        handler.post(runnable)
    }

    override fun onDestroy() {
        handler.removeCallbacks(runnable)
        super.onDestroy()
    }
}
