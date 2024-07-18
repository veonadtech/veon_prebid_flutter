package setupad.plugin.setupad_prebid_flutter

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 *
 */
class PrebidViewFactory(
    private val messenger: BinaryMessenger,
    private val plugin: SetupadPrebidFlutterPlugin
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, id: Int, o: Any?): PlatformView {
        //Getting the activity needed for showing interstitial ads and passing it to PrebidView class
        val activity = plugin.returnActivity()
        return PrebidView(context, messenger, id, activity)
    }
}
