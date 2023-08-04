package com.example.pigeon_pass_mesage_backandforth


data class Model(val filenameList: MutableList<String>, val filePathList: MutableList<String>) {

    fun addFilename(filename: String) {
        filenameList.add(filename)
    }

    fun addFilePath(filePath: String) {
        filePathList.add(filePath)
    }
    fun clearListModel() {
        filePathList.clear()
        filenameList.clear()
    }



}
