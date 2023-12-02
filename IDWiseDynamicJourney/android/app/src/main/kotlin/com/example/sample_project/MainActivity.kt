package com.example.sample_project

import android.graphics.Bitmap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.util.Log
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

import org.json.JSONObject
import java.lang.reflect.Type

class MainActivity : FlutterActivity() {

    val CHANNEL = "com.idwise.fluttersampleproject/idwise"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }
}
