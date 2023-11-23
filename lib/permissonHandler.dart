import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerWrapper {
  Future<bool> requestStoragePermission(Permission permission) async {
    // Check if the permission is already granted
    var status = await permission.status;

    if (!status.isGranted) {
      // If the permission is not granted, request it
      status = await permission.request();
      return Future.value(true);
    }

    // Handle the permission status HERE FOR STORAGE is SUNIL
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
}
