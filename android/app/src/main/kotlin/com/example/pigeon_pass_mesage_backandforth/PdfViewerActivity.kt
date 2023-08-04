package com.example.pigeon_pass_mesage_backandforth
import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.widget.EditText
import android.widget.Toolbar
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.github.barteksc.pdfviewer.PDFView;
import com.github.barteksc.pdfviewer.listener.OnErrorListener
import com.github.barteksc.pdfviewer.listener.OnPageErrorListener


class PdfViewerActivity : AppCompatActivity() , OnPageErrorListener,OnErrorListener{
    private var currentPassword: String? = null // Store the PDF password

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_pdf_viewer)
        setToolBar()
        currentPassword=null
        reloadPdfViewerWithPassword(this.currentPassword) //show password

    }

    private fun setToolBar() {
        val fileNamee = intent.getStringExtra("pdfFileName")
        val toolbar: androidx.appcompat.widget.Toolbar = findViewById(R.id.my_toolbar)
        setSupportActionBar(toolbar)
        supportActionBar?.title = fileNamee

    }

    override fun onPageError(page: Int, t: Throwable?) {
        Log.e( "Cannot load page ",  page.toString())
        if (t != null) {
            Log.e( "error load page ",  t.message.toString())
        }
    }
    override fun onError(t: Throwable?) {
        Log.e( "onError  ",  t!!.message.toString())
        val comparePswd="Password required or incorrect password.";
        if (comparePswd.equals(t.message.toString())){
            showPasswordDialog(this,)

        }
    }
    private fun showPasswordDialog(context: Context) {
        val dialogView = layoutInflater.inflate(R.layout.dialog_password, null)
        val passwordEditText = dialogView.findViewById<EditText>(R.id.passwordEditText)

        val alertDialog = AlertDialog.Builder(context)
            .setTitle("Enter Password")
            .setView(dialogView)
            .setPositiveButton("Submit") { _, _ ->
                val password = passwordEditText.text.toString()
                currentPassword = password
                reloadPdfViewerWithPassword(currentPassword!!)

            }
            .setNegativeButton("Cancel", null)
            .create()

        alertDialog.show()
    }
    private fun reloadPdfViewerWithPassword(password: String?) {
        val pdfView: PDFView = findViewById(R.id.pdfView)
        val filePath = intent.getStringExtra("pdfFilePath")

        filePath?.let {
            pdfView.fromUri(Uri.parse(it))
                .password(password) // Set the new password
                .onPageError(this)
                .onError(this)
                .load()
        }
    }

}
