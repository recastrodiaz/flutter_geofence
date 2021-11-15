package com.intivoto.flutter_geofence

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofenceStatusCodes
import com.google.android.gms.location.GeofencingEvent

class GeofenceBroadcastReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "GeoBroadcastReceiver"

        var callback: ((GeoRegion) -> Unit)? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Called onreceive")
        val geofencingEvent = GeofencingEvent.fromIntent(intent)
        if (geofencingEvent.hasError()) {
            val errorMessage = GeofenceStatusCodes
                    .getStatusCodeString(geofencingEvent.errorCode)
            Log.e(TAG, "something went wrong: $errorMessage")
            return
        }

        // Get the transition type.
        val geofenceTransition = geofencingEvent.geofenceTransition

        if (geofenceTransition == Geofence.GEOFENCE_TRANSITION_ENTER || geofenceTransition == Geofence.GEOFENCE_TRANSITION_EXIT) {
            val event = if (geofenceTransition == Geofence.GEOFENCE_TRANSITION_ENTER) GeoEvent.entry else GeoEvent.exit
            val triggeringGeofences = geofencingEvent.triggeringGeofences

            for (geofence: Geofence in triggeringGeofences) {
                val region = GeoRegion(id = geofence.requestId,
                        latitude = geofencingEvent.triggeringLocation.latitude,
                        longitude = geofencingEvent.triggeringLocation.longitude,
                        radius = 50.0.toFloat(),
                        events = listOf(event)
                )

                if (event == GeoEvent.entry) {
                    sendNotification("Entering region", body = getNotificationMessageForRegionId(context, region.id, "You are entering ${region.id}"), context = context);
                } else {
                    sendNotification("Exit from region", body = getNotificationMessageForRegionId(context, region.id, "You have exited ${region.id}"), context = context);
                }

                callback?.invoke(region)
                Log.i(TAG, region.toString())
            }
        } else {
            // Log the error.
            Log.e(TAG, "Not an event of interest")
        }
    }

    private fun sendNotification(title: String, body: String, context: Context) {
        try {

            val mBuilder = NotificationCompat.Builder(context.applicationContext, "high_importance_channel")


            val bigText = NotificationCompat.BigTextStyle()
            bigText.bigText(body)
            bigText.setBigContentTitle(title)
            // bigText.setSummaryText(body)


            mBuilder.setSmallIcon(R.drawable.common_full_open_on_phone)
            mBuilder.setContentTitle(title)
            mBuilder.setContentText(body)
            mBuilder.priority = Notification.PRIORITY_MAX
            mBuilder.setStyle(bigText)

            val mNotificationManager: NotificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channelId = "high_importance_channel"
                val channel = NotificationChannel(
                        channelId,
                        "This channel is used for important notifications.",
                        NotificationManager.IMPORTANCE_HIGH)
                mNotificationManager.createNotificationChannel(channel)
                mBuilder.setChannelId(channelId)
            }
            mNotificationManager.notify(0, mBuilder.build())
            Log.i(TAG, "Notification sent")
        } catch (ex: Exception) {
            Log.e(TAG, ex.toString())
        }
    }

    private fun getNotificationMessageForRegionId(context: Context, id: String, defaultMessage: String): String {
        val preferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val message = preferences.getString("flutter.flutter_geofence.notification.message.$id", defaultMessage)!!
        Log.i(TAG, "Reading flutter_geofence.notification.message.$id. :: $message")
        return message
    }
}