import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FileUtility {
  static const MethodChannel _channel =
      MethodChannel('com.sunil/pdfmethodChannel');
  static const EventChannel _pdfEventChannel = EventChannel(
      'com.sunil/pdfEventChannel'); //same event name in andriod if modified then change in android MainActivity too

  // Method to get all PDF files from device storage
  static getAllPDFFiles() async {
    if (Platform.isAndroid) {
      if (int.parse(Platform.version.split('.')[0]) >= 33) {
        _getPDFFilesUsingMediaStore();
      } else {
        _getPDFFilesUsingExternalStorage();
      }
    } else if (Platform.isIOS) {
      // Implement iOS file access if needed
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Method to get PDF files using MediaStore on Android 11 and above
  static _getPDFFilesUsingMediaStore() async {
    try {
      await _channel.invokeMethod('getAllPDFFiles');
    } on PlatformException catch (e) {
      debugPrint('Error getting PDF list: ${e.message}');
    }
  }

  // Method to get PDF files using getExternalStoragePublicDirectory on Android below 11
  static _getPDFFilesUsingExternalStorage() async {
    try {
      await _channel.invokeMethod('getPDFFilesFromExternalStorage');
    } on PlatformException catch (e) {
      debugPrint('Error getting PDF list: ${e.message}');
    }
  }

  static setPdfViewer(String selectedPdfPath) async {
    try {
      await _channel.invokeMethod('openPdf', {'pdfPath': selectedPdfPath});
    } on PlatformException catch (e) {
      debugPrint('Error getting PDF list: ${e.message}');
    }
  }

  static void listenForPdfList(
      {required Function(List<String> pdfList) callbackpdfList,
      required Function(List<String> filePathList) callbackfilePathList}) {
    debugPrint("Strt listning: ");

    _pdfEventChannel.receiveBroadcastStream().listen((dynamic data) {
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
