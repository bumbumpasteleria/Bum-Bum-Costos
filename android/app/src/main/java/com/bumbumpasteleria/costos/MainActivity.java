package com.bumbumpasteleria.costos;
import android.os.Bundle;
import com.getcapacitor.BridgeActivity;
public class MainActivity extends BridgeActivity { @Override public void onCreate(Bundle state){registerPlugin(BumDevicePlugin.class);super.onCreate(state);} }
