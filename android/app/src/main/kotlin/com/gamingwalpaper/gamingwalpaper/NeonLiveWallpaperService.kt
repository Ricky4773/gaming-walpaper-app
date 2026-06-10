package com.gamingwalpaper.gamingwalpaper

import android.content.res.AssetFileDescriptor
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import android.service.wallpaper.WallpaperService
import android.util.Log
import android.view.SurfaceHolder
import java.io.File
import java.io.FileInputStream

class NeonLiveWallpaperService : WallpaperService() {
    private companion object {
        const val TAG = "RXTLiveWallpaper"
    }

    override fun onCreateEngine(): Engine = VideoEngine()

    private inner class VideoEngine : Engine() {
        private val handler = Handler(Looper.getMainLooper())

        private var surfaceReady = false
        private var videoPath = ""
        private var videoAsset = ""
        private var preparedVideoPath = ""
        private var preparedVideoAsset = ""
        private var mediaPlayer: MediaPlayer? = null
        private var videoInput: FileInputStream? = null
        private var videoAssetDescriptor: AssetFileDescriptor? = null

        // ── Lifecycle ────────────────────────────────────────────────────────

        override fun onSurfaceCreated(holder: SurfaceHolder) {
            super.onSurfaceCreated(holder)
            holder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS)
            surfaceReady = true
            Log.d(TAG, "onSurfaceCreated surfaceValid=${holder.surface?.isValid}")
            refreshPlayback(holder)
        }

        override fun onSurfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
            super.onSurfaceChanged(holder, format, width, height)
            surfaceReady = true
            Log.d(TAG, "onSurfaceChanged ${width}x${height}")
            refreshPlayback(holder)
        }

        override fun onSurfaceDestroyed(holder: SurfaceHolder) {
            super.onSurfaceDestroyed(holder)
            surfaceReady = false
            Log.d(TAG, "onSurfaceDestroyed")
            releasePlayer()
        }

        override fun onVisibilityChanged(isVisible: Boolean) {
            Log.d(TAG, "onVisibilityChanged isVisible=$isVisible surfaceReady=$surfaceReady")
            if (isVisible && surfaceReady) {
                mediaPlayer?.let {
                    if (!it.isPlaying) it.start()
                } ?: refreshPlayback(surfaceHolder)
            } else {
                mediaPlayer?.pause()
            }
        }

        override fun onDestroy() {
            releasePlayer()
            super.onDestroy()
        }

        // ── Playback ─────────────────────────────────────────────────────────

        private fun refreshPlayback(holder: SurfaceHolder) {
            loadPrefs()
            Log.d(TAG, "refreshPlayback videoPath='$videoPath' videoAsset='$videoAsset'")

            if (!hasVideoSource()) {
                Log.w(TAG, "No video source set — wallpaper will be black until user picks a video")
                releasePlayer()
                return
            }

            startVideo(holder)
        }

        private fun startVideo(holder: SurfaceHolder) {
            // Reuse already-prepared player for same source
            val existing = mediaPlayer
            if (existing != null &&
                preparedVideoPath == videoPath &&
                preparedVideoAsset == videoAsset
            ) {
                Log.d(TAG, "reusing existing player")
                try {
                    existing.setDisplay(holder)
                    if (!existing.isPlaying) existing.start()
                } catch (e: Exception) {
                    Log.e(TAG, "reused player error, recreating", e)
                    releasePlayer()
                    startVideo(holder)
                }
                return
            }

            releasePlayer()

            try {
                val file = File(videoPath)
                Log.d(TAG, "creating MediaPlayer for path='${file.absolutePath}' asset='$videoAsset'")

                val player = MediaPlayer()
                mediaPlayer       = player
                preparedVideoPath  = videoPath
                preparedVideoAsset = videoAsset

                player.apply {
                    setDataSourceFromPrefs(this, file)
                    setDisplay(holder)
                    isLooping = true
                    setVolume(0f, 0f)

                    setOnPreparedListener { p ->
                        Log.d(TAG, "onPrepared ${p.videoWidth}x${p.videoHeight} duration=${p.duration}ms")
                        try { p.start() } catch (e: Exception) { Log.e(TAG, "start() failed", e) }
                    }

                    setOnErrorListener { p, what, extra ->
                        Log.e(TAG, "MediaPlayer error what=$what extra=$extra")
                        p.release()
                        if (mediaPlayer == p) {
                            mediaPlayer        = null
                            preparedVideoPath  = ""
                            preparedVideoAsset = ""
                        }
                        true
                    }

                    prepareAsync()
                }
            } catch (e: Exception) {
                Log.e(TAG, "startVideo failed", e)
                releasePlayer()
            }
        }

        private fun releasePlayer() {
            try { mediaPlayer?.release() } catch (_: Exception) {}
            mediaPlayer = null
            try { videoInput?.close() } catch (_: Exception) {}
            videoInput = null
            try { videoAssetDescriptor?.close() } catch (_: Exception) {}
            videoAssetDescriptor = null
            preparedVideoPath  = ""
            preparedVideoAsset = ""
        }

        // ── Helpers ──────────────────────────────────────────────────────────

        private fun loadPrefs() {
            val prefs = getSharedPreferences("rxt_live_wallpaper", MODE_PRIVATE)
            videoPath  = prefs.getString("videoPath",  "") ?: ""
            videoAsset = prefs.getString("videoAsset", "") ?: ""
            Log.d(TAG, "loadPrefs videoPath='$videoPath' videoAsset='$videoAsset'")
        }

        private fun hasVideoSource(): Boolean =
            (videoPath.isNotBlank() && File(videoPath).exists()) || videoAsset.isNotBlank()

        private fun setDataSourceFromPrefs(player: MediaPlayer, file: File) {
            if (file.exists() && file.canRead() && file.length() > 0) {
                Log.d(TAG, "setDataSource from file fd size=${file.length()}")
                val input = FileInputStream(file)
                videoInput = input
                player.setDataSource(input.fd)
                return
            }

            if (videoAsset.isNotBlank()) {
                val assetPath = "flutter_assets/$videoAsset"
                Log.d(TAG, "setDataSource from asset '$assetPath'")
                val fd = assets.openFd(assetPath)
                videoAssetDescriptor = fd
                player.setDataSource(fd.fileDescriptor, fd.startOffset, fd.length)
                return
            }

            throw IllegalStateException("No valid video source. path='$videoPath' asset='$videoAsset'")
        }
    }
}
