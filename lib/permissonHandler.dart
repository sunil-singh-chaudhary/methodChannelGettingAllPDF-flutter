import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  Future<bool> requestStoragePermission() async {
    // Check if the permission is already granted
    var status = await Permission.storage.status;

    if (!status.isGranted) {
      // If the permission is not granted, request it
      status = await Permission.storage.request();
      return Future.value(true);
    }

    // Handle the permission status
    if (status.isGranted) {
      // Permission granted
      debugPrint("Storage permission is granted.");
      return Future.value(true);
    } else {
      // Permission denied
      debugPrint("Storage permission is denied.");
      return Future.value(false);
    }
  }

  initPermissoinAndCallMethodChannel(
      {required Function() iscallbackPermission}) async {
    PermissionHandler handler = PermissionHandler();

    bool isPermission = await handler.requestStoragePermission();
    if (isPermission) {
      iscallbackPermission();
    } else {
      debugPrint('dont have permission');
    }
  }
}
