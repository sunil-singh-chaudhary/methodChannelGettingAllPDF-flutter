
import 'package:flutter/material.dart';
import 'package:pigeon_pass_mesage_backandforth/fileUtils.dart';

class ListViewWidget extends StatelessWidget {
  const ListViewWidget({
    super.key,
    required this.pdfPaths,
    required this.filePath,
    required this.fileutils,
  });

  final List<String> pdfPaths;
  final List<String> filePath;
  final FileUtility fileutils;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
    );
  }
}