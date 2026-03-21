package com.example.hanti_riyo

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.hanti_riyo/maps")
            .setMethodCallHandler { call, result ->
                if (call.method == "getGoogleMapsApiKey") {
                    try {
                        val appInfo = applicationContext.packageManager.getApplicationInfo(
                            applicationContext.packageName,
                            PackageManager.GET_META_DATA,
                        )
                        val key = appInfo.metaData?.getString("com.google.android.geo.API_KEY") ?: ""
                        result.success(key)
                    } catch (e: Exception) {
                        result.success("")
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
