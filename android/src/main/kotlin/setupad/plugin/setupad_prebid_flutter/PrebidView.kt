package setupad.plugin.setupad_prebid_flutter

import android.app.Activity
import android.content.Context
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import com.google.android.gms.ads.AdListener
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.admanager.AdManagerAdView
import com.google.android.gms.ads.admanager.AdManagerInterstitialAd
import com.google.android.gms.ads.admanager.AdManagerInterstitialAdLoadCallback
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.platform.PlatformView
import org.prebid.mobile.addendum.AdViewUtils
import org.prebid.mobile.addendum.PbFindSizeError
import org.prebid.mobile.AdSize
import org.prebid.mobile.api.data.SdkType
import org.prebid.mobile.api.exceptions.AdException
import org.prebid.mobile.api.multiadloader.MultiBannerLoader
import org.prebid.mobile.api.multiadloader.MultiInterstitialAdLoader
import org.prebid.mobile.api.multiadloader.listeners.MultiBannerViewListener
import org.prebid.mobile.api.multiadloader.listeners.MultiInterstitialAdListener
import org.prebid.mobile.api.rendering.BannerView
import org.prebid.mobile.api.rendering.RewardedAdUnit
import org.prebid.mobile.api.rendering.listeners.RewardedAdUnitListener
import org.prebid.mobile.eventhandlers.GamRewardedEventHandler
import org.prebid.mobile.rendering.interstitial.rewarded.Reward

/**
 * A class that is responsible for creating and adding banner and interstitial ads to the Flutter app's view, as well as pausing and resuming auction
 */
