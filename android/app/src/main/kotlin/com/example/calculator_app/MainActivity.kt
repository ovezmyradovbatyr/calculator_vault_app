package com.example.calculator_app

import android.app.Activity
import android.app.AppOpsManager
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Process
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.calculator_app/media"
    private val DELETE_REQUEST_CODE = 1001
    private var pendingDeleteResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanFile" -> {
                        val path = call.argument<String>("path")
                        if (path != null) {
                            MediaScannerConnection.scanFile(
                                this, arrayOf(path), null
                            ) { _, _ -> }
                            result.success(null)
                        } else {
                            result.error("INVALID_ARG", "path is null", null)
                        }
                    }
                    "deleteFromMediaStore" -> {
                        val uriStr = call.argument<String>("uri")
                        if (uriStr == null) {
                            result.error("INVALID_ARG", "uri is null", null)
                            return@setMethodCallHandler
                        }
                        deleteMediaByUri(uriStr, result)
                    }
                    "deleteByFilePath" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("INVALID_ARG", "path is null", null)
                            return@setMethodCallHandler
                        }
                        deleteMediaByFilePath(path, result)
                    }
                    "deleteByDisplayName" -> {
                        val name = call.argument<String>("name")
                        if (name == null) {
                            result.error("INVALID_ARG", "name is null", null)
                            return@setMethodCallHandler
                        }
                        deleteMediaByDisplayName(name, result)
                    }
                    "hasManageMedia" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val ops = getSystemService(APP_OPS_SERVICE) as AppOpsManager
                            val mode = ops.unsafeCheckOpNoThrow(
                                "android:manage_media",
                                Process.myUid(),
                                packageName
                            )
                            result.success(mode == AppOpsManager.MODE_ALLOWED)
                        } else {
                            result.success(false)
                        }
                    }
                    "requestManageMedia" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val intent = Intent(Settings.ACTION_REQUEST_MANAGE_MEDIA)
                            intent.data = Uri.fromParts("package", packageName, null)
                            startActivity(intent)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun deleteMediaByUri(uriStr: String, result: MethodChannel.Result) {
        try {
            val uri = Uri.parse(uriStr)
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> {
                    // Android 11+ – requires system confirmation dialog
                    pendingDeleteResult = result
                    val req = MediaStore.createDeleteRequest(contentResolver, listOf(uri))
                    startIntentSenderForResult(req.intentSender, DELETE_REQUEST_CODE, null, 0, 0, 0)
                }
                Build.VERSION.SDK_INT == Build.VERSION_CODES.Q -> {
                    // Android 10 – may throw RecoverableSecurityException for files from other apps
                    try {
                        val rows = contentResolver.delete(uri, null, null)
                        result.success(rows > 0)
                    } catch (e: android.app.RecoverableSecurityException) {
                        pendingDeleteResult = result
                        startIntentSenderForResult(
                            e.userAction.actionIntent.intentSender,
                            DELETE_REQUEST_CODE,
                            null, 0, 0, 0
                        )
                    }
                }
                else -> {
                    // Android 9 and below – direct delete
                    val rows = contentResolver.delete(uri, null, null)
                    result.success(rows > 0)
                }
            }
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun deleteMediaByDisplayName(displayName: String, result: MethodChannel.Result) {
        try {
            val collections = listOf(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            )
            for (collection in collections) {
                val projection = arrayOf(MediaStore.MediaColumns._ID)
                val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} = ?"
                val cursor = contentResolver.query(
                    collection, projection, selection, arrayOf(displayName), null
                )
                cursor?.use {
                    if (it.moveToFirst()) {
                        val id = it.getLong(it.getColumnIndexOrThrow(MediaStore.MediaColumns._ID))
                        val uri = Uri.withAppendedPath(collection, id.toString())
                        deleteMediaByUri(uri.toString(), result)
                        return
                    }
                }
            }
            result.success(false)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun deleteMediaByFilePath(filePath: String, result: MethodChannel.Result) {
        try {
            // Search all external media collections for the file
            val collections = listOf(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            )
            for (collection in collections) {
                val projection = arrayOf(MediaStore.MediaColumns._ID)
                val selection = "${MediaStore.MediaColumns.DATA} = ?"
                val cursor = contentResolver.query(
                    collection, projection, selection, arrayOf(filePath), null
                )
                cursor?.use {
                    if (it.moveToFirst()) {
                        val id = it.getLong(it.getColumnIndexOrThrow(MediaStore.MediaColumns._ID))
                        val uri = Uri.withAppendedPath(collection, id.toString())
                        deleteMediaByUri(uri.toString(), result)
                        return
                    }
                }
            }
            // Not found in MediaStore
            result.success(false)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == DELETE_REQUEST_CODE) {
            pendingDeleteResult?.success(resultCode == Activity.RESULT_OK)
            pendingDeleteResult = null
        }
    }
}
