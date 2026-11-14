package com.bumbumpasteleria.costos;
import android.os.Bundle;
import android.content.Intent;
import com.getcapacitor.BridgeActivity;
public class MainActivity extends BridgeActivity {
 @Override public void onCreate(Bundle state){registerPlugin(BumDevicePlugin.class);super.onCreate(state);}
 @Override protected void onNewIntent(Intent intent){setIntent(intent);super.onNewIntent(intent);}
}
