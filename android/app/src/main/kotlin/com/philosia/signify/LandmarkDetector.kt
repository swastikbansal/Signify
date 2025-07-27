package com.philosia.signify

import android.app.Activity
import android.util.Log
import android.util.Size
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class LandmarkDetector(private val activity: Activity, private val channel: MethodChannel) {

    private var handLandmarker: HandLandmarker? = null
    private var poseLandmarker: PoseLandmarker? = null
    private lateinit var backgroundExecutor: ExecutorService
    private var isDetectionActive = false

    fun initialize() {
        backgroundExecutor = Executors.newSingleThreadExecutor()
        setupMediaPipe()
    }

    fun startDetection() {
        isDetectionActive = true
        activity.runOnUiThread {
            channel.invokeMethod("onCameraReady", mapOf("success" to true))
        }
    }

    private fun setupMediaPipe() {
        try {
            // Hand Landmarker setup
            val handBaseOptions = BaseOptions.builder()
                .setModelAssetPath("hand_landmarker.task")
                .build()

            val handOptions = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(handBaseOptions)
                .setMinHandDetectionConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .setMinHandPresenceConfidence(0.5f)
                .setNumHands(2)
                .setRunningMode(RunningMode.IMAGE)
                .build()

            handLandmarker = HandLandmarker.createFromOptions(activity, handOptions)

            // Pose Landmarker setup
            val poseBaseOptions = BaseOptions.builder()
                .setModelAssetPath("pose_landmarker.task")
                .build()

            val poseOptions = PoseLandmarker.PoseLandmarkerOptions.builder()
                .setBaseOptions(poseBaseOptions)
                .setMinPoseDetectionConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .setMinPosePresenceConfidence(0.5f)
                .setRunningMode(RunningMode.IMAGE)
                .build()

            poseLandmarker = PoseLandmarker.createFromOptions(activity, poseOptions)

            activity.runOnUiThread {
                channel.invokeMethod("onInitialized", mapOf("success" to true))
            }

        } catch (e: Exception) {
            val error = "Error setting up MediaPipe: ${e.message}"
            Log.e("MediaPipe", error)
            activity.runOnUiThread {
                channel.invokeMethod("onError", mapOf("error" to error))
            }
        }
    }

    fun processImageFromFlutter(imageData: Map<String, Any>) {
        if (!isDetectionActive) return

        backgroundExecutor.execute {
            try {
                // Convert Flutter camera image to MediaPipe format
                val width = imageData["width"] as Int
                val height = imageData["height"] as Int
                val planes = imageData["planes"] as List<Map<String, Any>>

                // Get the Y plane (luminance) from the camera image
                val yPlane = planes[0]
                val yBytes = yPlane["bytes"] as ByteArray
                val yPixelStride = (yPlane["bytesPerPixel"] as Int?) ?: 1
                val yRowStride = (yPlane["bytesPerRow"] as Int?) ?: width

                // Create bitmap from camera image data
                val bitmap = createBitmapFromYuv420(yBytes, width, height, yPixelStride, yRowStride)

                val mpImage = BitmapImageBuilder(bitmap).build()
                val frameTime = System.currentTimeMillis()

                // Process with MediaPipe
                val handResult = handLandmarker?.detect(mpImage)
                val poseResult = poseLandmarker?.detect(mpImage)

                // Send results
                handResult?.let { sendHandLandmarks(it, frameTime) }
                poseResult?.let { sendPoseLandmarks(it, frameTime) }

            } catch (e: Exception) {
                Log.e("LandmarkDetector", "Error processing Flutter image: ${e.message}", e)
            }
        }
    }

    private fun createBitmapFromYuv420(
        yPlane: ByteArray,
        width: Int,
        height: Int,
        pixelStride: Int,
        rowStride: Int
    ): android.graphics.Bitmap {
        try {
            val bitmap = android.graphics.Bitmap.createBitmap(
                width,
                height,
                android.graphics.Bitmap.Config.ARGB_8888
            )

            val pixels = IntArray(width * height)
            var yIndex = 0

            for (y in 0 until height) {
                for (x in 0 until width) {
                    // Calculate the correct index in the Y plane
                    val yPlaneIndex = y * rowStride + x * pixelStride

                    // Ensure we don't exceed array bounds
                    if (yPlaneIndex < yPlane.size) {
                        val yValue = yPlane[yPlaneIndex].toInt() and 0xFF
                        // Create grayscale pixel
                        val pixel = android.graphics.Color.rgb(yValue, yValue, yValue)
                        pixels[yIndex] = pixel
                    } else {
                        // Use black pixel if we're out of bounds
                        pixels[yIndex] = android.graphics.Color.BLACK
                    }
                    yIndex++
                }
            }

            bitmap.setPixels(pixels, 0, width, 0, 0, width, height)
            return bitmap

        } catch (e: Exception) {
            Log.e("LandmarkDetector", "Error creating bitmap from YUV: ${e.message}", e)
            // Return a simple black bitmap as fallback
            return android.graphics.Bitmap.createBitmap(
                width,
                height,
                android.graphics.Bitmap.Config.ARGB_8888
            )
        }
    }

    private fun sendHandLandmarks(result: HandLandmarkerResult, timestamp: Long) {
        if (result.landmarks().isNotEmpty()) {
            // Print all hand landmarks to console
            result.landmarks().forEachIndexed { handIndex, hand ->
                Log.d("HandLandmarks", "=== Hand $handIndex (${hand.size} landmarks) ===")
                hand.forEachIndexed { landmarkIndex, landmark ->
                    Log.d(
                        "HandLandmarks",
                        "Landmark $landmarkIndex: x=${landmark.x()}, y=${landmark.y()}, z=${landmark.z()}"
                    )
                }
            }

            val handsData = result.landmarks().map { hand ->
                hand.map { landmark ->
                    mapOf("x" to landmark.x(), "y" to landmark.y(), "z" to landmark.z())
                }
            }
            activity.runOnUiThread {
                channel.invokeMethod(
                    "onHandLandmarks",
                    mapOf("hands" to handsData, "timestamp" to timestamp)
                )
            }
        }
    }

    private fun sendPoseLandmarks(result: PoseLandmarkerResult, timestamp: Long) {
        if (result.landmarks().isNotEmpty()) {
            // Print all pose landmarks to console
            result.landmarks().forEachIndexed { poseIndex, pose ->
                Log.d("PoseLandmarks", "=== Pose $poseIndex (${pose.size} landmarks) ===")
                pose.forEachIndexed { landmarkIndex, landmark ->
                    Log.d(
                        "PoseLandmarks",
                        "Landmark $landmarkIndex: x=${landmark.x()}, y=${landmark.y()}, z=${landmark.z()}"
                    )
                }
            }

            val posesData = result.landmarks().map { pose ->
                pose.map { landmark ->
                    mapOf("x" to landmark.x(), "y" to landmark.y(), "z" to landmark.z())
                }
            }
            activity.runOnUiThread {
                channel.invokeMethod(
                    "onPoseLandmarks",
                    mapOf("poses" to posesData, "timestamp" to timestamp)
                )
            }
        }
    }

    fun stopDetection() {
        isDetectionActive = false
        handLandmarker?.close()
        poseLandmarker?.close()
        if (::backgroundExecutor.isInitialized) {
            backgroundExecutor.shutdown()
        }
    }
}