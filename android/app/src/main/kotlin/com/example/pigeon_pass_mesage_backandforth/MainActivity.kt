package  com.example.pigeon_pass_mesage_backandforth
import android.app.Activity
import android.app.ProgressDialog
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.preference.PreferenceManager
import android.provider.DocumentsContract
import androidx.documentfile.provider.DocumentFile
import android.provider.MediaStore
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import java.io.File
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val REQUEST_CODE_SAF_PERMISSION = 101
    private val pdfList = ArrayList<String>()
    private lateinit var eventChannel: EventChannel
    val pdfListStreamHandler = PdfListStreamHandler()

    companion object {
        private const val METHOD_CHANNEL = "com.sunil/pdfmethodChannel"
        private const val EVENT_CHANNEL = "com.sunil/pdfEventChannel"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "getAllPDFFiles" -> {
                        pDFFilesUsingMediaStore()
                    }
                    "getPDFFilesFromExternalStorage" -> {
                        getPDFFilesFromAllAccessibleDirectories()
                    }
                    "openPdf" -> {
                        val Path = call.argument<String>("pdfPath")
                        Log.e( "absolute path: ", Path.toString())
                        OpenPdf.ShowPDf(MainActivity@this,Path)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        // Set up the EventChannel
        eventChannel= EventChannel(flutterEngine!!.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(pdfListStreamHandler)

    }

    class PdfListStreamHandler : EventChannel.StreamHandler {
        private var eventSink: EventChannel.EventSink? = null

        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            eventSink = events
        }
        override fun onCancel(arguments: Any?) {
            eventSink = null
        }
        fun sendPdfList(context: Context,pdfList: List<String>) {
//            val filePathList = ArrayList<String>()
//
//            for (uriString in pdfList) {
//                val uri = Uri.parse(uriString)
//                val actualPath = OpenPdf.getPathFromContentUri(context, uri)
//                if (actualPath != null) {
//                    filePathList.add(actualPath)
//                } else {
//                    Log.e("sendPdfList", "Could not convert URI to file path: $uriString")
//                }
//            }
            val pdfListCopy = ArrayList(pdfList)

            MainScope().launch {
                eventSink?.success(pdfListCopy)
            }
        }

    }

    private fun pDFFilesUsingMediaStore(){
        val pdfList = ArrayList<String>()
        val projection = arrayOf(
            MediaStore.Files.FileColumns.DATA
        )
        val selection = MediaStore.Files.FileColumns.MIME_TYPE + " = ?"
        val mimeType = "application/pdf"
        val selectionArgs = arrayOf(mimeType)
        try {
            contentResolver.query(
                MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
                projection,
                selection,
                selectionArgs,
                null
            ).use { cursor ->
                if (cursor != null && cursor.moveToFirst()) {
                    val columnData =
                        cursor.getColumnIndex(MediaStore.Files.FileColumns.DATA)
                    do {
                        pdfList.add(cursor.getString(columnData))
                    } while (cursor.moveToNext())
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun getPDFFilesFromAllAccessibleDirectories()
    {
        val pdfList = ArrayList<String>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // For Android 10 (API level 29) and above, use SAF
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
            startActivityForResult(intent, REQUEST_CODE_SAF_PERMISSION)
        } else {
            // For Android 9 (API level 28) and below, use deprecated method
            val directory = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            traverseDirectoryForPDFFiles(directory, pdfList)
        }
        Log.e("pdf return-->: ", pdfList.toString())

    }


    @RequiresApi(Build.VERSION_CODES.KITKAT)
    private fun traverseDirectoryForPDFFiles(directory: File, pdfList: ArrayList<String>) {
        if (directory.isDirectory) {
            val files = directory.listFiles()
            if (files != null) {
                for (file in files) {
                    if (file.isDirectory) {
                        traverseDirectoryForPDFFiles(file, pdfList)
                    } else if (file.isFile && file.name.lowercase(Locale.getDefault()).endsWith(".pdf")) {
                        pdfList.add(file.absolutePath)
                    }
                }
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun traverseDirectoryForPDFFiles(directoryUri: Uri, pdfList: ArrayList<String>) {
        val contentResolver = contentResolver
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(directoryUri, DocumentsContract.getDocumentId(directoryUri))
        contentResolver.query(childrenUri, arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_MIME_TYPE), null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) {
                val documentId = cursor.getString(0)
                val mimeType = cursor.getString(1)
                if (mimeType == "application/pdf") {
                    val documentUri = DocumentsContract.buildDocumentUriUsingTree(directoryUri, documentId)
                    pdfList.add(documentUri.toString())
                    pdfListStreamHandler.sendPdfList(MainActivity@this,pdfList)

                } else if (DocumentsContract.Document.MIME_TYPE_DIR == mimeType) {
                    val childUri = DocumentsContract.buildChildDocumentsUriUsingTree(directoryUri, documentId)
                    traverseDirectoryForPDFFiles(childUri, pdfList)
                }
            }
        }
    }


    // Inside your activity's onActivityResult function
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_CODE_SAF_PERMISSION && resultCode == Activity.RESULT_OK) {
            val uri: Uri? = data?.data
            if (uri != null) {
                // Now you have access to the selected directory via SAF
                val directory = DocumentFile.fromTreeUri(this, uri)
                if (directory != null && directory.isDirectory) {
                    pdfList.clear() // Clear the previous list before adding new items

                    val progressDialog = ProgressDialog.show(this, "Please wait", "Loading...")
                    progressDialog.setCancelable(false)

                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            val pdfListDeferred = async(Dispatchers.IO) {
                                val tempList = ArrayList<String>()
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    traverseDirectoryForPDFFiles(directory.uri, tempList)
                                } else {
                                    traverseDirectoryForPDFFiles(File(uri.path!!), tempList)
                                }
                                tempList
                            }

                            pdfList.clear()
                            pdfList.addAll(pdfListDeferred.await())

//                            val pdfLists = PdfLists(pdfList, emptyList()) // Empty second list for now
                            pdfListStreamHandler.sendPdfList(this@MainActivity, pdfList)
                        } catch (e: Exception) {
                            e.printStackTrace()
                        } finally {
                            progressDialog.dismiss() // Hide the progress bar
                        }
                    }
                }
            }
        }
    }


}
