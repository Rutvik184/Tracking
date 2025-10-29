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

    private lateinit var workHandler: Handler
    private lateinit var handlerThread: HandlerThread
    private var stopHandler: Handler? = null
    private var stopRunnable: Runnable? = null
    private var locationManager: LocationManager? = null
    private var locationListener: LocationListener? = null

    private var arg1: String? = null
    private var arg2: String? = null
    private var interval: Long = 1000L
    private var stopAfterMs: Long = 0L
    private var isRunning = false

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
        handlerThread = HandlerThread("LocationThread", Process.THREAD_PRIORITY_BACKGROUND)
        handlerThread.start()
        workHandler = Handler(handlerThread.looper)
        stopHandler = Handler(Looper.getMainLooper())
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (isRunning) {
            Log.d("LocationService", "Already running, ignoring duplicate start")
            return START_NOT_STICKY
        }

        isRunning = true
        arg1 = intent?.getStringExtra("arg1")
        arg2 = intent?.getStringExtra("arg2")
        interval = intent?.getLongExtra("arg3", 1000L) ?: 1000L
        stopAfterMs = intent?.getLongExtra("arg4", 0L) ?: 0L

        startForegroundService()
        startLocationLoop(interval)

        if (stopAfterMs > 0) scheduleStop(stopAfterMs)

        return START_NOT_STICKY
    }

    private fun startForegroundService() {
        val channelId = "LocationChannel"
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Location Tracking", NotificationManager.IMPORTANCE_LOW)
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Tracking Location")
            .setContentText("Interval: ${interval / 1000}s")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .build()

        startForeground(1, notification)
    }

    private fun startLocationLoop(interval: Long) {
        locationListener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                Log.d("LocationService", "📍 Lat: ${location.latitude}, Lng: ${location.longitude}, Arg1=$arg1, Arg2=$arg2")
            }
        }

        val fetchLocation = object : Runnable {
            override fun run() {
                if (ActivityCompat.checkSelfPermission(this@LocationService, Manifest.permission.ACCESS_FINE_LOCATION)
                    == PackageManager.PERMISSION_GRANTED
                ) {
                    locationManager?.requestSingleUpdate(LocationManager.GPS_PROVIDER, locationListener!!, handlerThread.looper)
                }
                workHandler.postDelayed(this, interval)
            }
        }

        workHandler.post(fetchLocation)
    }

    private fun scheduleStop(duration: Long) {
        stopRunnable?.let { stopHandler?.removeCallbacks(it) }

        if (duration <= 0L) {
            Log.d("LocationService", "No auto-stop scheduled (duration=$duration)")
            return
        }

        stopRunnable = Runnable {
            Log.d("LocationService", "⏱ Auto-stopping after $duration ms")
            stopLogging()
        }

        stopHandler?.postDelayed(stopRunnable!!, duration)
        Log.d("LocationService", "Auto-stop scheduled in ${duration / 1000} sec")
    }

    private fun stopLogging() {
        if (!isRunning) return

        isRunning = false
        Log.d("LocationService", "🛑 Stopping location updates")

        workHandler.removeCallbacksAndMessages(null)
        stopHandler?.removeCallbacks(stopRunnable!!)
        locationListener?.let {
            try {
                locationManager?.removeUpdates(it)
            } catch (e: Exception) {
                Log.e("LocationService", "removeUpdates failed: ${e.message}")
            }
        }

        stopForeground(true)
        stopSelf()
    }

    override fun onDestroy() {
        Log.d("LocationService", "Service destroyed")
        stopLogging()
        handlerThread.quitSafely()
        instance = null
        super.onDestroy()
    }
}
