import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pigeon_pass_mesage_backandforth/platformwrapper.dart';

class FileUtility {
  var methodchannel = const MethodChannel('com.sunil/pdfmethodChannel');
  var pdfEventChannel = const EventChannel('com.sunil/pdfEventChannel');

  //same event name in andriod if modified then change in android MainActivity too
  Future<int> getAndroidSdkVersion() async {
    final version = await const MethodChannel('com.sunil.androidVersion')
        .invokeMethod<int>('getAndroidSdkVersion');
    return version ?? 0; // Default value or handle appropriately
  }

  // Method to get all PDF files from device storage
  getAllPDFFiles(PlatformWrapperChecker wrapperPlatform) async {
    if (wrapperPlatform.isAndroid()) {
      if (wrapperPlatform.getAndroidSdkVersion() >= 33) {
        getPDFFilesUsingMediaStore();
      } else {
        getPDFFilesUsingExternalStorage();
      }
    } else if (Platform.isIOS) {
      // Implement iOS file access if needed
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Method to get PDF files using MediaStore on Android 11 and above
  getPDFFilesUsingMediaStore() async {
    try {
      await methodchannel.invokeMethod('getAllPDFFiles');
    } on PlatformException catch (e) {
      debugPrint('Error getting PDF list: ${e.message}');
    }
  }

  // Method to get PDF files using getExternalStoragePublicDirectory on Android below 11
  getPDFFilesUsingExternalStorage() async {
    try {
      await methodchannel.invokeMethod('getPDFFilesFromExternalStorage');
    } on PlatformException catch (e) {
      debugPrint('Error getting PDF list: ${e.message}');
    }
  }

  setPdfViewer(String selectedPdfPath) async {
    try {
      await methodchannel.invokeMethod('openPdf', {'pdfPath': selectedPdfPath});
    } on PlatformException catch (e) {
      debugPrint('Error getting PDF list: ${e.message}');
    }
  }

  listenForPdfList(
      {required Function(List<String> pdfList) callbackpdfList,
      required Function(List<String> filePathList) callbackfilePathList}) {
    pdfEventChannel.receiveBroadcastStream().listen((dynamic data) {
      debugPrint("Data type: ${data.runtimeType}");

      if (data is Map<dynamic, dynamic>) {
        List<String> pdfList = List<String>.from(data['filenameList']);
        List<String> filePathList = List<String>.from(data['filePathList']);

        callbackpdfList(pdfList);
        callbackfilePathList(filePathList);
      } else {
        debugPrint('Error: Invalid PDF data format');
      }
    }, onError: (dynamic error) {
      debugPrint('Error receiving PDF data: $error');
    });
  }
}
