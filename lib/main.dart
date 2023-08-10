import 'package:flutter/material.dart';
import 'package:pigeon_pass_mesage_backandforth/platformwrapper.dart';

import 'HomePage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    PlatformWrapperChecker wrapperPlatform = PlatformWrapperChecker();

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(wrapper: wrapperPlatform),
    );
  }
}
