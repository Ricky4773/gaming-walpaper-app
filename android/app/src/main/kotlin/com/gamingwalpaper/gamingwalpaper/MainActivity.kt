package com.gamingwalpaper.gamingwalpaper

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private companion object {
        const val TAG = "RXTLiveWallpaper"
    }

    private val downloadsChannel = "rxt_gaming/downloads"
    private val liveWallpaperChannel = "rxt_gaming/live_wallpaper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            downloadsChannel
        ).setMethodCallHandler { call, result ->
            if (call.method != "saveImageToDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val sourcePath = call.argument<String>("sourcePath")
            val fileName = call.argument<String>("fileName") ?: "rxt_gaming_wallpaper.jpg"

            if (sourcePath.isNullOrBlank()) {
                result.error("NO_SOURCE", "Source file path missing", null)
                return@setMethodCallHandler
            }

            try {
                result.success(saveImageToDownloads(sourcePath, fileName))
            } catch (error: Exception) {
                result.error("SAVE_FAILED", error.message, null)
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            liveWallpaperChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setLiveWallpaperStyle" -> {
                    saveLiveWallpaperStyle(
                        title = call.argument<String>("title") ?: "RXT Neon",
                        colorOne = call.numberArgument("colorOne", 0xFF00E5FF.toInt()),
                        colorTwo = call.numberArgument("colorTwo", 0xFFFF2D92.toInt()),
                        colorThree = call.numberArgument("colorThree", 0xFF7C4DFF.toInt()),
                        speed = call.numberArgument("speed", 1f),
                        intensity = call.numberArgument("intensity", 1f),
                        videoPath = call.argument<String>("videoPath") ?: "",
                        videoAsset = call.argument<String>("videoAsset") ?: ""
                    )
                    result.success(true)
                }
                "openLiveWallpaper" -> {
                    try {
                        openLiveWallpaperPicker()
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("LIVE_WALLPAPER_FAILED", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveImageToDownloads(sourcePath: String, fileName: String): String {
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists()) {
            throw IllegalArgumentException("Source file does not exist")
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "image/jpeg")
                put(
                    MediaStore.Downloads.RELATIVE_PATH,
                    "${Environment.DIRECTORY_DOWNLOADS}/RXT Gaming"
                )
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Could not create downloads entry")

            resolver.openOutputStream(uri)?.use { output ->
                FileInputStream(sourceFile).use { input ->
                    input.copyTo(output)
                }
            } ?: throw IllegalStateException("Could not open downloads output stream")

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return "${Environment.DIRECTORY_DOWNLOADS}/RXT Gaming/$fileName"
        }

        val downloadsDir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            "RXT Gaming"
        )
        if (!downloadsDir.exists()) {
            downloadsDir.mkdirs()
        }

        val targetFile = File(downloadsDir, fileName)
        sourceFile.copyTo(targetFile, overwrite = true)
        return targetFile.absolutePath
    }

    private fun openLiveWallpaperPicker() {
        val component = ComponentName(this, NeonLiveWallpaperService::class.java)
        val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
            putExtra(WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT, component)
        }
        startActivity(intent)
    }

    private fun saveLiveWallpaperStyle(
        title: String,
        colorOne: Int,
        colorTwo: Int,
        colorThree: Int,
        speed: Float,
        intensity: Float,
        videoPath: String,
        videoAsset: String
    ) {
        val videoFile = File(videoPath)
        Log.d(
            TAG,
            "MainActivity saveLiveWallpaperStyle title='$title' videoPath='$videoPath' videoAsset='$videoAsset' exists=${videoFile.exists()} canRead=${videoFile.canRead()} length=${if (videoFile.exists()) videoFile.length() else -1}"
        )
        val committed = getSharedPreferences("rxt_live_wallpaper", MODE_PRIVATE)
            .edit()
            .putString("title", title)
            .putInt("colorOne", colorOne)
            .putInt("colorTwo", colorTwo)
            .putInt("colorThree", colorThree)
            .putFloat("speed", speed.coerceIn(0.5f, 1.6f))
            .putFloat("intensity", intensity.coerceIn(0.6f, 1.5f))
            .putString("videoPath", videoPath)
            .putString("videoAsset", videoAsset)
            .commit()
        Log.d(TAG, "MainActivity prefsCommit=$committed")
    }

    private fun <T : Number> io.flutter.plugin.common.MethodCall.numberArgument(
        key: String,
        defaultValue: T
    ): T {
        val value = argument<Number>(key) ?: return defaultValue
        @Suppress("UNCHECKED_CAST")
        return when (defaultValue) {
            is Int -> value.toInt() as T
            is Float -> value.toFloat() as T
            else -> defaultValue
        }
    }
}
