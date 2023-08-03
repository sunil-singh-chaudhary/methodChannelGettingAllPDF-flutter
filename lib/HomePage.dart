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
              debugPrint('path-- ${pdfPaths[index]}');
              FileUtility.setPdfViewer(pdfPaths[index]);
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
    });

    _pdfEventChannel.receiveBroadcastStream().listen((dynamic pdfList) {
      if (pdfList is List<dynamic>) {
        List<String> stringList = pdfList.cast<String>();
        setState(() {
          pdfPaths = stringList;
        });
      } else {
        debugPrint('Error: Invalid PDF list format');
      }
    }, onError: (dynamic error) {
      debugPrint('Error receiving PDF list: $error');
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
