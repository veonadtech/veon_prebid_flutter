object BannerCache {

    private val cachedBanners = mutableMapOf<String, BannerView>()
    private val bannerListeners = mutableMapOf<String, BannerViewListener>()

    fun cacheBanner(configId: String, adUnitId: String, bannerView: BannerView, listener: BannerViewListener) {
        val key = generateKey(configId, adUnitId)
        cachedBanners[key] = bannerView
        bannerListeners[key] = listener
        Log.d("BannerCache", "Banner cached for key: $key")
    }

    fun getCachedBanner(configId: String, adUnitId: String): BannerView? {
        val key = generateKey(configId, adUnitId)
        return cachedBanners[key]
    }

    fun getCachedBannerListener(configId: String, adUnitId: String): BannerViewListener? {
        val key = generateKey(configId, adUnitId)
        return bannerListeners[key]
    }

    fun hasCachedBanner(configId: String, adUnitId: String): Boolean {
        val key = generateKey(configId, adUnitId)
        return cachedBanners.containsKey(key)
    }

    fun removeCachedBanner(configId: String, adUnitId: String) {
        val key = generateKey(configId, adUnitId)
        cachedBanners.remove(key)
        bannerListeners.remove(key)
        Log.d("BannerCache", "Banner removed from cache: $key")
    }

    fun clearAll() {
        cachedBanners.clear()
        bannerListeners.clear()
        Log.d("BannerCache", "All banners cleared from cache")
    }

    private fun generateKey(configId: String, adUnitId: String): String {
        return "$configId|$adUnitId"
    }

}