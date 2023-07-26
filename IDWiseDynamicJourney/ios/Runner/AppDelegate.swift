import UIKit
import Flutter
import IDWise

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
  let methodChannelName = "com.idwise.fluttersampleproject/idwise"
  var channel: FlutterMethodChannel? = nil
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
      
     // Native code bridging Swift -> Dart , calling iOS SDK here
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
      let channel = FlutterMethodChannel(name: methodChannelName,
                                                binaryMessenger: controller.binaryMessenger)
      self.channel = channel
      channel.setMethodCallHandler({ [self]
          (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
          
          switch call.method {
          case "initialize":
              // receiving arguments from Dart side and consuming here
              
              var clientKey: String = "" // should not be empty
              var sdkTheme: IDWiseSDKTheme = IDWiseSDKTheme.systemDefault
              if let parameteres = call.arguments as? [String:Any] {
                  if let clientkey = parameteres["clientKey"] as? String {
                      clientKey = clientkey
                  }
                  if let theme = parameteres["theme"] as? String {
                      if theme == "LIGHT" {
                          sdkTheme = IDWiseSDKTheme.light
                      } else if theme == "DARK" {
                          sdkTheme = IDWiseSDKTheme.dark
                      } else  {
                          sdkTheme = IDWiseSDKTheme.systemDefault
                      }
                  }
                
              }
              IDWise.initialize(clientKey: clientKey,theme: sdkTheme) { error in
                  result("got some error")
                  if let err = error {
                      channel.invokeMethod(
                        "onError",
                        arguments: ["errorCode": err.code,"message": err.message] as [String : Any])
                  }
              }

          case "startJourney":
              // receiving arguments from Dart side and consuming here

              var referenceNo: String = "" // optional parameter
              var locale: String = "en"
              var journeyDefinitionId = ""
              if let parameteres = call.arguments as? [String:Any] {
                  if let refNo = parameteres["referenceNo"] as? String {
                      referenceNo = refNo
                  }
                  if let loc = parameteres["locale"] as? String {
                      locale = loc
                  }
                  if let journeyDefId = parameteres["journeyDefinitionId"] as? String {
                      journeyDefinitionId = journeyDefId
                  }
              }
              IDWise.startJourney(journeyDefinitionId: journeyDefinitionId,referenceNumber: referenceNo,locale: locale, journeyDelegate: self)
              result("successfully started journey")
          default:
              result(FlutterMethodNotImplemented)
          }
          
      })
      
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}





extension AppDelegate:IDWiseSDKJourneyDelegate {
    func onJourneyResumed(journeyID: String) {
        channel?.invokeMethod(
                    "onJourneyResumed",
                    arguments: journeyID)
    }
    
    
    func onError(error : IDWiseSDKError) {
        channel?.invokeMethod(
                    "onError",
                    arguments: ["errorCode": error.code,"message": error.message] as [String : Any])
    }
    
    func JourneyStarted(journeyID: String) {
        channel?.invokeMethod(
                    "onJourneyStarted",
                    arguments: journeyID)
    }
    
    func JourneyFinished() {
        channel?.invokeMethod(
                    "onJourneyFinished",
                    arguments: nil)
    }
    
    func JourneyCancelled() {
        channel?.invokeMethod(
                    "onJourneyCancelled",
                    arguments: nil)
    }
   
}