class PrebidView internal constructor(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    activity: Activity
) :
    PlatformView, MethodCallHandler {
    private var applicationContext: Context = context
    private var appActivity: Activity = activity
    private val channel = MethodChannel(messenger, "setupad.plugin.setupad_prebid_flutter/myChannel_$id")
    private var bannerLayout: ViewGroup?

    // NEW: keep a reference to MultiInterstitialAdLoader so we can control it later
    private var interstitialLoader: MultiInterstitialAdLoader? = null
    // Keep last used IDs so "loadInterstitial" works even if called later
    private var lastInterstitialConfigId: String? = null
    private var lastInterstitialAdUnitId: String? = null

    // NEW: keep a reference to BannerView so we can control it later
    private var bannerView: BannerView? = null
    private var bannerLoader: MultiBannerLoader? = null
    private var adView: View? = null

    // Keep last used IDs and size so "loadBanner" works even if called later
    private var lastBannerConfigId: String? = null
    private var lastBannerAdUnitId: String? = null
    private var lastBannerWidth: Int? = null
    private var lastBannerHeight: Int? = null
    private var lastRefreshInterval: Int? = null

    private val Tag = "PrebidPluginLog"

    /**
     * Setting channel method, configuring banner layout
     */
    init {
        try {
            channel.setMethodCallHandler(this)
        } catch (e: Exception) {
            Log.e(Tag, "Error setting method call handler: $e")
        }
        bannerLayout = FrameLayout(applicationContext)
        val params = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        )
        params.gravity = Gravity.BOTTOM
    }

    /**
     * Adding a view to the UI where banner will be added
     */
    override fun getView(): View? {
        return bannerLayout
    }

    /**
     * Disposing view and destroying Prebid auction
     */
    override fun dispose() {
        bannerLayout = null
        channel.setMethodCallHandler(null)
        onDestroy()
    }

    /**
     * Checking which method was called and then calling the needed method
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setParams" -> {
                settingParameters(call)
                result.success(null)
            }
            "pauseAuction" -> {
                onPause()
                result.success(null)
            }
            "resumeAuction" -> {
                onResume()
                result.success(null)
            }
            "destroyAuction" -> {
                onDestroy()
                result.success(null)
            }

            // NEW: explicit interstitial control from Flutter
            "loadInterstitial" -> {
                // Recreate loader if needed and load
                val cfg = lastInterstitialConfigId
                val adu = lastInterstitialAdUnitId
                if (cfg.isNullOrEmpty() || adu.isNullOrEmpty()) {
                    Log.w(Tag, "loadInterstitial called but config/adUnit not set yet (call setParams first).")
                } else {
                    ensureInterstitialLoader(adu, cfg)
                    interstitialLoader?.loadAd()
                }
                result.success(null)
            }
            "showInterstitial" -> {
                interstitialLoader?.showAd()
                result.success(null)
            }
            "hideInterstitial" -> {
                // There is no "hide" for a shown interstitial; destroy to ensure it won't show again.
                destroyInterstitialLoader()
                result.success(null)
            }
            // NEW: explicit banner control from Flutter
            "loadBanner" -> {
                val adUnitId = lastBannerAdUnitId
                val configId = lastBannerConfigId
                val width = lastBannerWidth
                val height = lastBannerHeight
                val refreshInterval = lastRefreshInterval

                // Recreate loader if needed and load
                if (configId.isNullOrEmpty() || adUnitId.isNullOrEmpty()
                    || width == null || height == null
                ) {
                    Log.w(Tag, "loadBanner called but config/adUnit/width/height not set yet (call setParams first).")
                } else {
                    ensureBannerLoader(
                        adUnitId,
                        configId,
                        width,
                        height,
                        refreshInterval
                    )
                    bannerLoader?.loadAd()
                }
                result.success(null)
            }
            "showBanner" -> {
                if (adView != null) {
                    bannerLayout?.addView(adView)
                } else {
                    Log.w(Tag, "showBanner: adView is null")
                }
                result.success(null)
            }
            "hideBanner" -> {
                // There is no "hide" for a shown banner; destroy to ensure it won't show again.
                destroyBannerView()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Getting the parameters user wrote and then validating them
     */
    private fun settingParameters(call: MethodCall) {
        Log.d(Tag, "Setting ad parameters")
        val arguments = call.arguments as? Map<*, *>
        val adType = arguments?.get("adType") as? String ?: ""
        val adUnitId = arguments?.get("adUnitId") as? String ?: ""
        val configId = arguments?.get("configId") as? String ?: ""
        val width = arguments?.get("width") as? Int ?: 0
        val height = arguments?.get("height") as? Int ?: 0
        val refreshInterval = arguments?.get("refreshInterval") as? Int ?: 0

        bannerLayout?.removeAllViews()

        when {
            adType == "" -> {
                Log.e(Tag, applicationContext.getString(R.string.emptyAdType))
            }

            adType.lowercase() != "banner" && adType.lowercase() != "interstitial" && adType.lowercase() != "rewardvideo" -> {
                Log.e(Tag, applicationContext.getString(R.string.errorsInAdTypeName))
            }

            else -> {
                when {
                    adUnitId == "" && configId != "" -> { //adUnitID tuscias
                        Log.e(Tag, applicationContext.getString(R.string.emptyAdUnitID))
                    }

                    adUnitId != "" && configId == "" -> { //configID tuscias
                        Log.e(Tag, applicationContext.getString(R.string.emptyConfigID))
                    }

                    adUnitId == "" && configId == "" -> { //ad unit ir config ID tusti
                        Log.e(Tag, applicationContext.getString(R.string.emptyAdUnitConfigID))
                    }

                    refreshInterval < 30 && adType.lowercase() == "banner" -> {
                        Log.e(Tag, applicationContext.getString(R.string.tooSmallRefreshInterval))
                    }

                    refreshInterval > 120 && adType.lowercase() == "banner" -> {
                        Log.e(Tag, applicationContext.getString(R.string.tooBigRefreshInterval))
                    }

                    else -> {
                        Log.d(Tag, "Parameters set successfully!")
                        when (adType.lowercase()) {
                            "banner" -> createBanner(adUnitId, configId, width, height, refreshInterval)
                            "interstitial" -> {
                                createInterstitial(adUnitId, configId)
                                bannerLayout?.visibility = View.GONE
                            }

                            "rewardvideo" -> createRewardVideo(adUnitId, configId)

                            else -> {}
                        }
                    }
                }
            }
        }
    }

    /**
     * Setting banner parameters and fetching demand
     */
    private fun createBanner(
        AD_UNIT_ID: String,
        CONFIG_ID: String,
        width: Int,
        height: Int,
        refreshInterval: Int
    ) {

        Log.d(Tag, "Prebid banner: $CONFIG_ID/$AD_UNIT_ID")

        // Remember IDs and size for future explicit loads
        lastBannerAdUnitId = AD_UNIT_ID
        lastBannerConfigId = CONFIG_ID
        lastBannerWidth = width
        lastBannerHeight = height
        lastRefreshInterval = refreshInterval

        ensureBannerLoader(
            AD_UNIT_ID,
            CONFIG_ID,
            width,
            height,
            refreshInterval
        )
    }

    /**
     * Setting interstitial ad parameters and fetching demand
     * NOTE: No auto-show. Use channel "showInterstitial" to display later.
     */
    private fun createInterstitial(AD_UNIT_ID: String, CONFIG_ID: String) {
        Log.d(Tag, "Prebid interstitial: $CONFIG_ID/$AD_UNIT_ID")

        // Remember IDs for future explicit loads
        lastInterstitialAdUnitId = AD_UNIT_ID
        lastInterstitialConfigId = CONFIG_ID

        ensureInterstitialLoader(AD_UNIT_ID, CONFIG_ID)

        interstitialLoader?.setListener(object : MultiInterstitialAdListener {
            override fun onAdLoaded(sdk: SdkType) {
                val id = getAdId(sdk, CONFIG_ID, AD_UNIT_ID)
                channel.invokeMethod("onAdLoaded", id)
                Log.d(Tag, "onAdLoaded: Ad loaded from ${sdk.name} (not auto-showing)")
                // Do NOT call show here; Flutter must call "showInterstitial"
            }

            override fun onAdDisplayed(sdk: SdkType) {
                val id = getAdId(sdk, CONFIG_ID, AD_UNIT_ID)
                channel.invokeMethod("onAdDisplayed", id)
                Log.d(Tag, "onAdDisplayed: Ad displayed from ${sdk.name}")
            }

            override fun onAdFailed(error: String?, sdk: SdkType?) {
                val errorMsg = error ?: "Unknown error"
                channel.invokeMethod("onAdFailed", errorMsg)
                val sdkName = sdk?.name ?: "unknown SDK"
                Log.d(Tag, "onAdFailed: $errorMsg (SDK: $sdkName)")
            }

            override fun onAdFailedToShow(error: String?, sdk: SdkType?) {
                channel.invokeMethod("onAdFailed", error)
                val sdkName = sdk?.name ?: "unknown SDK"
                Log.d(Tag, "onAdFailedToShow: $error (SDK: $sdkName)")
            }

            override fun onAdClicked(sdk: SdkType) {
                val id = getAdId(sdk, CONFIG_ID, AD_UNIT_ID)
                channel.invokeMethod("onAdClicked", id)
                Log.d(Tag, "onAdClicked: Ad clicked from ${sdk.name}")
            }

            override fun onAdClosed(sdk: SdkType) {
                val id = getAdId(sdk, CONFIG_ID, AD_UNIT_ID)
                channel.invokeMethod("onAdClosed", id)
                Log.d(Tag, "onAdClosed: Ad closed from ${sdk.name}")
                // Optional: after close, you may want to auto-load next
                // interstitialLoader?.loadAd()
            }
        })

        // Kick off the first load now (won't auto-show)
        interstitialLoader?.loadAd()
    }

    // Ensure we have a loader instance bound to these IDs; recreate if IDs changed
    private fun ensureInterstitialLoader(adUnitId: String, configId: String) {
        val current = interstitialLoader
        if (current == null || lastInterstitialAdUnitId != adUnitId || lastInterstitialConfigId != configId) {
            try {
                current?.destroy()
            } catch (e: Exception) {
                Log.w(Tag, "Error destroying old interstitial loader: $e")
            }
            interstitialLoader = MultiInterstitialAdLoader(
                context = appActivity,
                configId = configId,
                gamAdUnitId = adUnitId
            )
        }
    }

    // Ensure we have a loader instance bound to these IDs; recreate if IDs changed
    private fun ensureBannerLoader(
        adUnitId: String,
        configId: String,
        width: Int,
        height: Int,
        refreshInterval: Int?
    ) {
        val refresh = refreshInterval ?: 30
        val current = bannerLoader
        if (current == null || lastBannerAdUnitId != adUnitId || lastBannerConfigId != configId) {
            try {
                current?.destroy()
                bannerLoader = MultiBannerLoader(
                    context = applicationContext,
                    adSize = AdSize(width, height),
                    configId = configId,
                    gamAdUnitId = adUnitId,
                    autoRefreshDelay = refresh
                )

                bannerLoader?.setListener(object : MultiBannerViewListener {
                    override fun onAdLoaded(view: View, sdk: SdkType) {
                        adView = view
                        val id = getAdId(sdk, configId, adUnitId)
                        channel.invokeMethod("onAdLoaded", id);
                        Log.d(Tag, "onAdLoaded: Ad loaded from ${sdk.name} (not auto-showing)")
                    }

                    override fun onAdFailed(bannerView: BannerView?, error: String?, sdk: SdkType?) {
                        val errorMsg = error ?: "Unknown error"
                        val sdkName = sdk?.name ?: "unknown SDK"
                        channel.invokeMethod("onAdFailed", errorMsg)
                        Log.d(Tag, "onAdFailed: $errorMsg (SDK: $sdkName)")
                    }

                    override fun onAdClicked(bannerView: BannerView?, sdk: SdkType) {
                        val id = getAdId(sdk, configId, adUnitId)
                        channel.invokeMethod("onAdClicked", id)
                        Log.d(Tag, "onAdClicked: Ad clicked from ${sdk.name}")
                    }

                    override fun onAdClosed(bannerView: BannerView?, sdk: SdkType) {
                        val id = getAdId(sdk, configId, adUnitId)
                        channel.invokeMethod("onAdClosed", id)
                        Log.d(Tag, "onAdClosed: Ad closed from ${sdk.name}")
                    }

                    override fun onAdDisplayed(bannerAdView: BannerView?, sdk: SdkType) {
                        bannerView = bannerAdView
                        val id = getAdId(sdk, configId, adUnitId)
                        channel.invokeMethod("onAdDisplayed", id)
                        Log.d(Tag, "onAdDisplayed: Ad displayed from ${sdk.name}")
                    }

                    override fun onImpression(sdk: SdkType) {
                        Log.d(Tag, "onImpression: Impression tracked from ${sdk.name}")
                    }

                    override fun onAdOpened(sdk: SdkType) {
                        Log.d(Tag, "onAdOpened: Ad opened from ${sdk.name}")
                    }
                })

                bannerLoader?.loadAd()
            } catch (e: Exception) {
                Log.w(Tag, "Error destroying old bannerView: $e")
            }
        }
    }

    private fun getAdId(sdk: SdkType, configId: String, adUnitId: String): String =
        when (sdk) {
            SdkType.PREBID -> configId
            SdkType.GAM -> adUnitId
            else -> "unknown_id"
        }

    private fun createRewardVideo(AD_UNIT_ID: String, CONFIG_ID: String) {
        Log.d(Tag, "Prebid reward video: $CONFIG_ID/$AD_UNIT_ID")
        val eventHandler = GamRewardedEventHandler(appActivity, AD_UNIT_ID)
        RewardedAdUnit(applicationContext, CONFIG_ID, eventHandler).apply {
            setRewardedAdUnitListener(object : RewardedAdUnitListener {
                override fun onAdLoaded(unit: RewardedAdUnit?) {
                    if ((bidResponse.winningBid?.price ?: 0.0) > 0.5) show()
                    Log.d(Tag, "onAdLoaded:")
                    channel.invokeMethod("onAdLoaded", CONFIG_ID);
                }

                override fun onAdDisplayed(p0: RewardedAdUnit?) {
                    channel.invokeMethod("onAdDisplayed", CONFIG_ID)
                    Log.d(Tag, "onAdDisplayed:")
                }

                override fun onAdFailed(p0: RewardedAdUnit?, exception: AdException?) {
                    channel.invokeMethod("onAdFailed", exception?.message);
                    Log.d(Tag, "onAdFailed: $exception")
                }

                override fun onAdClicked(p0: RewardedAdUnit?) {
                    channel.invokeMethod("onAdClicked", CONFIG_ID)
                    Log.d(Tag, "onAdClicked:")
                }

                override fun onAdClosed(p0: RewardedAdUnit?) {
                    channel.invokeMethod("onAdClosed", CONFIG_ID)
                    Log.d(Tag, "onAdClosed:")
                }

                override fun onUserEarnedReward(p0: RewardedAdUnit?, reward:Reward?) {
                    channel.invokeMethod("onUserEarnedReward", CONFIG_ID)
                    Log.d(Tag, "onUserEarnedReward:")
                }

            })
            loadAd()
        }
    }

    /**
     * Banner listener which, if ad is loaded, resizes that banner
     * findPrebidCreativeSize() method is a fix for GAM bug, where the ad is sized incorrectly
     */
    private fun bannerListener(bannerAdView: AdManagerAdView): AdListener {
        return object : AdListener() {
            override fun onAdLoaded() {
                super.onAdLoaded()
                AdViewUtils.findPrebidCreativeSize(
                    bannerAdView,
                    object : AdViewUtils.PbFindSizeListener {
                        override fun success(width: Int, height: Int) {
                            Log.d(
                                Tag,
                                "Success in finding Prebid creative size"
                            )
                            bannerAdView.setAdSizes(com.google.android.gms.ads.AdSize(width, height))
                        }

                        override fun failure(error: PbFindSizeError) {
                            Log.e(Tag, "Failure in finding Prebid creative size: $error")
                        }
                    })
            }

            override fun onAdFailedToLoad(error: LoadAdError) {
                super.onAdFailedToLoad(error)
                Log.e(Tag, "Failure in loading banner ad: $error")
            }
        }
    }

    /**
     * A method for stopping auction and removing reference to the banner, as well as hiding
     * banner from the layout. The same applies to the interstitial as well.
     */
    private fun onDestroy() {
        destroyBannerView()
        destroyInterstitialLoader()
    }

    private fun destroyBannerView() {
        try {
            bannerLayout?.removeAllViews()
            bannerView?.destroy()
            bannerLoader?.destroy()
        } catch (e: Exception) {
            Log.w(Tag, "Error destroying bannerView: $e")
        } finally {
            bannerView = null
            bannerLoader = null
            adView = null
        }
    }

    private fun destroyInterstitialLoader() {
        try {
            interstitialLoader?.destroy()
        } catch (e: Exception) {
            Log.w(Tag, "Error destroying interstitial loader: $e")
        } finally {
            interstitialLoader = null
        }
    }

    /**
     * A method for pausing auction
     */
    private fun onPause() {
        if (bannerView != null) {
            bannerView!!.stopRefresh()
            Log.d(Tag, "Pausing Prebid auction")
        }
    }

    /**
     * A method for resuming auction
     */
    private fun onResume() {
        if (bannerView != null) {
            Log.d(Tag, "Resuming Prebid auction")
            bannerView!!.setAutoRefreshDelay(lastRefreshInterval ?: 30)
        }
    }
}