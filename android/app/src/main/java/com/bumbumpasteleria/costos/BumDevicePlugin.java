package com.bumbumpasteleria.costos;

import android.content.SharedPreferences;
import android.content.Intent;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.util.UUID;

@CapacitorPlugin(name="BumDevice")
public class BumDevicePlugin extends Plugin {
    @PluginMethod public void identity(PluginCall call) {
        SharedPreferences p=getContext().getSharedPreferences("bum-device",0);
        if(!p.contains("deviceId"))p.edit().putString("deviceId",UUID.randomUUID().toString()).putString("proof",UUID.randomUUID().toString()+UUID.randomUUID().toString()).commit();
        JSObject result=new JSObject();result.put("deviceId",p.getString("deviceId",""));result.put("proof",p.getString("proof",""));call.resolve(result);
    }
    @PluginMethod public void setOwner(PluginCall call) {
        String owner=call.getString("owner","");
        if(!owner.isEmpty()&&!owner.matches("[0-9a-fA-F-]{36}")){call.reject("Cuenta no válida");return;}
        getContext().getSharedPreferences("bum-device",0).edit().putString("owner",owner).commit();
        // Remove notifications belonging to a previous account when sessions change.
        ((android.app.NotificationManager)getContext().getSystemService(android.content.Context.NOTIFICATION_SERVICE)).cancelAll();call.resolve();
    }
    @PluginMethod public void consumeAgenda(PluginCall call) {
        Intent intent=getActivity().getIntent();boolean open=intent!=null&&intent.getBooleanExtra("bumOpenAgenda",false);
        if(open)intent.removeExtra("bumOpenAgenda");JSObject result=new JSObject();result.put("open",open);call.resolve(result);
    }
}
