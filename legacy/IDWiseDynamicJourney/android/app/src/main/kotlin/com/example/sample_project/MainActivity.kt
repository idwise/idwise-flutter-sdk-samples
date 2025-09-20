package com.example.sample_project

import android.graphics.Bitmap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.util.Log
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

import com.idwise.sdk.IDWiseJourneyCallbacks
import com.idwise.sdk.IDWiseDynamic
import com.idwise.sdk.IDWiseStepCallbacks
import com.idwise.sdk.data.models.*
import org.json.JSONObject
import java.lang.reflect.Type
import android.util.Base64
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    val CHANNEL = "com.idwise.fluttersampleproject/idwise"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    IDWiseDynamic.unloadSDK()

                    val clientKey = call.argument<String>("clientKey")
                    val theme = when (call.argument<String>("theme")) {
                        "LIGHT" -> IDWiseTheme.LIGHT
                        "DARK" -> IDWiseTheme.DARK
                        else -> IDWiseTheme.SYSTEM_DEFAULT
                    }

                    IDWiseDynamic.initialize(clientKey!!, theme) { error ->
                        Log.d("IDWiseSDKCallback", "onError ${error?.message}")
                        result.error("ERROR", error!!.message, null)
                        methodChannel?.invokeMethod("onError", Gson().toJson(error))
                    }
                }

                "startStep" -> {
                    val stepId = call.argument<String>("stepId")
                    stepId?.let { IDWiseDynamic.startStep(this, it); }
                }

                "skipStep" -> {
                    val stepId = call.argument<String>("stepId")
                    stepId?.let { IDWiseDynamic.skipStep(it); }
                }

                "startJourney" -> {
                    Log.d("startDynamicJourney", "startDynamicJourney")
                    val journeyDefinitionId = call.argument<String>("flowId")
                    Log.d("startDynamicJourney", "journeyDefinitionId: $journeyDefinitionId")
                    val referenceNo = call.argument<String>("referenceNo")
                    Log.d("startDynamicJourney", "referenceNo: $referenceNo")
                    val locale = call.argument<String>("locale")
                    Log.d("startDynamicJourney", "locale: $locale")

                    IDWiseDynamic.startJourney(
                        context=this,
                        flowId=journeyDefinitionId!!,
                        referenceNo=referenceNo,
                        locale=locale,
                        journeyCallbacks = journeyCallback,
                        stepCallbacks = stepCallback
                    )
                }

                "resumeJourney" -> {
                    Log.d("resumeDynamicJourney", "resumeDynamicJourney")
                    val journeyDefinitionId = call.argument<String>("journeyDefinitionId")
                    Log.d("resumeDynamicJourney", "journeyDefinitionId: $journeyDefinitionId")
                    val journeyId = call.argument<String>("journeyId")
                    Log.d("resumeDynamicJourney", "journeyId: $journeyId")
                    val locale = call.argument<String>("locale")
                    Log.d("resumeDynamicJourney", "locale: $locale")

                    IDWiseDynamic.resumeJourney(
                        context=this,
                        flowId=journeyDefinitionId!!,
                        journeyId=journeyId!!,
                        locale=locale,
                        journeyCallbacks = journeyCallback,
                        stepCallbacks = stepCallback
                    )
                }

                "finishJourney" -> {
                    IDWiseDynamic.finishJourney()
                }

                "getJourneySummary" -> {
                    IDWiseDynamic.getJourneySummary(callback = { summary, error ->

                        val gson = Gson()
                        val summaryResponse = JourneySummaryExposed(summary,error)
                        
                        Log.d("getJourneySummary.kt","response getJourneySummary $summaryResponse ")
                        methodChannel?.invokeMethod("journeySummary", gson.toJson(summaryResponse))
                    })
                }

                "unloadSDK" -> {
                    IDWiseDynamic.unloadSDK()
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
            Log.d("IDWiseSDKCallback", "onJourneyFinished")
            methodChannel?.invokeMethod("onJourneyFinished", 
                Gson().toJson(journeyInfo))
        }

        override fun onJourneyCancelled(journeyInfo: JourneyCancelledInfo) {
            Log.d("IDWiseSDKCallback", "onJourneyCancelled")
            methodChannel?.invokeMethod("onJourneyCancelled", 
                Gson().toJson(journeyInfo))
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
            methodChannel?.invokeMethod("onError", Gson().toJson(error))
        }
    }

    private val stepCallback = object : IDWiseStepCallbacks {
        override fun onStepCaptured(stepCapturedInfo: StepCapturedInfo) {
            Log.d("IDWiseStepSDKCallback", "onStepCaptured")
           
            val originalImage = convertImageToBase64String(stepCapturedInfo.originalImage)
            val croppedImage = convertImageToBase64String(stepCapturedInfo.croppedImage)
            val response = OnStepCapturedInfoExposed(stepCapturedInfo.stepId.toString(),originalImage,croppedImage)
            
            methodChannel?.invokeMethod("onStepCaptured", Gson().toJson(response))
        }

        override fun onStepSkipped(stepInfo: StepSkippedInfo) {
            Log.d("IDWiseStepSDKCallback", "onStepSkipped")
            methodChannel?.invokeMethod("onStepSkipped", Gson().toJson(stepInfo))
        }

        override fun onStepCancelled(stepInfo: StepCancelledInfo) {
            Log.d("IDWiseStepSDKCallback", "onStepCancelled")
            methodChannel?.invokeMethod("onStepCancelled", Gson().toJson(stepInfo))
        }

        override fun onStepResult(stepInfo: StepResultInfo) {
            methodChannel?.invokeMethod("onStepResult" ,Gson().toJson(stepInfo))
        }
    }

    fun convertImageToBase64String(bitmap: Bitmap?): String {
        if (bitmap == null || bitmap.isRecycled) return ""

        val baos = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, baos)
        val b = baos.toByteArray()
        return Base64.encodeToString(b, Base64.NO_WRAP)
    }

    internal data class OnStepCapturedInfoExposed(
        val stepId:String,
        val originalImage:String?,
        val croppedImage:String
    )


    internal data class JourneySummaryExposed(
        val summary:JourneySummary?,
        val error:IDWiseError?
    )
}
