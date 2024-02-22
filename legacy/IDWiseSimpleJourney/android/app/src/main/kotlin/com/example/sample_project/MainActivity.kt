package com.example.sample_project

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.util.Log
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.lang.reflect.Type

import com.idwise.sdk.IDWiseSDKCallback
import com.idwise.sdk.data.models.IDWiseSDKError
import com.idwise.sdk.data.models.JourneyInfo
import com.idwise.sdk.IDWise
import com.idwise.sdk.data.models.IDWiseSDKTheme

class MainActivity : FlutterActivity() {

    val CHANNEL = "com.idwise.fluttersampleproject/idwise"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val clientKey = call.argument<String>("clientKey")
                    val theme = when (call.argument<String>("theme")) {
                        "LIGHT" -> IDWiseSDKTheme.LIGHT
                        "DARK" -> IDWiseSDKTheme.DARK
                        else -> IDWiseSDKTheme.SYSTEM_DEFAULT
                    }

                    IDWise.initialize(clientKey!!, theme) { error ->
                        Log.d("IDWiseSDKCallback", "onError ${error?.message}")
                        result.error("ERROR", error!!.message, null)
                        methodChannel?.invokeMethod("onError", Gson().toJson(error))
                    }
                }

                "startJourney" -> {
                    val journeyDefinitionId = call.argument<String>("journeyDefinitionId")
                    val referenceNo = call.argument<String>("referenceNo")
                    val locale = call.argument<String>("locale")

                    IDWise.startJourney(
                        this,
                        journeyDefinitionId!!,
                        referenceNo,
                        locale,
                        callback = object : IDWiseSDKCallback {
                            override fun onJourneyStarted(journeyInfo: JourneyInfo) {
                                Log.d("IDWiseSDKCallback", "onJourneyStarted")
                                methodChannel?.invokeMethod(
                                    "onJourneyStarted",
                                    journeyInfo.journeyId
                                )
                            }

                            override fun onJourneyCompleted(
                                journeyInfo: JourneyInfo,
                                isSucceeded: Boolean
                            ) {
                                Log.d("IDWiseSDKCallback", "onJourneyFinished")
                                methodChannel?.invokeMethod("onJourneyFinished", null)
                            }

                            override fun onJourneyCancelled(journeyInfo: JourneyInfo?) {
                                Log.d("IDWiseSDKCallback", "onJourneyCancelled")
                                methodChannel?.invokeMethod("onJourneyCancelled", null)
                            }

                            override fun onJourneyResumed(journeyInfo: JourneyInfo) {
                                Log.d("IDWiseSDKCallback", "onJourneyResumed")
                                methodChannel?.invokeMethod(
                                    "onJourneyResumed",
                                    journeyInfo.journeyId
                                )
                            }

                            override fun onError(error: IDWiseSDKError) {
                                Log.d(
                                    "IDWiseSDKCallback",
                                    "onError ${error.message}"
                                )
                                methodChannel?.invokeMethod("onError", Gson().toJson(error))
                            }
                        }
                    )
                }

                "getJourneySummary" -> {
                    
                    IDWise.getJourneySummary(callback = { summary, error ->

                        val gson = Gson()
                        val type: Type = object : TypeToken<HashMap<String, Any>>() {}.type
                        val argsMap = hashMapOf<String, Any?>()

                        summary?.let {
                            argsMap["summary"] = gson.fromJson(gson.toJson(summary), type)
                        }
                        error?.let {
                            argsMap["error"] = gson.fromJson(gson.toJson(error), type)
                        }

                        methodChannel?.invokeMethod("journeySummary", argsMap)
                    })
                
                }

                else -> result.error("NO_SUCH_METHOD", "NO SUCH METHOD", null)
            }
            // Note: this method is invoked on the main thread.
            // TODO
        }
    }
}
