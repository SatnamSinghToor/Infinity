package com.duggustore.app

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.SoundPool
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var soundPool: SoundPool? = null
    private val soundIds = mutableMapOf<String, Int>()

    // Streams this app muted itself, so only those are ever unmuted — a
    // stream the user had muted stays muted.
    private val mutedStreams = mutableSetOf<Int>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
