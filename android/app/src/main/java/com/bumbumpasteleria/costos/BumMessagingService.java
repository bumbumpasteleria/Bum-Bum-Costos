package com.bumbumpasteleria.costos;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.content.Context;
import androidx.core.app.NotificationCompat;
import com.google.firebase.messaging.RemoteMessage;
import com.capacitorjs.plugins.pushnotifications.MessagingService;
import java.util.Map;

public class BumMessagingService extends MessagingService {
    @Override public void onMessageReceived(RemoteMessage message) {
        Map<String,String> data=message.getData();
        String owner=getSharedPreferences("bum-device",0).getString("owner","");
        if(owner.isEmpty()||!owner.equals(data.get("ownerId")))return;
        NotificationManager manager=(NotificationManager)getSystemService(Context.NOTIFICATION_SERVICE);
        if(android.os.Build.VERSION.SDK_INT>=26)manager.createNotificationChannel(new NotificationChannel("bum_pendientes","Pendientes de Bum Bum Costos",NotificationManager.IMPORTANCE_DEFAULT));
        Intent intent=new Intent(this,MainActivity.class).putExtra("bumOpenAgenda",true).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP|Intent.FLAG_ACTIVITY_SINGLE_TOP);
        PendingIntent pending=PendingIntent.getActivity(this,0,intent,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
        String body=data.get("body");if(body==null)body="Revisa tus pendientes en Agenda.";if(body.length()>250)body=body.substring(0,250);
        try{manager.notify(910,new NotificationCompat.Builder(this,"bum_pendientes").setSmallIcon(R.drawable.ic_notification).setColor(0xff8a3450).setContentTitle("Bum Bum Costos").setContentText(body).setStyle(new NotificationCompat.BigTextStyle().bigText(body)).setContentIntent(pending).setAutoCancel(true).setVisibility(NotificationCompat.VISIBILITY_PRIVATE).build());}catch(SecurityException denied){/* The user controls notification permission. */}
    }
}
