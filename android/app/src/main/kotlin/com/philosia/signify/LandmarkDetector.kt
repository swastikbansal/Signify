package com.philosia.signify

import android.app.Activity
import android.content.Context
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class LandmarkDetector(
    private val activity: Activity,
    private val channel: MethodChannel,
    var minHandDetectionConfidence: Float = DEFAULT_HAND_DETECTION_CONFIDENCE,
    var minHandTrackingConfidence: Float = DEFAULT_HAND_TRACKING_CONFIDENCE,
    var minHandPresenceConfidence: Float = DEFAULT_HAND_PRESENCE_CONFIDENCE,
    var maxNumHands: Int = DEFAULT_NUM_HANDS,
    var minPoseDetectionConfidence: Float = DEFAULT_POSE_DETECTION_CONFIDENCE,
    var minPoseTrackingConfidence: Float = DEFAULT_POSE_TRACKING_CONFIDENCE,
    var minPosePresenceConfidence: Float = DEFAULT_POSE_PRESENCE_CONFIDENCE,
    var currentDelegate: Int = DELEGATE_GPU,
    var runningMode: RunningMode = RunningMode.IMAGE,
    val context: Context,
    val LandmarkerHelperListener: LandmarkerListener? = null
) {

    companion object {
        const val DELEGATE_CPU = 0
        const val DELEGATE_GPU = 1
        // Lowered detection confidence for better second hand detection
        const val DEFAULT_HAND_DETECTION_CONFIDENCE = 0.3F
        // Reduced tracking confidence to maintain detection of weaker hands
        const val DEFAULT_HAND_TRACKING_CONFIDENCE = 0.3F
        // Lowered presence confidence for better multi-hand scenarios
        const val DEFAULT_HAND_PRESENCE_CONFIDENCE = 0.3F
        const val DEFAULT_NUM_HANDS = 2
        const val DEFAULT_POSE_DETECTION_CONFIDENCE = 0.5F
        const val DEFAULT_POSE_TRACKING_CONFIDENCE = 0.5F
        const val DEFAULT_POSE_PRESENCE_CONFIDENCE = 0.5F
        const val TAG = "LandmarkDetector"
        const val OTHER_ERROR = 0
        const val GPU_ERROR = 1
    }

    private var handLandmarker: HandLandmarker? = null
    private var poseLandmarker: PoseLandmarker? = null
    private lateinit var backgroundExecutor: ExecutorService
    private var isDetectionActive = false

    fun initialize() {
        backgroundExecutor = Executors.newSingleThreadExecutor()
        setupMediaPipe()
    }

    fun clearHandLandmarker() {
        handLandmarker?.close()
        poseLandmarker?.close()
        handLandmarker = null
        poseLandmarker = null
    }

    // Return running status of HandLandmarkerHelper
    fun isClose(): Boolean {
        return handLandmarker == null && poseLandmarker == null 
    }

    // Method to update hand detection parameters for better multi-hand detection
    fun updateHandDetectionParams(
        detectionConfidence: Float = 0.3f,
        trackingConfidence: Float = 0.3f,
        presenceConfidence: Float = 0.3f
    ) {
        minHandDetectionConfidence = detectionConfidence
        minHandTrackingConfidence = trackingConfidence
        minHandPresenceConfidence = presenceConfidence
        
        Log.d(TAG, "Updated hand detection params - Detection: $detectionConfidence, Tracking: $trackingConfidence, Presence: $presenceConfidence")
        
        // Reinitialize with new parameters
        clearHandLandmarker()
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
            val handBaseOptionBuilder = BaseOptions.builder()
                
            when (currentDelegate) {
                DELEGATE_CPU -> {
                    handBaseOptionBuilder.setDelegate(Delegate.CPU)
                }
                DELEGATE_GPU -> {
                    handBaseOptionBuilder.setDelegate(Delegate.GPU)
                }
            }

            handBaseOptionBuilder.setModelAssetPath("hand_landmarker.task")
            val handBaseOptions = handBaseOptionBuilder.build()

            if (runningMode == RunningMode.LIVE_STREAM && LandmarkerHelperListener == null) {
                throw IllegalStateException(
                    "LandmarkerHelperListener must be set when runningMode is LIVE_STREAM."
                )
            }

            val handOptionsBuilder = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(handBaseOptions)
                .setMinHandDetectionConfidence(minHandDetectionConfidence)
                .setMinTrackingConfidence(minHandTrackingConfidence)
                .setMinHandPresenceConfidence(minHandPresenceConfidence)
                .setNumHands(maxNumHands)
                .setRunningMode(runningMode)

            // Add logging to verify configuration
            Log.d(TAG, "Hand detection config - Detection: $minHandDetectionConfidence, Tracking: $minHandTrackingConfidence, Presence: $minHandPresenceConfidence, MaxHands: $maxNumHands")

            if (runningMode == RunningMode.LIVE_STREAM) {
                handOptionsBuilder
                    .setResultListener(this::returnLivestreamHandResult)
                    .setErrorListener(this::returnLivestreamHandError)
            }
            
            val handOptions = handOptionsBuilder.build()
            handLandmarker = HandLandmarker.createFromOptions(activity, handOptions)


            // Pose Landmarker setup
            val poseBaseOptionBuilder = BaseOptions.builder()
                
            when (currentDelegate) {
                DELEGATE_CPU -> {
                    poseBaseOptionBuilder.setDelegate(Delegate.CPU)
                }
                DELEGATE_GPU -> {
                    poseBaseOptionBuilder.setDelegate(Delegate.GPU)
                }
            }

            poseBaseOptionBuilder.setModelAssetPath("pose_landmarker.task")
            val poseBaseOptions = poseBaseOptionBuilder.build()

            val poseOptionsBuilder = PoseLandmarker.PoseLandmarkerOptions.builder()
                .setBaseOptions(poseBaseOptions)
                .setMinPoseDetectionConfidence(minPoseDetectionConfidence)
                .setMinTrackingConfidence(minPoseTrackingConfidence)
                .setMinPosePresenceConfidence(minPosePresenceConfidence)
                .setRunningMode(runningMode)

            if (runningMode == RunningMode.LIVE_STREAM) {
                poseOptionsBuilder
                    .setResultListener(this::returnLivestreamPoseResult)
                    .setErrorListener(this::returnLivestreamPoseError)
            }

            val poseOptions = poseOptionsBuilder.build()
            poseLandmarker = PoseLandmarker.createFromOptions(activity, poseOptions)

            activity.runOnUiThread {
                channel.invokeMethod("onInitialized", mapOf("success" to true))
            }

        } catch (e: Exception) {
            val error = "Error setting up MediaPipe: ${e.message}"
            Log.e(TAG, error)
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

                // Create bitmap from camera image data with better error handling
                val bitmap = createBitmapFromYuv420(yBytes, width, height, yPixelStride, yRowStride)
                
                // Verify bitmap was created successfully
                if (bitmap.isRecycled) {
                    Log.w(TAG, "Created bitmap is recycled, skipping frame")
                    return@execute
                }

                val mpImage = BitmapImageBuilder(bitmap).build()
                val frameTime = System.currentTimeMillis()

                // Process with MediaPipe - hand detection first as it's more critical
                val handResult = handLandmarker?.detect(mpImage)
                val poseResult = poseLandmarker?.detect(mpImage)

                // Send results with better error handling
                handResult?.let { 
                    sendHandLandmarks(it, frameTime) 
                } ?: run {
                    // Log occasional warnings when hand detection fails
                    if (frameTime % 5000 < 100) { // ~every 5 seconds
                        Log.w(TAG, "Hand detection returned null result")
                    }
                }
                
                poseResult?.let { sendPoseLandmarks(it, frameTime) }

                // Clean up bitmap to prevent memory leaks
                if (!bitmap.isRecycled) {
                    bitmap.recycle()
                }

            } catch (e: Exception) {
                Log.e(TAG, "Error processing Flutter image: ${e.message}", e)
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
                        
                        // Apply contrast enhancement for better hand detection
                        val enhancedY = enhanceContrast(yValue)
                        
                        // Create grayscale pixel with enhanced contrast
                        val pixel = android.graphics.Color.rgb(enhancedY, enhancedY, enhancedY)
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
            Log.e(TAG, "Error creating bitmap from YUV: ${e.message}", e)
            // Return a simple black bitmap as fallback
            return android.graphics.Bitmap.createBitmap(
                width,
                height,
                android.graphics.Bitmap.Config.ARGB_8888
            )
        }
    }

    // Helper method to enhance contrast for better hand detection
    private fun enhanceContrast(yValue: Int): Int {
        // Apply simple contrast enhancement
        // This helps MediaPipe better distinguish hand features
        val contrast = 1.2f // Increase contrast by 20%
        val enhanced = ((yValue - 128) * contrast + 128).toInt()
        
        // Clamp to valid range
        return when {
            enhanced < 0 -> 0
            enhanced > 255 -> 255
            else -> enhanced
        }
    }

    private fun sendHandLandmarks(result: HandLandmarkerResult, timestamp: Long) {
        val numHands = result.landmarks().size
        
        // Enhanced logging for multi-hand detection debugging
        if (numHands > 0) {
            Log.d(TAG, "Detected $numHands hand(s) at timestamp $timestamp")
            
            // Log hand confidence scores if available
            if (result.handednesses().isNotEmpty()) {
                result.handednesses().forEachIndexed { handIndex, handedness ->
                    if (handedness.isNotEmpty()) {
                        val confidence = handedness[0].score()
                        val label = handedness[0].categoryName()
                        Log.d(TAG, "Hand $handIndex: $label (confidence: $confidence)")
                    }
                }
            }
            
            // Detailed landmark logging (reduced frequency to avoid spam)
            if (timestamp % 1000 < 100) { // Log detailed info ~every second
                result.landmarks().forEachIndexed { handIndex, hand ->
                    Log.d("HandLandmarks", "=== Hand $handIndex (${hand.size} landmarks) ===")
                    // Log only key landmarks (wrist, thumb tip, index tip, middle tip, ring tip, pinky tip)
                    val keyLandmarks = listOf(0, 4, 8, 12, 16, 20)
                    keyLandmarks.forEach { landmarkIndex ->
                        if (landmarkIndex < hand.size) {
                            val landmark = hand[landmarkIndex]
                            Log.d(
                                "HandLandmarks",
                                "Key Landmark $landmarkIndex: x=${landmark.x()}, y=${landmark.y()}, z=${landmark.z()}"
                            )
                        }
                    }
                }
            }

            val handsData = result.landmarks().map { hand ->
                hand.map { landmark ->
                    mapOf("x" to landmark.x(), "y" to landmark.y(), "z" to landmark.z())
                }
            }
            
            // Include handedness information in the result
            val handednessData = if (result.handednesses().isNotEmpty()) {
                result.handednesses().map { handedness ->
                    if (handedness.isNotEmpty()) {
                        mapOf(
                            "label" to handedness[0].categoryName(),
                            "confidence" to handedness[0].score()
                        )
                    } else {
                        mapOf("label" to "Unknown", "confidence" to 0.0f)
                    }
                }
            } else {
                emptyList()
            }
            
            activity.runOnUiThread {
                channel.invokeMethod(
                    "onHandLandmarks",
                    mapOf(
                        "hands" to handsData, 
                        "handedness" to handednessData,
                        "timestamp" to timestamp,
                        "numHands" to numHands
                    )
                )
            }
        } else {
            // Log when no hands are detected (but less frequently)
            if (timestamp % 2000 < 100) { // Log ~every 2 seconds
                Log.d(TAG, "No hands detected at timestamp $timestamp")
            }
        }
    }

    private fun sendPoseLandmarks(result: PoseLandmarkerResult, timestamp: Long) {
        if (result.landmarks().isNotEmpty()) {
            // Log pose landmark count for debugging skeleton overlay issues
            result.landmarks().forEachIndexed { poseIndex, pose ->
                Log.d("PoseLandmarks", "=== Pose $poseIndex (${pose.size} landmarks) ===")
                // Log key landmarks for skeleton positioning debugging
                if (timestamp % 2000 < 100) { // Log ~every 2 seconds
                    val keyLandmarks = listOf(0, 11, 12, 23, 24) // nose, shoulders, hips
                    keyLandmarks.forEach { landmarkIndex ->
                        if (landmarkIndex < pose.size) {
                            val landmark = pose[landmarkIndex]
                            Log.d(
                                "PoseLandmarks",
                                "Key Landmark $landmarkIndex: x=${landmark.x()}, y=${landmark.y()}, z=${landmark.z()}"
                            )
                        }
                    }
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
                    mapOf(
                        "poses" to posesData, 
                        "timestamp" to timestamp,
                        "numPoses" to result.landmarks().size
                    )
                )
            }
        } else {
            // Log when no poses are detected
            if (timestamp % 3000 < 100) { // Log ~every 3 seconds
                Log.d(TAG, "No poses detected at timestamp $timestamp")
            }
        }
    }

    private fun returnLivestreamHandResult(result: HandLandmarkerResult, input: MPImage) {
        val finishTimeMs = System.currentTimeMillis()
        val inferenceTime = finishTimeMs - result.timestampMs()
        LandmarkerHelperListener?.onHandResults(result, inferenceTime, input.height, input.width)
    }

    private fun returnLivestreamHandError(error: RuntimeException) {
        LandmarkerHelperListener?.onError(error.message ?: "Hand detection error", OTHER_ERROR)
    }

    private fun returnLivestreamPoseResult(result: PoseLandmarkerResult, input: MPImage) {
        val finishTimeMs = System.currentTimeMillis()
        val inferenceTime = finishTimeMs - result.timestampMs()
        LandmarkerHelperListener?.onPoseResults(result, inferenceTime, input.height, input.width)
    }

    private fun returnLivestreamPoseError(error: RuntimeException) {
        LandmarkerHelperListener?.onError(error.message ?: "Pose detection error", OTHER_ERROR)
    }

    fun stopDetection() {
        isDetectionActive = false
        handLandmarker?.close()
        poseLandmarker?.close()
        if (::backgroundExecutor.isInitialized) {
            backgroundExecutor.shutdown()
        }
    }

    interface LandmarkerListener {
        fun onError(error: String, errorCode: Int = OTHER_ERROR)
        fun onHandResults(result: HandLandmarkerResult, inferenceTime: Long, height: Int, width: Int)
        fun onPoseResults(result: PoseLandmarkerResult, inferenceTime: Long, height: Int, width: Int)
    }
}