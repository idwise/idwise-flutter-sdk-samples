package com.example.sample_project

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.util.Log
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.lang.reflect.Type

import com.idwise.sdk.IDWiseJourneyCallbacks
import com.idwise.sdk.data.models.IDWiseError
import com.idwise.sdk.IDWise
import com.idwise.sdk.data.models.*

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
                        "LIGHT" -> IDWiseTheme.LIGHT
                        "DARK" -> IDWiseTheme.DARK
                        else -> IDWiseTheme.SYSTEM_DEFAULT
                    }

                    IDWise.initialize(clientKey!!, theme) { error ->
                        Log.d("IDWiseSDKCallback", "onError ${error?.message}")
                        methodChannel?.invokeMethod("onInitializeError", Gson().toJson(error))
                    }
                }

                "startJourney" -> {
                    val journeyDefinitionId = call.argument<String>("flowId")
                    val referenceNo = call.argument<String>("referenceNo")
                    val locale = call.argument<String>("locale")
                    val applicantDetails = call.argument<HashMap<String,String>>("applicantDetails")
                    
                    IDWise.startJourney(
                        context = activity,
                        flowId = journeyDefinitionId!!,
                        referenceNo=referenceNo,
                        locale = locale,
                        applicantDetails = applicantDetails,
                        journeyCallbacks = journeyCallback
                    )
                }

                else -> result.error("NO_SUCH_METHOD", "NO SUCH METHOD", null)
            }
            // Note: this method is invoked on the main thread.
            // TODO
        }
    }

    private val journeyCallback = object : IDWiseJourneyCallbacks {
        override fun onJourneyStarted(journeyInfo: JourneyStartedInfo) {
            Log.d("IDWiseSDKCallback", "onJourneyStarted")
            
            methodChannel?.invokeMethod(
                "onJourneyStarted",
                Gson().toJson(journeyInfo)
            )
        }

        override fun onJourneyCompleted(
            journeyInfo: JourneyCompletedInfo
        ) {
            Log.d("IDWiseSDKCallback", "onJourneyCompleted")
            
            methodChannel?.invokeMethod("onJourneyCompleted",  Gson().toJson(journeyInfo))
        }

        override fun onJourneyCancelled(journeyInfo: JourneyCancelledInfo) {
            Log.d("IDWiseSDKCallback", "onJourneyCancelled")
            
            methodChannel?.invokeMethod("onJourneyCancelled",  Gson().toJson(journeyInfo))
        }

        override fun onJourneyResumed(journeyInfo: JourneyResumedInfo) {
            Log.d("IDWiseSDKCallback", "onJourneyResumed")
            methodChannel?.invokeMethod(
                "onJourneyResumed",
                 Gson().toJson(journeyInfo)
            )
        }

        override fun onJourneyBlocked(journeyInfo: JourneyBlockedInfo) {
            Log.d("IDWiseSDKCallback", "onJourneyBlocked")
            methodChannel?.invokeMethod(
                "onJourneyBlocked",
                 Gson().toJson(journeyInfo)
            )
        }

        override fun onError(error: IDWiseError) {
            Log.d(
                "IDWiseSDKCallback",
                "onError ${error.message}"
            )
            
            methodChannel?.invokeMethod("onError",  Gson().toJson(error))
        }
    }
}
