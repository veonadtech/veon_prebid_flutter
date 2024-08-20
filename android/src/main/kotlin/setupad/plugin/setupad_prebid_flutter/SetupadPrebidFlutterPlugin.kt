package setupad.plugin.setupad_prebid_flutter

import android.app.Activity
import android.util.Log
import com.google.android.gms.ads.MobileAds

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import org.prebid.mobile.Host
import org.prebid.mobile.PrebidMobile
import org.prebid.mobile.api.data.InitializationStatus
import java.util.concurrent.CompletableFuture
import io.flutter.plugin.common.MethodChannel

/**
 * Plugin's main class that is called once and allows to interact with Android via Dart code
 * */
class SetupadPrebidFlutterPlugin : FlutterPlugin, ActivityAware {
    private lateinit var activity: Activity
    private val Tag = "PrebidPluginLog"
    private val activityFuture = CompletableFuture<Activity>()


    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        //Getting Prebid account ID through method channel and initializing Prebid Mobile SDK
        try {
            MethodChannel(
                binding.binaryMessenger,
                "setupad.plugin.setupad_prebid_flutter/myChannel_0"
            ).setMethodCallHandler { call, result ->
                if (call.method == "startPrebid") {
                    val arguments = call.arguments as? Map<*, *>
                    val prebidAccountID = arguments?.get("accountID") as? String ?: ""
                    val timeoutMillis = arguments?.get("timeoutMillis") as? Int ?: 0
                    val pbsDebug = arguments?.get("pbsDebug") as? Boolean ?: false
                    initializePrebidMobile(prebidAccountID, timeoutMillis, pbsDebug)
                } else {
                    result.notImplemented()
                }
            }
            binding.platformViewRegistry.registerViewFactory(
                "setupad.plugin.setupad_prebid_flutter",
                PrebidViewFactory(binding.binaryMessenger, this)
            )
        } catch (e: Exception) {
            Log.e(Tag, "Can't initialize Prebid Mobile SDK: ${e.message}")
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        //For interstitial ad to show, it needs activity, so here I get application activity which
        //is passed to PrebidView class in PrebidViewFactory
        activity = binding.activity
        activityFuture.complete(activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityFuture.complete(null)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityFuture.complete(activity)
    }

    override fun onDetachedFromActivity() {
        activityFuture.complete(null)
    }

    /**
     * A method for passing application's activity
     */
    fun returnActivity(): Activity {
        return activity
    }

    /**
     * Prebid Mobile SDK initialization method
     */
    private fun initializePrebidMobile(prebidAccountID: String, timeout: Int, pbs: Boolean) {
        activityFuture.thenAccept { activity ->
            PrebidMobile.setPrebidServerAccountId(prebidAccountID)
            PrebidMobile.setPrebidServerHost(
                Host.createCustomHost(
                    "https://prebid.veonadx.com/openrtb2/auction"
                )
            )

            PrebidMobile.initializeSdk(activity) { status ->
                when (status) {
                    InitializationStatus.SUCCEEDED -> {
                        Log.d(Tag, "Prebid Mobile SDK initialized successfully!")
                    }
                    InitializationStatus.SERVER_STATUS_WARNING -> {
                        Log.e(
                            Tag,
                            "Prebid Server status checking failed: $status\n${status.description}"
                        )
                    }
                    else -> {
                        Log.e(
                            Tag,
                            "Prebid Mobile SDK initialization error: $status\n${status.description}"
                        )
                    }
                }
            }
            PrebidMobile.setPbsDebug(pbs)
            PrebidMobile.checkGoogleMobileAdsCompatibility(MobileAds.getVersion().toString())
            PrebidMobile.setTimeoutMillis(timeout)
            PrebidMobile.setShareGeoLocation(true)
            PrebidMobile.useExternalBrowser = true
        }
    }
}