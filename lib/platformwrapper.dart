import 'dart:io';

class PlatformWrapperChecker {
  bool isAndroid() {
    return Platform.isAndroid;
  }

  int getAndroidSdkVersion() {
    return int.parse(Platform.version.split('.')[0]);
  }
}
