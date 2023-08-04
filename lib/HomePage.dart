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

  static const EventChannel _pdfEventChannel =
      EventChannel('com.sunil/pdfEventChannel');

  @override
  void initState() {
    super.initState();
    initPermissoinAndCallMethodChannel();
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
              setState(() {
                pdfPaths = [];
                filePath = [];
              });
              _getPDFFiles();
              listenForPdfList();
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

  void listenForPdfList() {
    setState(() {
      pdfPaths = [];
      filePath = [];
    });

    _pdfEventChannel.receiveBroadcastStream().listen((dynamic data) {
      debugPrint("Data type: ${data.runtimeType}");

      if (data is Map<dynamic, dynamic>) {
        List<String> pdfList = List<String>.from(data['filenameList']);
        List<String> filePathList = List<String>.from(data['filePathList']);
        debugPrint('filePathList: $filePath');
        debugPrint('pdfList: $pdfPaths');

        setState(() {
          pdfPaths = pdfList;
          filePath = filePathList;
        });
      } else {
        debugPrint('Error: Invalid PDF data format');
      }
    }, onError: (dynamic error) {
      debugPrint('Error receiving PDF data: $error');
    });
  }

  void initPermissoinAndCallMethodChannel() async {
    bool isPermission = await PermissionHandler.requestStoragePermission();
    if (isPermission) {
      setState(() {
        pdfPaths = [];
      });

      _getPDFFiles();
      listenForPdfList();
    } else {
      debugPrint('dont have permission');
    }
  }
}
