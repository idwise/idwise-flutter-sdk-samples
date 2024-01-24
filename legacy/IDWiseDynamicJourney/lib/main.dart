import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'my_store.dart'; // Import your store class

void main() {
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

  static const JOURNEY_ID = "JOURNEY_ID";

  static const STEP_ID_DOCUMENT = '0';
  static const STEP_SELFIE = '2';

  static const IDWISE_CLIENT_KEY =
      "<IDWISE_CLIENT_KEY>"; // Replace from client key here
  static const JOURNEY_DEFINITION_ID =
      "<YOUR_JOURNEY_DEFINITION_ID>"; // Replace from journey definition id
  static const LOCALE = "en";

  // bool _isButtonEnabled = true;

  Future<void> clearSaved() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  Future<void> saveJourneyId(String journeyId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(JOURNEY_ID, journeyId);
  }

  Future<String?> retrieveJourneyId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(JOURNEY_ID);
  }

  Future<void> _navigateStep(String stepId) async {
    print("StepId: $stepId");
    platformChannel.invokeMethod('startStep', {"stepId": stepId});
  }

  Future<void> unloadSDK() async {
    print("unloadSDK");
    platformChannel.invokeMethod('unloadSDK');
  }

  Future<void> startResumeJourney() async {
    try {
      context.read<MyStore>().setJourneyStatus(false);

      print("Initializing SDK");
      initializeSDK();

      String? journeyId = await retrieveJourneyId();

      if (journeyId == null) {
        print("Starting new journey...");
        startDynamicJourney();
      } else {
        print("Resuming journey...");
        resumeDynamicJourney(journeyId);
      }

      setJourneyMethodHandler();
    } on PlatformException catch (e) {
      print("Failed : '${e.message}'.");
    }
    print("End");
  }

  Future<void> setJourneyMethodHandler() async {
    try {
      platformChannel.setMethodCallHandler((handler) async {
        switch (handler.method) {
          case 'onJourneyStarted':
            context.read<MyStore>().setJourneyStatus(true);
            saveJourneyId(handler.arguments.toString());
            context.read<MyStore>().setJourneyId(handler.arguments.toString());
            print("Method: onJourneyStarted, ${handler.arguments.toString()}");
            getJourneySummary(handler.arguments.toString());
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
            getJourneySummary(handler.arguments.toString());
            break;
          case 'onStepCaptured':
            print("Method: onStepCaptured, ${handler.arguments.toString()}");
            break;
          case 'onStepConfirmed':
            print("Method: onStepConfirmed, ${handler.arguments.toString()}");
            break;
          case 'onStepResult':
            print("Method: onStepResult, ${handler.arguments.toString()}");
            String? journeyId = await retrieveJourneyId();
            if (journeyId != null) {
              getJourneySummary(journeyId);
            }
            break;
          case 'onStepCancelled':
            print("Method: onStepCancelled, ${handler.arguments.toString()}");
            break;
          case 'onError':
            print("Method: onError, ${handler.arguments.toString()}");
            break;
          case 'journeySummary':
            handleJourneySummary(handler.arguments);
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

  Future<void> initializeSDK() async {
    try {
      const initializeArgs = {
        "clientKey": IDWISE_CLIENT_KEY,
        "theme": "SYSTEM_DEFAULT",
      };

      platformChannel.invokeMethod('initialize', initializeArgs);
    } on PlatformException catch (e) {
      print("Failed : '${e.message}'.");
    }
  }

  Future<void> startDynamicJourney() async {
    try {
      final startJourneyArgs = {
        "journeyDefinitionId": JOURNEY_DEFINITION_ID,
        "referenceNo": 'idwise_test_' + const Uuid().v4(),
        "locale": LOCALE
      };
      platformChannel.invokeMethod('startDynamicJourney', startJourneyArgs);
    } on PlatformException catch (e) {
      print("Failed : '${e.message}'.");
    }
  }

  Future<void> resumeDynamicJourney(String journeyId) async {
    try {
      final resumeJourneyArgs = {
        "journeyDefinitionId": JOURNEY_DEFINITION_ID,
        "journeyId": journeyId,
        "locale": LOCALE
      };
      platformChannel.invokeMethod('resumeDynamicJourney', resumeJourneyArgs);
    } on PlatformException catch (e) {
      print("Failed : '${e.message}'.");
    }
  }

  Future<void> getJourneySummary(String journeyId) async {
    try {
      platformChannel
          .invokeMethod('getJourneySummary', {"journeyId": journeyId});
    } on PlatformException catch (e) {
      print("Failed : '${e.message}'.");
    }
  }

  Future<void> handleJourneySummary(dynamic response) async {
    try {
      print("JourneySummary - Details: ${response["summary"].toString()}");
      print("JourneySummary - Error:  ${response["error"].toString()}");
      bool isCompleted = response["summary"]["is_completed"];
      print("JourneySummary - Completed: $isCompleted");

      if (isCompleted) {
        context.read<MyStore>().setJourneyCompleted(true);
        String? journeyId = await retrieveJourneyId();
        platformChannel
            .invokeMethod('finishDynamicJourney', {"journeyId": journeyId});
        clearSaved();
      }
    } catch (e) {
      print("Exception : JourneySummary: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    startResumeJourney();

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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    )),
                Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text("Verification Journey",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold))),
                Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text("Please take some time to verify your identity",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)))
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
                Consumer<MyStore>(
                  builder: (context, model, child) {
                    return Visibility(
                      visible: model.isJourneyCompleted,
                      //_isButtonEnabled
                      child: Padding(
                          padding: const EdgeInsets.only(
                              top: 50.0, left: 15.0, right: 15.0),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.check,
                                    color: Color(0xff248A3D), size: 36.0),
                                Padding(
                                    padding: EdgeInsets.only(top: 10.0),
                                    child: Text(
                                        "Congratulations! Your verification has been completed.",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)))
                              ])),
                    );
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
                            onPressed: () {
                              clearSaved();
                              unloadSDK();
                              startResumeJourney();
                            }))))
          ])),
    );
  }
}
