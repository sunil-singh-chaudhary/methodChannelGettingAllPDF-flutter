package com.example.pigeon_pass_mesage_backandforth;

import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import java.util.HashMap;
import java.util.Map;

public class OpenPdf {
   static public Map<String, Object> getModelAsMap(Model model) {
        Map<String, Object> map = new HashMap<>();
        map.put("filenameList", model.getFilenameList());
        map.put("filePathList", model.getFilePathList());
        return map;
    }

    //SHOW PDF
//    static void ShowPDf(Context context, String pathpdf){
//        context.startActivity(
//                PdfViewerActivity.Companion.launchPdfFromPath(
//                        context,
//                        pathpdf,
//                        "Title",  "",
//                        true,
//                        false)
//        );
//    }
//  Convert content URi to Absolute Path ans show in pdf then

public static String getPathFromContentUri(Context context, Uri contentUri) {
    String filePath = null;
    Cursor cursor = null;
    try {
        String[] projection = {DocumentsContract.Document.COLUMN_DOCUMENT_ID};
        cursor = context.getContentResolver().query(contentUri, projection, null, null, null);
        if (cursor != null && cursor.moveToFirst()) {
            String documentId = cursor.getString(cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID));
            if (documentId != null) {
                String[] parts = documentId.split(":");
                String id = parts[parts.length - 1]; // Get the last part
                String selection = MediaStore.Files.FileColumns._ID + " = ?";
                String[] selectionArgs = {id};
                String[] projectionData = {MediaStore.Files.FileColumns.DATA};
                Cursor dataCursor = context.getContentResolver().query(MediaStore.Files.getContentUri("external"), projectionData, selection, selectionArgs, null);
                if (dataCursor != null && dataCursor.moveToFirst()) {
                    filePath = dataCursor.getString(dataCursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATA));
                }
                if (dataCursor != null) {
                    dataCursor.close();
                }
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (cursor != null) {
            cursor.close();
        }
    }
    return filePath;
}




}


