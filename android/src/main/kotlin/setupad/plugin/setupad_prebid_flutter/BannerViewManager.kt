class BannerViewManager(
    private val context: Context,
    private val activity: Activity,
    private val channel: MethodChannel,
    private val configId: String,
    private val adUnitId: String,
    private val width: Int,
    private val height: Int,
    private val refreshInterval: Int = 30
) {
    private val Tag = "BannerViewManager"
    private var bannerView: BannerView? = null

    fun createBanner(): BannerView {
        val eventHandler = GamBannerEventHandler(context, adUnitId, org.prebid.mobile.AdSize(width, height))
        bannerView = BannerView(context, configId, eventHandler).apply {
            setAutoRefreshDelay(refreshInterval)
        }
        return bannerView!!
    }

    fun loadAd() {
        bannerView?.loadAd()
    }

    fun destroy() {
        bannerView?.destroy()
        bannerView = null
    }

    fun createBannerListener(): BannerViewListener {
        return object : BannerViewListener {
            override fun onAdLoaded(bannerView: BannerView?) {
                channel.invokeMethod("onAdLoaded", configId)
                Log.d(Tag, "onAdLoaded:")

                // Сохраняем баннер в кэш только после успешной загрузки
                if (bannerView != null) {
                    BannerCache.cacheBanner(configId, adUnitId, bannerView, this)
                }
            }

            override fun onAdDisplayed(bannerView: BannerView?) {
                channel.invokeMethod("onAdDisplayed", configId)
                Log.d(Tag, "onAdDisplayed:")
            }

            override fun onAdFailed(bannerView: BannerView?, exception: AdException?) {
                channel.invokeMethod("onAdFailed", exception?.message)
                Log.d(Tag, "onAdFailed: $exception")

                // Не сохраняем в кэш при ошибке
                BannerCache.removeCachedBanner(configId, adUnitId)
            }

            override fun onAdClicked(bannerView: BannerView?) {
                channel.invokeMethod("onAdClicked", configId)
                Log.d(Tag, "onAdClicked:")
            }

            override fun onAdClosed(bannerView: BannerView?) {
                channel.invokeMethod("onAdClosed", configId)
                Log.d(Tag, "onAdClosed:")
            }
        }
    }

    companion object {
        fun create(
            context: Context,
            activity: Activity,
            channel: MethodChannel,
            configId: String,
            adUnitId: String,
            width: Int,
            height: Int,
            refreshInterval: Int = 30
        ): BannerViewManager {
            return BannerViewManager(
                context, activity, channel, configId, adUnitId, width, height, refreshInterval
            )
        }
    }
}