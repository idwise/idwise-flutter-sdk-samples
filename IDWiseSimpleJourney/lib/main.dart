import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:idwise_flutter_sdk/idwise_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDWise Flutter Application',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.indigo,
      ),
      home: const MyHomePage(title: 'IDWise Flutter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const methodChannelName = "com.idwise.fluttersampleproject/idwise";
  static const platformChannel = MethodChannel(methodChannelName);

  late IDWiseSDKJourneyCallbacks _journeyCallbacks;

  String IDWISE_CLIENT_KEY = "<CLIENT_KEY>"; // Provided by IDWise
  String JOURNEY_DEFINITION_ID = "<FLOW_ID>"; // Provided by IDWise
  String referenceNo = "<REFERENCE_NO>";
  String LOCALE = "en";

  @override
  void initState() {
    super.initState();
    setupCallbacks();
    initializeSDK();
  }

  void setupCallbacks() {
    _journeyCallbacks = IDWiseSDKJourneyCallbacks(
        onJourneyStarted: (dynamic journeyInfo) =>
            print("onJourneyStarted: $journeyInfo"),
        onJourneyCompleted: (dynamic journeyInfo) =>
            print("onJourneyCompleted: $journeyInfo"),
        onJourneyResumed: (dynamic journeyInfo) =>
            print("onJourneyResumed: $journeyInfo"),
        onJourneyCancelled: (dynamic journeyInfo) =>
            print("onJourneyCancelled: $journeyInfo"),
        onError: (dynamic error) => print("onError $error"));
  }

  void initializeSDK() {
    try {
      IDWise.initialize(IDWISE_CLIENT_KEY, IDWiseSDKTheme.DARK,
          onError: (error) {
        print("onError in _idwiseFlutterPlugin: $error");
      });
    } on PlatformException catch (e) {
      print("Failed : '${e.message}'.");
    }
  }

  Future<void> startJourney() async {
    try {
      IDWise.startJourney(
          JOURNEY_DEFINITION_ID, referenceNo, LOCALE, _journeyCallbacks);
    } on PlatformException catch (e) {
      print("Failed : '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text('Start SDK'),
              style: ElevatedButton.styleFrom(
                  primary: const Color(0xff4B5EB9),
                  textStyle: const TextStyle(color: Colors.white)),
              onPressed: startJourney,
            )
          ],
        ),
      ),
    );
  }
}
