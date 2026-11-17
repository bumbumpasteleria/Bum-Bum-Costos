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
    @PluginMethod public void openExternal(PluginCall call) {
        String raw=call.getString("url","");android.net.Uri u=android.net.Uri.parse(raw);
        boolean download="github.com".equals(u.getHost())&&u.getPath()!=null&&u.getPath().matches("/bumbumpasteleria/Bum-Bum-Costos/releases/download/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+\\.apk")&&u.getQuery()==null&&u.getFragment()==null;
        boolean google="exanisbqasrzoerdghmz.supabase.co".equals(u.getHost())&&"/auth/v1/authorize".equals(u.getPath())&&"google".equals(u.getQueryParameter("provider"));
        if(!"https".equals(u.getScheme())||u.getUserInfo()!=null||u.getPort()!=-1||(!download&&!google)){call.reject("Enlace no permitido");return;}
        try{getActivity().startActivity(new Intent(Intent.ACTION_VIEW,u));call.resolve();}catch(Exception e){call.reject("No se pudo abrir el enlace");}
    }
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
        String target=open?intent.getStringExtra("bumTarget"):null;if(open){intent.removeExtra("bumOpenAgenda");intent.removeExtra("bumTarget");}JSObject result=new JSObject();result.put("open",open);result.put("target",target==null?"Agenda y cobros":target);call.resolve(result);
    }
}
