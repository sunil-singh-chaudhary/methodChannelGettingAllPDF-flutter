import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'fileUtils.dart';
import 'permissonHandler.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> pdfPaths = [];
  List<String> filePath = [];

  @override
  void initState() {
    super.initState();
    PermissionHandler.initPermissoinAndCallMethodChannel(
      iscallbackPermission: () {
        setState(() {
          refreshAndListen();
        });
      },
    );
  }

  void _getPDFFiles() async {
    await FileUtility.getAllPDFFiles();
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
              FileUtility.setPdfViewer(filePath[index]);
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

  void refreshAndListen() {
    _getPDFFiles();
    FileUtility.listenForPdfList(
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
