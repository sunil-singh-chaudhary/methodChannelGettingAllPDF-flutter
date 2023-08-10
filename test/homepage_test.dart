import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pigeon_pass_mesage_backandforth/HomePage.dart';
import 'package:pigeon_pass_mesage_backandforth/fileUtils.dart';
import 'package:pigeon_pass_mesage_backandforth/permissonHandler.dart';
import 'package:pigeon_pass_mesage_backandforth/platformwrapper.dart';

class MockMethodChannel extends Mock implements MethodChannel {}

class MockEventChannel extends Mock implements EventChannel {}

class MockPlatformWrapper extends Mock implements PlatformWrapperChecker {}

class MockPermissionHandler extends Mock implements PermissionHandler {}

void main() {
  late MockMethodChannel mockMethodChannel;
  late MockEventChannel mockEventChannel;
  late FileUtility utils;
  late MockPlatformWrapper platformWrapper;
  late MockPermissionHandler permissonMock;
  late PermissionHandler permissionHandler;

  setUp(() {
    mockMethodChannel = MockMethodChannel();
    mockEventChannel = MockEventChannel();
    utils = FileUtility();
    permissionHandler = PermissionHandler();
    platformWrapper = MockPlatformWrapper();
    permissonMock = MockPermissionHandler();

    utils.methodchannel = mockMethodChannel; //update methodchannel with mock
    utils.pdfEventChannel = mockEventChannel;

    when(() => mockMethodChannel.invokeMethod('getAllPDFFiles'))
        .thenAnswer((_) async => null); // Returning null here

    when(() => mockMethodChannel.invokeMethod('getPDFFilesFromExternalStorage'))
        .thenAnswer((_) async => null); // Returning null here
  });
  tearDown(() {
    // Reset mock states
    reset(mockMethodChannel);
    reset(mockEventChannel);
    reset(permissonMock);
    reset(platformWrapper);

    // Release any resources, if necessary
  });
  testWidgets("android or IOS and sdk verison", (tester) async {
    when(() => platformWrapper.isAndroid()).thenReturn(true);

    when(() => platformWrapper.getAndroidSdkVersion())
        .thenReturn(30); // Replace with the desired Android SDK version

    await tester.pumpWidget(MaterialApp(
      home: HomePage(wrapper: platformWrapper),
    )); // Replace with your widget instantiation

    // Call the public method to fetch PDF files
    await tester.runAsync(() async {
      await tester.tap(find.byType(IconButton));
      // Replace with how you trigger the method
      await tester.pumpAndSettle(); // Wait for the UI to update

      // Verify the expected method calls based on the Android version
      verify(() => platformWrapper.isAndroid()).called(1);
      verify(() => platformWrapper.getAndroidSdkVersion()).called(1);

      // ... add more verifications based on your logic
      await utils.getAllPDFFiles(platformWrapper);

      final sdkVersion = platformWrapper.getAndroidSdkVersion();

      //so we can verifiy it like this too because the method returning null

      // if (sdkVersion >= 33) {
      //   await expectLater(utils.getPDFFilesUsingMediaStore(),
      //       completion(equals(null)), // Expect a completion with null value
      //       reason: "Called Mediastore"
      //       );
      // } else {
      //   await expectLater(utils.getPDFFilesUsingExternalStorage(),
      //       completion(equals(null)), // Expect a completion with null value

      //       reason: "Called EXTERNAL STORAGE"
      //       );
      // }

      //or wecan also verify it with method channel becuause when calling [MethodChannel] it invoke
      //the method

      if (sdkVersion >= 33) {
        verify(() => mockMethodChannel.invokeMethod('getAllPDFFiles'))
            .called(1);
        verifyNever(() =>
            mockMethodChannel.invokeMethod('getPDFFilesFromExternalStorage'));
      } else {
        verify(() => mockMethodChannel
            .invokeMethod('getPDFFilesFromExternalStorage')).called(1);
        verifyNever(() => mockMethodChannel.invokeMethod('getAllPDFFiles'));
      }
    });
  });

  group("Permissoin Handling", () {
    testWidgets("Test permission handling when permission is granted",
        (tester) async {
      when(() => permissonMock.requestStoragePermission())
          .thenAnswer((_) => Future.value(true));

      await tester.pumpWidget(MaterialApp(
          home: HomePage(
        wrapper: platformWrapper,
      )));

      bool callbackInvoked = false;

      // Verify that permission was requested
      // verify(() => permissionHandler.requestStoragePermission()).called(1);

      await permissionHandler.initPermissoinAndCallMethodChannel(
        iscallbackPermission: () {
          callbackInvoked = true;
        },
      );

      expectLater(callbackInvoked, isTrue);
    });
    // testWidgets("Test permission handling when permission is not granted",
    //     (tester) async {
    //   when(() => permissonMock.requestStoragePermission())
    //       .thenAnswer((_) => Future.value(false));

    //   final permissionHandler = PermissionHandler();

    //   bool callbackInvoked = true;

    //   await permissionHandler.initPermissoinAndCallMethodChannel(
    //     iscallbackPermission: () {
    //       callbackInvoked = false;
    //     },
    //   );

    //   expect(callbackInvoked, isTrue);
    // });
  });

  testWidgets("Test getPDFFilesUsingExternalStorage() on Android SDK < 33",
      (tester) async {
    // Set up the mock behavior for the getPDFFilesUsingExternalStorage method
    when(() => mockMethodChannel.invokeMethod('getPDFFilesFromExternalStorage'))
        .thenAnswer((_) async => null);

    // Trigger the method under test
    await utils.getPDFFilesUsingExternalStorage();

    // Verify that the correct method was called
    verify(() =>
            mockMethodChannel.invokeMethod('getPDFFilesFromExternalStorage'))
        .called(1);
  });

  testWidgets("Test getPDFFilesUsingMediaStore() on Android SDK > 33",
      (tester) async {
    // Set up the mock behavior for the getPDFFilesUsingExternalStorage method
    when(() => mockMethodChannel.invokeMethod('getAllPDFFiles'))
        .thenAnswer((_) async => null);

    // Trigger the method under test
    await utils.getPDFFilesUsingMediaStore();

    // Verify that the correct method was called
    verify(() => mockMethodChannel.invokeMethod('getAllPDFFiles')).called(1);
  });

  testWidgets("Test onLIsten from android", (WidgetTester tester) async {
    // Prepare mock data to simulate the method channel broadcast
    final mockPdfData = {
      'filenameList': ['pdf1.pdf', 'pdf2.pdf'],
      'filePathList': ['/path/to/pdf1', '/path/to/pdf2'],
    };

    // Mock the method channel broadcast stream
    final mockStream = Stream<dynamic>.fromIterable([mockPdfData]);

    // Mock the event channel
    when(() => mockEventChannel.receiveBroadcastStream())
        .thenAnswer((_) => mockStream);

    await tester.pumpWidget(
      MaterialApp(home: HomePage(wrapper: platformWrapper)),
    );

    // Find the IconButton in the AppBar
    final iconButtonFinder = find.byType(IconButton);
    expect(iconButtonFinder, findsOneWidget);

    // Trigger the button click to call _listenPDF
    await tester.tap(iconButtonFinder);
    await tester.pumpAndSettle();
    late List<String> pdfList, filePathList;
    // Create a Completer to signal when data has been received
    final completer = Completer<void>();

    //call predefine our method for listen
    utils.pdfEventChannel.receiveBroadcastStream().listen((event) {
      pdfList = event['filenameList'] as List<String>;
      filePathList = event['filePathList'] as List<String>;

      // Verify that the callback functions are called and states are updated
      expect(pdfList, mockPdfData['filenameList']);
      expect(filePathList, mockPdfData['filePathList']);

      debugPrint('pdfList: $pdfList'); // Debug statement

      // Verify that the callback functions are called and states are updated
      expect(pdfList, isNotNull); // Check if pdfList is not null
      expect(pdfList, isNotEmpty); // Check if pdfList is not empty
      expect(pdfList.length, 2); // Check if pdfList has the expected length

      // Complete the Completer to signal that data has been received
      completer.complete();
    });

    // Wait for the Completer to complete
    await completer.future;

    await tester.pumpAndSettle(const Duration(seconds: 5));

    debugPrint('length of list is ${pdfList.length}');
    // Update the ListTile widgets with the received data
    final listTileFinder = find.byType(ListTile);
    for (int index = 0; index < pdfList.length; index++) {
      final pdfTextFinder = find.descendant(
        of: listTileFinder.at(index),
        matching: find.text(
            pdfList[index]), // Find the Text widget with the expected text
      );
    }
  });
}
