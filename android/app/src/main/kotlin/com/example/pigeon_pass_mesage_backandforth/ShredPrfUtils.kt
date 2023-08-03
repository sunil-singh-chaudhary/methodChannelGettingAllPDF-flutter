package com.example.pigeon_pass_mesage_backandforth

import android.content.Context
import android.content.SharedPreferences
import android.database.Cursor
import android.preference.PreferenceManager
import android.provider.MediaStore

class ShredPrfUtils {


    private fun saveDirectoryUri( uriString:String, context: Context) {
        var sharedPreferences:
        SharedPreferences = PreferenceManager.getDefaultSharedPreferences(context)
        sharedPreferences.edit().putString("SAVED_DIRECTORY_URI", uriString).apply()
    }

    private fun getSavedDirectoryUri(context: Context): String?
    {
        val sharedPreferences: SharedPreferences =
            PreferenceManager.getDefaultSharedPreferences(context)
        return sharedPreferences.getString("SAVED_DIRECTORY_URI", null)
    }


}