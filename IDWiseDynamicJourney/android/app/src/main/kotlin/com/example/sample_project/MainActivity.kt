package com.example.sample_project

import android.graphics.Bitmap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.util.Log
import com.google.gson.Gson

import com.idwise.sdk.IDWiseSDKCallback
import com.idwise.sdk.data.models.IDWiseSDKError
import com.idwise.sdk.data.models.JourneyInfo
import com.idwise.sdk.IDWise
import com.idwise.sdk.IDWiseSDKStepCallback
import com.idwise.sdk.data.models.IDWiseSDKTheme
import com.idwise.sdk.data.models.StepResult
import org.json.JSONObject

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

                "startStep" -> {
                    val stepId = call.argument<String>("stepId")
                    stepId?.let { IDWise.startStep(this, it); }
                }

                "startDynamicJourney" -> {
                    val journeyDefinitionId = call.argument<String>("journeyDefinitionId")
                    val referenceNo = call.argument<String>("referenceNo")
                    val locale = call.argument<String>("locale")

                    IDWise.startDynamicJourney(
                        this,
                        journeyDefinitionId!!,
                        referenceNo,
                        locale,
                        journeyCallback = object : IDWiseSDKCallback {
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
                        },
                        stepCallback = object : IDWiseSDKStepCallback {
                            override fun onStepCaptured(
                                stepId: String,
                                bitmap: Bitmap?,
                                croppedBitmap: Bitmap?
                            ) {
                                Log.d("IDWiseStepSDKCallback", "onStepCaptured")
                                methodChannel?.invokeMethod("onStepCaptured", stepId)
                            }

                            override fun onStepConfirmed(stepId: String) {
                                Log.d("IDWiseStepSDKCallback", "onStepConfirmed")
                                methodChannel?.invokeMethod("onStepConfirmed", stepId)
                            }

                            override fun onStepResult(stepId: String, stepResult: StepResult?) {
                                Log.d(
                                    "IDWiseStepSDKCallback",
                                    "onStepResult ${stepResult?.errorUserFeedbackDetails}"
                                )

                                val json = JSONObject()
                                json.put("stepId", stepId)
                                json.put("stepResult", Gson().toJson(stepResult))

                                methodChannel?.invokeMethod("onStepResult", Gson().toJson(json))
                            }

                        }
                    )

                }

                else -> result.error("NO_SUCH_METHOD", "NO SUCH METHOD", null)
            }
            // Note: this method is invoked on the main thread.
            // TODO
        }
    }
}
