package com.duggustore.app

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.drawable.Drawable
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.SoundPool
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.util.Base64
import java.io.ByteArrayOutputStream
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var soundPool: SoundPool? = null
    private val soundIds = mutableMapOf<String, Int>()

    // Streams this app muted itself, so only those are ever unmuted — a
    // stream the user had muted stays muted.
    private val mutedStreams = mutableSetOf<Int>()

    // The three-key strip at the bottom is a solid white bar, never a
    // see-through patch; the window-level colour wins over whatever
    // Flutter asks for later.
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applySystemBars()
    }

    // The keys' strip: white, and the glyphs on it dark. A see-through bar
    // makes the system paint white glyphs over whatever is behind it, so
    // the window keeps the strip to itself and the app draws above it.
    private fun applySystemBars() {
        window.navigationBarColor = Color.WHITE
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(true)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Dark glyphs on the white strip.
            window.decorView.systemUiVisibility =
                window.decorView.systemUiVisibility or
                    View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
        }
    }

    // The height of the three-key strip, in pixels.
    private fun navInsetPx(): Int {
        val insets = window.decorView.rootWindowInsets ?: return 0
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            insets.getInsets(android.view.WindowInsets.Type.systemBars()).bottom
        } else {
            @Suppress("DEPRECATION")
            insets.systemWindowInsetBottom
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Flutter re-asserts its own edge-to-edge setup when the first
        // screen paints; this puts the white strip back in charge.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "duggu/system_bars")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "apply" -> {
                        window.decorView.post { applySystemBars() }
                        // The keys' strip height in pixels: the window knows
                        // it exactly, and the app needs it to keep its own
                        // bottom bar clear of the keys.
                        result.success(navInsetPx())
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "duggu/voice_sound")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        play(call.argument<String>("asset") ?: "")
                        result.success(null)
                    }
                    "muteBeep" -> {
                        muteRecognizerBeep()
                        result.success(null)
                    }
                    "unmuteBeep" -> {
                        restoreStreams()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        // Every UPI app installed on the phone (they answer the upi:// scheme):
        // the checkout lists each as its own payment option, with the app's
        // real launcher icon inlined as a PNG so the row shows the actual
        // brand mark, not a generic glyph.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "duggu/upi_apps")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "list" -> {
                        try {
                            val pm = packageManager
                            // No MATCH_ALL here: that flag asks for the
                            // QUERY_ALL_PACKAGES permission, which Android
                            // refuses. The manifest already declares the upi
                            // scheme in <queries>, so a plain query is enough
                            // to see the UPI apps.
                            // Several schemes are asked for, one app each:
                            // GPay and PhonePe answer upi://, Paytm and
                            // BHIM answer their own.
                            val schemes = listOf(
                                "upi://pay",
                                "upi://",
                                "tez://pay",
                                "paytmmp://pay",
                            )
                            val seen = mutableSetOf<String>()
                            val out = mutableListOf<Map<String, String>>()
                            for (scheme in schemes) {
                                val intent = Intent(Intent.ACTION_VIEW)
                                intent.data = Uri.parse(scheme)
                                val infos = pm.queryIntentActivities(intent, 0)
                                for (info in infos) {
                                    val pkg = info.activityInfo.packageName
                                    if (pkg == packageName) continue
                                    if (!seen.add(pkg)) continue
                                    val label = try {
                                        pm.getApplicationLabel(
                                            pm.getApplicationInfo(pkg, 0)
                                        ).toString()
                                    } catch (_: Exception) {
                                        pkg
                                    }
                                    val iconPng = runCatching {
                                        val d = pm.getApplicationIcon(pkg)
                                        val size = 96
                                        val bmp = Bitmap.createBitmap(
                                            size, size, Bitmap.Config.ARGB_8888
                                        )
                                        val canvas = Canvas(bmp)
                                        d.setBounds(0, 0, size, size)
                                        d.draw(canvas)
                                        val bytes = ByteArrayOutputStream()
                                        bmp.compress(
                                            Bitmap.CompressFormat.PNG, 100, bytes
                                        )
                                        bmp.recycle()
                                        Base64.encodeToString(
                                            bytes.toByteArray(), Base64.NO_WRAP
                                        )
                                    }.getOrNull() ?: ""
                                    out.add(
                                        mapOf(
                                            "package" to pkg,
                                            "label" to label,
                                            "icon" to iconPng,
                                        )
                                    )
                                }
                            }
                            android.util.Log.i(
                                "UpiApps", "found ${out.size} upi apps"
                            )
                            result.success(out)
                        } catch (e: Exception) {
                            android.util.Log.e("UpiApps", "list failed", e)
                            result.success(emptyList<Map<String, String>>())
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun pool(): SoundPool = soundPool ?: SoundPool.Builder()
        .setMaxStreams(2)
        .setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
        )
        .build()
        .also { soundPool = it }

    private fun play(asset: String) {
        if (asset.isEmpty()) return
        val pool = pool()
        val loaded = soundIds[asset]
        if (loaded != null) {
            pool.play(loaded, 1f, 1f, 1, 0, 1f)
            return
        }
        @Suppress("DEPRECATION")
        val key = asset // assets.openFd works directly with the asset path in the
        // app_assets directory under the v2 (Framework) embedding.
        val fd = assets.openFd(key)
        pool.setOnLoadCompleteListener { p, id, status ->
            if (status == 0 && soundIds[asset] == id) p.play(id, 1f, 1f, 1, 0, 1f)
        }
        soundIds[asset] = pool.load(fd, 1)
        fd.close()
    }

    // The ringer mode before this app switched the phone to vibrate, or null
    // when it didn't.
    private var savedRingerMode: Int? = null

    // Google's recogniser plays its own beep each time it starts and stops
    // listening, and there is no API to turn it off. Which stream it uses
    // varies by phone, so the usual three are muted for as long as the voice
    // sheet listens.
    //
    // On many phones (ColorOS, MIUI) the system and notification streams are
    // tied to the ringer, and muting them outright would mean silent mode,
    // which Android refuses without Do Not Disturb access — the beep then
    // played anyway. Vibrate mode needs no such access and silences the same
    // streams, so it is the fallback.
    private fun muteRecognizerBeep() {
        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        var needsVibrate = false
        for (stream in listOf(
            AudioManager.STREAM_MUSIC,
            AudioManager.STREAM_SYSTEM,
            AudioManager.STREAM_NOTIFICATION,
        )) {
            if (stream in mutedStreams) continue
            try {
                if (audio.isStreamMute(stream)) continue
                audio.adjustStreamVolume(stream, AudioManager.ADJUST_MUTE, 0)
                if (audio.isStreamMute(stream)) {
                    mutedStreams.add(stream)
                } else if (stream != AudioManager.STREAM_MUSIC) {
                    needsVibrate = true
                }
            } catch (_: SecurityException) {
                if (stream != AudioManager.STREAM_MUSIC) needsVibrate = true
            }
        }
        if (needsVibrate && savedRingerMode == null &&
            audio.ringerMode == AudioManager.RINGER_MODE_NORMAL
        ) {
            try {
                audio.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                savedRingerMode = AudioManager.RINGER_MODE_NORMAL
            } catch (_: SecurityException) {
            }
        }
    }

    private fun restoreStreams() {
        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        for (stream in mutedStreams) {
            try {
                audio.adjustStreamVolume(stream, AudioManager.ADJUST_UNMUTE, 0)
            } catch (_: SecurityException) {
            }
        }
        mutedStreams.clear()
        savedRingerMode?.let { mode ->
            try {
                // Only put it back if nobody changed it in the meantime.
                if (audio.ringerMode == AudioManager.RINGER_MODE_VIBRATE) {
                    audio.ringerMode = mode
                }
            } catch (_: SecurityException) {
            }
        }
        savedRingerMode = null
    }

    // Whatever happens on the Flutter side, leaving the app must never leave
    // the phone's sound muted.
    override fun onPause() {
        restoreStreams()
        super.onPause()
    }

    override fun onDestroy() {
        restoreStreams()
        soundPool?.release()
        soundPool = null
        super.onDestroy()
    }
}
