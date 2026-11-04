package setupad.plugin.setupad_prebid_flutter_example

import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.preference.PreferenceManager
import io.flutter.embedding.android.FlutterActivity
import java.io.File

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        if ((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            seedPrebidScriptsForDebug()
        }
        super.onCreate(savedInstanceState)
    }

    private fun seedPrebidScriptsForDebug() {
        val preferences = PreferenceManager.getDefaultSharedPreferences(this)
        for (name in listOf("omsdk.js", "mraid.js")) {
            val path = "PBMJSLibraries/$name"
            val target = File(filesDir, path)
            target.parentFile?.mkdirs()
            assets.open(path).use { source ->
                target.outputStream().use { output -> source.copyTo(output) }
            }
            preferences.edit().putBoolean(path, true).apply()
        }
    }
}
