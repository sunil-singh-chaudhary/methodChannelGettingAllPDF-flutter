import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'fileUtils.dart';
import 'listviewwidget.dart';
import 'permissonHandler.dart';
import 'platformwrapper.dart';

class HomePage extends StatefulWidget {
  PlatformWrapperChecker wrapper;
  HomePage({Key? key, required this.wrapper}) : super(key: key);

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  var fileutils = FileUtility();
  List<String> pdfPaths = [];
  List<String> filePath = [];
  PermissionHandlerWrapper handler = PermissionHandlerWrapper();
  @override
  void initState() {
    super.initState();
    requestPermissionAndRefresh();
  }

  requestPermissionAndRefresh() async {
    Permission permission = Permission.storage;
    bool isPermission = await handler.requestStoragePermission(permission);
    if (isPermission) {
      setState(() {
        refreshAndListen();
      });
    } else {
      debugPrint('Permission not granted');
    }
  }

  void getPDFFiles() async {
    await fileutils.getAllPDFFiles(widget.wrapper);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Files'),
        actions: [
          IconButton(
            icon: const Icon(
                Icons.document_scanner), // Replace with your desired icon
            onPressed: () {
              refreshAndListen();
            },
          ),
        ],
      ),
      body: ListViewWidget(pdfPaths: pdfPaths, filePath: filePath, fileutils: fileutils),
    );
  }

  refreshAndListen() {
    getPDFFiles();
    listenPDF();
  }

  listenPDF() {
    fileutils.listenForPdfList(
      callbackpdfList: (pdfList) {
        setState(() {
          pdfPaths = pdfList;
        });
      },
      callbackfilePathList: (filePathList) {
        setState(() {
          filePath = filePathList;
        });
      },
    );
  }
}

