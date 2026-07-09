package com.gamingwalpaper.gamingwalpaper

import android.app.WallpaperManager
import android.content.ContentValues
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
    private companion object {
        const val TAG = "RXTMainActivity"
        const val DOWNLOADS_CHANNEL = "rxt_gaming/downloads"
        const val LIVE_WALLPAPER_CHANNEL = "rxt_gaming/live_wallpaper"
        const val RINGTONE_CHANNEL = "rxt_gaming/ringtone"
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Downloads channel ───────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOWNLOADS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveImageToDownloads" -> {
                        val sourcePath = call.argument<String>("sourcePath")
                        val fileName = call.argument<String>("fileName")
                        if (sourcePath == null || fileName == null) {
                            result.error("ARGS", "sourcePath/fileName missing", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val savedPath = saveImageToDownloads(sourcePath, fileName)
                            if (savedPath != null) {
                                result.success(savedPath)
                            } else {
                                result.error("SAVE_FAILED", "Could not save image", null)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "saveImageToDownloads failed", e)
                            result.error("EXCEPTION", e.message, null)
                        }
                    }

                    "saveAudioToDownloads" -> {
                        val sourcePath = call.argument<String>("sourcePath")
                        val fileName = call.argument<String>("fileName")
                        if (sourcePath == null || fileName == null) {
                            result.error("ARGS", "sourcePath/fileName missing", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val savedPath = saveAudioToDownloads(sourcePath, fileName)
                            if (savedPath != null) {
                                result.success(savedPath)
                            } else {
                                result.error("SAVE_FAILED", "Could not save audio", null)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "saveAudioToDownloads failed", e)
                            result.error("EXCEPTION", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        // ── Live wallpaper channel ──────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LIVE_WALLPAPER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setLiveWallpaperStyle" -> {
                        try {
                            val prefs = getSharedPreferences("rxt_live_wallpaper", MODE_PRIVATE)
                            val editor = prefs.edit()
                            editor.putString("title", call.argument<String>("title") ?: "")
                            editor.putInt("colorOne", call.argument<Int>("colorOne") ?: 0xFF00E5FF.toInt())
                            editor.putInt("colorTwo", call.argument<Int>("colorTwo") ?: 0xFFFF2D92.toInt())
                            editor.putInt("colorThree", call.argument<Int>("colorThree") ?: 0xFF7C4DFF.toInt())
                            val speed = (call.argument<Double>("speed") ?: 1.0).toFloat()
                            val intensity = (call.argument<Double>("intensity") ?: 1.0).toFloat()
                            editor.putFloat("speed", speed)
                            editor.putFloat("intensity", intensity)
                            editor.putString("videoPath", call.argument<String>("videoPath") ?: "")
                            editor.putString("videoAsset", call.argument<String>("videoAsset") ?: "")
                            editor.apply()
                            Log.d(TAG, "setLiveWallpaperStyle saved to prefs")
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "setLiveWallpaperStyle failed", e)
                            result.error("EXCEPTION", e.message, null)
                        }
                    }

                    "openLiveWallpaper" -> {
                        try {
                            val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER)
                            intent.putExtra(
                                WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                                android.content.ComponentName(
                                    this,
                                    "com.gamingwalpaper.gamingwalpaper.NeonLiveWallpaperService"
                                )
                            )
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "openLiveWallpaper failed, trying generic picker", e)
                            try {
                                val fallback = Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER)
                                fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(fallback)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("EXCEPTION", e2.message, null)
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        // ── Ringtone channel ─────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RINGTONE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setRingtone" -> {
                        val sourcePath = call.argument<String>("sourcePath")
                        val fileName = call.argument<String>("fileName")
                        val title = call.argument<String>("title") ?: fileName ?: "RXT Ringtone"
                        if (sourcePath == null || fileName == null) {
                            result.error("ARGS", "sourcePath/fileName missing", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val status = setAsRingtone(sourcePath, fileName, title)
                            result.success(mapOf("status" to status))
                        } catch (e: Exception) {
                            Log.e(TAG, "setRingtone failed", e)
                            result.error("EXCEPTION", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ── Helper: save image to public Downloads via MediaStore ────────────
    private fun saveImageToDownloads(sourcePath: String, fileName: String): String? {
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists()) {
            Log.e(TAG, "saveImageToDownloads source file missing: $sourcePath")
            return null
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/RXT Gaming")
            }
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                ?: return null
            resolver.openOutputStream(uri)?.use { out ->
                FileInputStream(sourceFile).use { input -> input.copyTo(out) }
            }
            return uri.toString()
        } else {
            val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
            val targetDir = File(picturesDir, "RXT Gaming")
            if (!targetDir.exists()) targetDir.mkdirs()
            val targetFile = File(targetDir, fileName)
            FileInputStream(sourceFile).use { input ->
                FileOutputStream(targetFile).use { out -> input.copyTo(out) }
            }
            // Notify gallery
            val intent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
            intent.data = Uri.fromFile(targetFile)
            sendBroadcast(intent)
            return targetFile.absolutePath
        }
    }

    // ── Helper: save audio to public Downloads via MediaStore ────────────
    private fun saveAudioToDownloads(sourcePath: String, fileName: String): String? {
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists()) {
            Log.e(TAG, "saveAudioToDownloads source file missing: $sourcePath")
            return null
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "audio/mpeg")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/RXT Gaming")
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: return null
            resolver.openOutputStream(uri)?.use { out ->
                FileInputStream(sourceFile).use { input -> input.copyTo(out) }
            }
            return uri.toString()
        } else {
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val targetDir = File(downloadsDir, "RXT Gaming")
            if (!targetDir.exists()) targetDir.mkdirs()
            val targetFile = File(targetDir, fileName)
            FileInputStream(sourceFile).use { input ->
                FileOutputStream(targetFile).use { out -> input.copyTo(out) }
            }
            return targetFile.absolutePath
        }
    }

    // ── Helper: set file as device ringtone via MediaStore + RingtoneManager ──
    // Returns one of: "success", "permission_needed", "failed"
    private fun setAsRingtone(sourcePath: String, fileName: String, title: String): String {
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists()) {
            Log.e(TAG, "setAsRingtone source file missing: $sourcePath")
            return "failed"
        }

        // Android 6+ requires WRITE_SETTINGS permission to set system-wide ringtone.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.System.canWrite(this)) {
            Log.w(TAG, "setAsRingtone missing WRITE_SETTINGS permission, opening settings screen")
            val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
            intent.data = Uri.parse("package:$packageName")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            return "permission_needed"
        }

        return try {
            val ringtoneUri: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val resolver = contentResolver
                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                    put(MediaStore.MediaColumns.MIME_TYPE, "audio/mpeg")
                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_RINGTONES + "/RXT Gaming")
                    put(MediaStore.Audio.Media.IS_RINGTONE, true)
                    put(MediaStore.Audio.Media.IS_NOTIFICATION, false)
                    put(MediaStore.Audio.Media.IS_ALARM, false)
                    put(MediaStore.Audio.Media.IS_MUSIC, false)
                    put(MediaStore.Audio.Media.TITLE, title)
                }
                val insertedUri = resolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
                if (insertedUri == null) {
                    Log.e(TAG, "setAsRingtone insert returned null uri")
                    return "failed"
                }
                resolver.openOutputStream(insertedUri)?.use { out ->
                    FileInputStream(sourceFile).use { input -> input.copyTo(out) }
                }
                insertedUri
            } else {
                val ringtonesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_RINGTONES)
                val targetDir = File(ringtonesDir, "RXT Gaming")
                if (!targetDir.exists()) targetDir.mkdirs()
                val targetFile = File(targetDir, fileName)
                FileInputStream(sourceFile).use { input ->
                    FileOutputStream(targetFile).use { out -> input.copyTo(out) }
                }

                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.DATA, targetFile.absolutePath)
                    put(MediaStore.MediaColumns.TITLE, title)
                    put(MediaStore.MediaColumns.MIME_TYPE, "audio/mpeg")
                    put(MediaStore.Audio.Media.ARTIST, "RXT Gaming")
                    put(MediaStore.Audio.Media.IS_RINGTONE, true)
                    put(MediaStore.Audio.Media.IS_NOTIFICATION, false)
                    put(MediaStore.Audio.Media.IS_ALARM, false)
                    put(MediaStore.Audio.Media.IS_MUSIC, false)
                }

                // Remove any previous entry pointing to the same path to avoid duplicates
                contentResolver.delete(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    MediaStore.MediaColumns.DATA + "=?",
                    arrayOf(targetFile.absolutePath)
                )

                val insertedUri = contentResolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
                if (insertedUri == null) {
                    Log.e(TAG, "setAsRingtone legacy insert returned null uri")
                    return "failed"
                }
                insertedUri
            }

            RingtoneManager.setActualDefaultRingtoneUri(
                this,
                RingtoneManager.TYPE_RINGTONE,
                ringtoneUri
            )
            Log.d(TAG, "setAsRingtone success uri=$ringtoneUri")
            "success"
        } catch (e: Exception) {
            Log.e(TAG, "setAsRingtone exception", e)
            "failed"
        }
    }
}
