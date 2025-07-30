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
    
    // Memory management variables
    private var lastProcessTime = 0L
    private val MIN_PROCESS_INTERVAL = 66L // Minimum 66ms between frames (~15fps)
    private var isProcessing = false

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
        if (!isDetectionActive) {
            Log.w(TAG, "Detection not active, skipping frame")
            return
        }

        // Memory protection: Skip if already processing or too frequent
        val currentTime = System.currentTimeMillis()
        if (isProcessing || (currentTime - lastProcessTime) < MIN_PROCESS_INTERVAL) {
            return
        }

        isProcessing = true
        lastProcessTime = currentTime

        backgroundExecutor.execute {
            try {
                val width = imageData["width"] as Int
                val height = imageData["height"] as Int
                val format = imageData["format"] as String
                val isFrontCamera = imageData["isFrontCamera"] as? Boolean ?: false
                val planes = imageData["planes"] as List<Map<String, Any>>

                Log.d(TAG, "Processing image: ${width}x${height}, format: $format, frontCamera: $isFrontCamera")

                // Create bitmap with original size but optimized format
                val bitmap = createSimpleBitmap(planes[0], width, height)
                
                if (bitmap == null) {
                    Log.e(TAG, "Failed to create bitmap - bitmap is null")
                    return@execute
                }
                
                if (bitmap.isRecycled) {
                    Log.e(TAG, "Failed to create bitmap - bitmap is recycled")
                    return@execute
                }

                Log.d(TAG, "Bitmap created successfully: ${bitmap.width}x${bitmap.height}")

                // Mirror the bitmap if using front camera (for correct left/right hand detection)
                val processedBitmap = if (isFrontCamera) {
                    Log.d(TAG, "Mirroring bitmap for front camera")
                    mirrorBitmap(bitmap)
                } else {
                    bitmap
                }

                // Create MediaPipe image and process
                val mpImage = BitmapImageBuilder(processedBitmap).build()
                val frameTime = System.currentTimeMillis()

                Log.d(TAG, "Processing with MediaPipe...")

                // Process with MediaPipe
                val handResult = handLandmarker?.detect(mpImage)
                val poseResult = poseLandmarker?.detect(mpImage)

                Log.d(TAG, "MediaPipe results - Hands: ${handResult?.landmarks()?.size ?: 0}, Poses: ${poseResult?.landmarks()?.size ?: 0}")

                // Send all results (not just when landmarks exist)
                handResult?.let { sendHandLandmarks(it, frameTime) }
                poseResult?.let { sendPoseLandmarks(it, frameTime) }

                // Clean up immediately
                bitmap.recycle()
                if (processedBitmap != bitmap) {
                    processedBitmap.recycle()
                }

                // Force garbage collection periodically
                if (frameTime % 5000 < MIN_PROCESS_INTERVAL) {
                    System.gc()
                }

            } catch (e: Exception) {
                Log.e(TAG, "Error processing Flutter image: ${e.message}", e)
            } finally {
                isProcessing = false
            }
        }
    }

    // Simple bitmap creation that works reliably
    private fun createSimpleBitmap(
        planeData: Map<String, Any>,
        width: Int,
        height: Int
    ): android.graphics.Bitmap? {
        return try {
            val bytes = planeData["bytes"] as ByteArray
            val bytesPerPixel = (planeData["bytesPerPixel"] as? Int) ?: 4
            val bytesPerRow = (planeData["bytesPerRow"] as? Int) ?: (width * bytesPerPixel)
            
            Log.d(TAG, "Creating bitmap: ${width}x${height}, bytes: ${bytes.size}, bpp: $bytesPerPixel, bpr: $bytesPerRow")
            
            // Create bitmap with ARGB_8888 (MediaPipe compatible)
            val bitmap = android.graphics.Bitmap.createBitmap(
                width,
                height,
                android.graphics.Bitmap.Config.ARGB_8888
            )
            
            // Convert BGRA to ARGB format (simple, reliable approach)
            val pixels = IntArray(width * height)
            var pixelIndex = 0
            
            for (y in 0 until height) {
                val rowStart = y * bytesPerRow
                for (x in 0 until width) {
                    val byteIndex = rowStart + (x * bytesPerPixel)
                    
                    if (byteIndex + 3 < bytes.size) {
                        // BGRA8888 format: Blue, Green, Red, Alpha
                        val b = bytes[byteIndex].toInt() and 0xFF
                        val g = bytes[byteIndex + 1].toInt() and 0xFF
                        val r = bytes[byteIndex + 2].toInt() and 0xFF
                        val a = bytes[byteIndex + 3].toInt() and 0xFF
                        
                        // Create ARGB pixel
                        pixels[pixelIndex] = (a shl 24) or (r shl 16) or (g shl 8) or b
                    } else {
                        pixels[pixelIndex] = android.graphics.Color.BLACK
                    }
                    pixelIndex++
                }
            }
            
            bitmap.setPixels(pixels, 0, width, 0, 0, width, height)
            Log.d(TAG, "Bitmap created successfully: ${bitmap.width}x${bitmap.height}")
            bitmap
            
        } catch (e: Exception) {
            Log.e(TAG, "Error creating bitmap: ${e.message}")
            null
        }
    }

    // Mirror bitmap horizontally for front camera (so left hand appears on left side)
    private fun mirrorBitmap(original: android.graphics.Bitmap): android.graphics.Bitmap {
        return try {
            val matrix = android.graphics.Matrix().apply {
                preScale(-1.0f, 1.0f) // Flip horizontally
            }
            
            android.graphics.Bitmap.createBitmap(
                original,
                0,
                0,
                original.width,
                original.height,
                matrix,
                false
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error mirroring bitmap: ${e.message}")
            original // Return original if mirroring fails
        }
    }



    private fun sendHandLandmarks(result: HandLandmarkerResult, timestamp: Long) {
        val numHands = result.landmarks().size
        
        // Always log detection status for debugging
        if (timestamp % 2000 < MIN_PROCESS_INTERVAL) { // Log every ~2 seconds
            Log.d(TAG, "Hand detection: $numHands hand(s) detected")
        }

        // Always send results, even when no hands detected (for clearing overlay)
        val handsData = if (numHands > 0) {
            result.landmarks().map { hand ->
                hand.map { landmark ->
                    mapOf("x" to landmark.x(), "y" to landmark.y(), "z" to landmark.z())
                }
            }
        } else {
            emptyList() // Empty list clears the overlay
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
    }

    private fun sendPoseLandmarks(result: PoseLandmarkerResult, timestamp: Long) {
        val numPoses = result.landmarks().size
        
        // Always log detection status for debugging
        if (timestamp % 3000 < MIN_PROCESS_INTERVAL) { // Log every ~3 seconds
            Log.d(TAG, "Pose detection: $numPoses pose(s) detected")
        }

        // Always send results, even when no poses detected (for clearing overlay)
        val posesData = if (numPoses > 0) {
            result.landmarks().map { pose ->
                pose.map { landmark ->
                    mapOf("x" to landmark.x(), "y" to landmark.y(), "z" to landmark.z())
                }
            }
        } else {
            emptyList() // Empty list clears the overlay
        }
        
        activity.runOnUiThread {
            channel.invokeMethod(
                "onPoseLandmarks",
                mapOf(
                    "poses" to posesData, 
                    "timestamp" to timestamp,
                    "numPoses" to numPoses
                )
            )
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
        isProcessing = false
        
        handLandmarker?.close()
        poseLandmarker?.close()
        
        if (::backgroundExecutor.isInitialized) {
            backgroundExecutor.shutdown()
        }
        
        // Force garbage collection on stop
        System.gc()
        
        Log.d(TAG, "Detection stopped and memory cleaned up")
    }

    interface LandmarkerListener {
        fun onError(error: String, errorCode: Int = OTHER_ERROR)
        fun onHandResults(result: HandLandmarkerResult, inferenceTime: Long, height: Int, width: Int)
        fun onPoseResults(result: PoseLandmarkerResult, inferenceTime: Long, height: Int, width: Int)
    }
}