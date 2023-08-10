import 'package:flutter/material.dart';
import 'fileUtils.dart';
import 'permissonHandler.dart';
import 'platformwrapper.dart';

class HomePage extends StatefulWidget {
  PlatformWrapperChecker wrapper;
  HomePage({Key? key, required this.wrapper}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var fileutils = FileUtility();
  List<String> pdfPaths = [];
  List<String> filePath = [];
  PermissionHandler handler = PermissionHandler();
  bool _isPermissionGranted = false;
  @override
  void initState() {
    super.initState();
    requestPermissionAndRefresh();
  }

  Future<void> requestPermissionAndRefresh() async {
    bool isPermission = await handler.requestStoragePermission();
    if (isPermission) {
      setState(() {
        _isPermissionGranted = true;
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
      body: ListView.builder(
        itemCount: pdfPaths.length,
        itemBuilder: (context, index) {
          return ListTile(
            onTap: () {
              debugPrint('filePath-- ${filePath[index]}');
              fileutils.setPdfViewer(filePath[index]);
            },
            leading: Text(
              "$index",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            title: Text(pdfPaths[index]),
          );
        },
      ),
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
