package com.dikonda.hinduconnect

import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import com.android.installreferrer.api.ReferrerDetails
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.dikonda.hinduconnect/install_referrer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInstallReferrer") {
                getInstallReferrer(result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getInstallReferrer(result: MethodChannel.Result) {
        try {
            val referrerClient = InstallReferrerClient.newBuilder(this).build()
            val listener = object : InstallReferrerStateListener {
                override fun onInstallReferrerSetupFinished(responseCode: Int) {
                    when (responseCode) {
                        InstallReferrerClient.InstallReferrerResponse.OK -> {
                            try {
                                val response: ReferrerDetails = referrerClient.installReferrer
                                val referrer: String? = response.installReferrer
                                result.success(referrer ?: "")
                                referrerClient.endConnection()
                            } catch (e: Exception) {
                                result.success("")
                                referrerClient.endConnection()
                            }
                        }
                        InstallReferrerClient.InstallReferrerResponse.FEATURE_NOT_SUPPORTED -> {
                            result.success("")
                            referrerClient.endConnection()
                        }
                        InstallReferrerClient.InstallReferrerResponse.SERVICE_UNAVAILABLE -> {
                            result.success("")
                            referrerClient.endConnection()
                        }
                        else -> {
                            result.success("")
                            referrerClient.endConnection()
                        }
                    }
                }

                override fun onInstallReferrerServiceDisconnected() {
                    result.success("")
                }
            }
            referrerClient.startConnection(listener)
        } catch (e: Exception) {
            result.success("")
        }
    }
} 