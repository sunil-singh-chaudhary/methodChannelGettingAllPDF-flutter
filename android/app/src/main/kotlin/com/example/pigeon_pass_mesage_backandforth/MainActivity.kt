package  com.example.pigeon_pass_mesage_backandforth
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.documentfile.provider.DocumentFile
import com.kaopiz.kprogresshud.KProgressHUD
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
    private lateinit var eventChannel: EventChannel
    val pdfListStreamHandler = PdfListStreamHandler()
    lateinit var pdfsearchList : PdfSearchService
    private var hud: KProgressHUD? = null

    companion object {
        private const val METHOD_CHANNEL = "com.sunil/pdfmethodChannel"
        private const val EVENT_CHANNEL = "com.sunil/pdfEventChannel"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pdfsearchList = PdfSearchService() // Initialize the property with an instance

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
                        val fileNamee=this@MainActivity.pdfsearchList.getFileName(MainActivity@this,Uri.parse(Path))


                        var actualPath = pdfsearchList.getRealPath(context, Uri.parse(Path))
                        //using actual path can convert uri to string when needed here dont need it work on Uri
                        //direactly

                        val intent = Intent(this, PdfViewerActivity::class.java)
                        intent.putExtra("pdfFilePath", Path)
                        intent.putExtra("pdfFileName", fileNamee)

                        startActivity(intent)
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
        fun sendPdfList(context: Context,pdfListsModel: Model) {
           var mapTosend= OpenPdf.getModelAsMap( Model(ArrayList(pdfListsModel.filenameList), ArrayList(pdfListsModel.filePathList)))
            Log.e("pdfListCopy", " $mapTosend")
            MainScope().launch {
                eventSink?.success(mapTosend)
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
        val pdfList =Model(ArrayList(), ArrayList())

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // For Android 10 (API level 29) and above, use SAF
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
            startActivityForResult(intent, REQUEST_CODE_SAF_PERMISSION)
        } else {
            // For Android 9 (API level 28) and below, use deprecated method
            val directory = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            traverseDirectoryForPDFFiles(directory, pdfList)
        }

    }


    @RequiresApi(Build.VERSION_CODES.KITKAT)
    private fun traverseDirectoryForPDFFiles(directory: File, pdfList: Model) {
        if (directory.isDirectory) {
            val files = directory.listFiles()
            if (files != null) {
                for (file in files) {
                    if (file.isDirectory) {
                        traverseDirectoryForPDFFiles(file, pdfList)
                    } else if (file.isFile && file.name.lowercase(Locale.getDefault()).endsWith(".pdf")) {
                        pdfList.addFilePath(file.absolutePath)
                        pdfList.addFilename(file.name)

                    }
                }
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun traverseDirectoryForPDFFiles(directoryUri: Uri, pdfLists: Model) {
        val contentResolver = contentResolver

        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(directoryUri, DocumentsContract.getDocumentId(directoryUri))
        contentResolver.query(childrenUri, arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_MIME_TYPE), null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) {
                val documentId = cursor.getString(0)
                val mimeType = cursor.getString(1)
                if (mimeType == "application/pdf") {
                    val documentUri = DocumentsContract.buildDocumentUriUsingTree(directoryUri, documentId)
//                    pdfList.add(documentUri.toString())
                    val fileNamee=this@MainActivity.pdfsearchList.getFileName(MainActivity@this,documentUri)

                    pdfLists.addFilename(fileNamee!!)
                    pdfLists.addFilePath(documentUri.toString()!!)
                    pdfListStreamHandler.sendPdfList(MainActivity@this,pdfLists)

                } else if (DocumentsContract.Document.MIME_TYPE_DIR == mimeType) {
                    val childUri = DocumentsContract.buildChildDocumentsUriUsingTree(directoryUri, documentId)
                    traverseDirectoryForPDFFiles(childUri, pdfLists)
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

                    hud = KProgressHUD.create(this)
                        .setStyle(KProgressHUD.Style.SPIN_INDETERMINATE).show()
                    var tempList = Model(ArrayList(), ArrayList())

                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            val pdfListDeferred = async(Dispatchers.IO) {
                                 tempList = Model(ArrayList(), ArrayList()) // Create a new Model instance
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    traverseDirectoryForPDFFiles(directory.uri, tempList)
                                } else {
                                    traverseDirectoryForPDFFiles(File(uri.path!!), tempList)
                                }
                                tempList
                            }
                            tempList.clearListModel()
                            val pdfListsModel = pdfListDeferred.await()
                            hud?.dismiss()
//                            val pdfLists = PdfLists(pdfList, emptyList()) // Empty second list for now
                            pdfListStreamHandler.sendPdfList(this@MainActivity, pdfListsModel)
                        } catch (e: Exception) {
                            hud?.dismiss()

                            e.printStackTrace()
                        } finally {
                            hud?.dismiss()
                        }
                    }
                }
            }
        }
    }


}
