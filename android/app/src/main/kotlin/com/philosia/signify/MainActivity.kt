package com.philosia.signify

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Toast
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class MainActivity : FlutterActivity(), MethodCallHandler {

    private lateinit var channel: MethodChannel
    private var landmarkDetector: LandmarkDetector? = null

    companion object {
        private const val REQUEST_CODE_PERMISSIONS = 10
        private val REQUIRED_PERMISSIONS = arrayOf(Manifest.permission.CAMERA)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (!allPermissionsGranted()) {
            ActivityCompat.requestPermissions(this, REQUIRED_PERMISSIONS, REQUEST_CODE_PERMISSIONS)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mediapipe_plugin")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                try {
                    landmarkDetector = LandmarkDetector(this, channel)
                    landmarkDetector?.initialize()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("INIT_ERROR", "Failed to initialize: ${e.message}", null)
                }
            }

            "startDetection" -> {
                try {
                    landmarkDetector?.startDetection()
                    result.success("Detection started")
                } catch (e: Exception) {
                    result.error("START_ERROR", "Failed to start detection: ${e.message}", null)
                }
            }

            "stopDetection" -> {
                try {
                    landmarkDetector?.stopDetection()
                    result.success("Detection stopped")
                } catch (e: Exception) {
                    result.error("STOP_ERROR", "Failed to stop detection: ${e.message}", null)
                }
            }

            "processImage" -> {
                try {
                    landmarkDetector?.processImageFromFlutter(call.arguments as Map<String, Any>)
                    result.success("Image processed")
                } catch (e: Exception) {
                    result.error("PROCESS_ERROR", "Failed to process image: ${e.message}", null)
                }
            }

            else -> result.notImplemented()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        landmarkDetector?.stopDetection()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE_PERMISSIONS) {
            if (!allPermissionsGranted()) {
                Toast.makeText(this, "Permissions not granted by the user.", Toast.LENGTH_SHORT)
                    .show()
            }
        }
    }

    private fun allPermissionsGranted() = REQUIRED_PERMISSIONS.all {
        ContextCompat.checkSelfPermission(baseContext, it) == PackageManager.PERMISSION_GRANTED
    }
}
