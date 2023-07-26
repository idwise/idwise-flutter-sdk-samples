import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'my_store.dart'; // Import your store class

void main() {
  Provider.debugCheckInvalidValueType = null;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => MyStore(),
        child: MaterialApp(
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
        ));
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

  // final MyStore myStore = MyStore();

  static const STEP_ID_DOCUMENT = '0';
  static const STEP_SELFIE = '2';

  // bool _isButtonEnabled = true;

  Future<void> _navigateStep(String stepId) async {
    print("StepId: $stepId");
    platformChannel.invokeMethod('startStep', {"stepId": stepId});
  }

  Future<void> _startIDWise() async {
    try {
      /**
       * You can call initialize either in initState() of your Page
       * where you are going to start the verification, to pre-initialize the SDK.
       * Or you can call it along with startJourney(). Which suits best for your
       * usecase. Further implementation is done in MainActivity.kt for Android
       * and AppDelegate.swift for iOS
       */
      context.read<MyStore>().setJourneyStatus(false);
      print("initializing");
      const initializeArgs = {
        "clientKey": "<YOUR_CLIENT_KEY>", // Replace from client key here
        "theme": "SYSTEM_DEFAULT", // Values [LIGHT, DARK, SYSTEM_DEFAULT]
      };
      platformChannel.invokeMethod('initialize', initializeArgs);

      /**
       * You can call the startJourney when you wan to start the verification
       * process. Further implementation is done in MainActivity.kt for Android
       * and AppDelegate.swift for iOS
       */

      print("starting journey");
      const startJourneyArgs = {
        "journeyDefinitionId": "<YOUR_JOURNEY_DEFINITION_ID>", // Replace from journey definition id
        "referenceNo": null, //Put your reference number here
        "locale" : "en"
      };
      platformChannel.invokeMethod('startDynamicJourney', startJourneyArgs);

      platformChannel.setMethodCallHandler((handler) async {
        switch (handler.method) {
          case 'onJourneyStarted':
            context.read<MyStore>().setJourneyStatus(true);
            context.read<MyStore>().setJourneyId(handler.arguments.toString());
            print("Method: onJourneyStarted, ${handler.arguments.toString()}");
            break;
          case 'onJourneyFinished':
            print("Method: onJourneyFinished");
            break;
          case 'onJourneyCancelled':
            print("Method: onJourneyCancelled");
            break;
          case 'onJourneyResumed':
            context.read<MyStore>().setJourneyStatus(true);
            context.read<MyStore>().setJourneyId(handler.arguments.toString());
            print("Method: onJourneyResumed, ${handler.arguments.toString()}");
            break;
          case 'onStepCaptured':
            print("Method: onStepCaptured, ${handler.arguments.toString()}");
            break;
          case 'onStepConfirmed':
            print("Method: onStepConfirmed, ${handler.arguments.toString()}");
            break;
          case 'onStepResult':
            print("Method: onStepResult, ${handler.arguments.toString()}");
            break;
          case 'onError':
            print("Method: onError, ${handler.arguments.toString()}");
            break;
          default:
            print('Unknown method from MethodChannel: ${handler.method}');
            break;
        }
      });
    } on PlatformException catch (e) {
      print("Failed : '${e.message}'.");
    }
    print("End");
  }

  @override
  Widget build(BuildContext context) {
    _startIDWise();

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: SafeArea(
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
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
            Column(
              children: const [
                Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text(
                      "Welcome to",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )),
                Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text("Verification Journey",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold))),
                Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text("Please take some time to verify your identity",
                        style: TextStyle(fontWeight: FontWeight.bold)))
              ],
            ),
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Consumer<MyStore>(
                  builder: (context, store, child) {
                    return FractionallySizedBox(
                        widthFactor: 0.5,
                        child: SizedBox(
                            height: 45,
                            child: ElevatedButton(
                                child: const Text('ID Document',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          10.0), // Set the BorderRadius
                                    ),
                                    backgroundColor: store.isJourneyStarted
                                        ? const Color(0xff2A4CD0)
                                        : const Color(0xff6C6C70),
                                    textStyle:
                                        const TextStyle(color: Colors.white)),
                                onPressed: store.isJourneyStarted
                                    ? () {
                                        _navigateStep(STEP_ID_DOCUMENT);
                                      }
                                    : null)));
                  },
                ),
                const Padding(padding: EdgeInsets.all(5.0)),
                Consumer<MyStore>(
                  builder: (context, store, child) {
                    return FractionallySizedBox(
                        widthFactor: 0.5,
                        child: SizedBox(
                            height: 45,
                            child: ElevatedButton(
                                child: const Text('Selfie',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          10.0), // Set the BorderRadius
                                    ),
                                    backgroundColor: store.isJourneyStarted
                                        ? const Color(0xff2A4CD0)
                                        : const Color(0xff6C6C70),
                                    textStyle:
                                        const TextStyle(color: Colors.white)),
                                onPressed: store.isJourneyStarted
                                    ? () {
                                        _navigateStep(STEP_SELFIE);
                                      }
                                    : null)));
                  },
                ),
              ],
            )),
            Consumer<MyStore>(
              builder: (context, model, child) {
                return Visibility(
                  visible: model.isJourneyStarted, //_isButtonEnabled
                  child: Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Text('Journey Id: ' + model.journeyId,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold))),
                );
              },
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 10.0),
                child: FractionallySizedBox(
                    widthFactor: 1,
                    child: SizedBox(
                        height: 55,
                        child: ElevatedButton(
                            child: const Text('Test New Journey',
                                style: TextStyle(
                                    color: Color(0xff2A4CD0),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      10.0), // Set the BorderRadius
                                ),
                                side: const BorderSide(
                                    width: 1.0, color: Color(0xff2A4CD0)),
                                backgroundColor: Colors.white,
                                textStyle:
                                    const TextStyle(color: Colors.black)),
                            onPressed: _startIDWise))))
          ])),
    );
  }
}
