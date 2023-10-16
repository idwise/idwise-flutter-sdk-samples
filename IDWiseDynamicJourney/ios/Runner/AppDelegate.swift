import UIKit
import Flutter
import IDWiseSDK

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

          case "startDynamicJourney":
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
              IDWise.startDynamicJourney(journeyDefinitionId: journeyDefinitionId, referenceNumber: referenceNo, locale: locale, journeyDelegate: self, stepDelegate: self)
              result("successfully started journey")
          case "startStep":
            if let parameteres = call.arguments as? [String:Any] {
                  if let stepId = parameteres["stepId"] as? String {
                      IDWise.startStep(stepId: stepId)
                  }
            }
          case "resumeDynamicJourney":
              var locale: String = "en"
              var journeyDefinitionId = ""
              var journeyId = ""
              if let parameteres = call.arguments as? [String:Any] {
                  if let loc = parameteres["locale"] as? String {
                      locale = loc
                  }
                  if let journeyDefId = parameteres["journeyDefinitionId"] as? String {
                      journeyDefinitionId = journeyDefId
                  }
                  if let journeyID = parameteres["journeyId"] as? String {
                      journeyId = journeyID
                  }
              }
              
              IDWise.resumeDynamicJourney(journeyDefinitionId: journeyDefinitionId, journeyId: journeyId, locale: locale, journeyDelegate: self, stepDelegate: self)
          case "finishDynamicJourney":
              if let parameteres = call.arguments as? [String:Any] {
                    if let journeyId = parameteres["journeyId"] as? String {
                        IDWise.finishDynamicJourney(journeyId: journeyId)
                    }
              }
          case "getJourneySummary":
              if let parameteres = call.arguments as? [String:Any] {
                  if let journeyId = parameteres["journeyId"] as? String {
                      IDWise.getJourneySummary(journeyId: journeyId) { summary, error in
                          
                          do {
                              let jsonData = try JSONEncoder().encode(summary)
                              var jsonString: Any?
                              jsonString = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
                              
                              channel.invokeMethod(
                                "journeySummary",
                                arguments: ["summary": jsonString,"error": error] as [String: Any])
                              
                          } catch {
                              channel.invokeMethod(
                                "journeySummary",
                                arguments: ["summary": "","error": error] as [String : Any])
                              
                          }
                      }
                  }
              }
              
          case "unloadSDK":
              IDWise.unloadSDK()
              

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

extension AppDelegate: IDWiseSDKStepDelegate {
    func onStepCaptured(stepId: Int, capturedImage: UIImage?) {
        channel?.invokeMethod(
                    "onStepCaptured",
                    arguments: stepId)
    }
    
    func onStepResult(stepId: Int, stepResult: IDWiseSDK.StepResult?) {
        
        do {
            let jsonData = try JSONEncoder().encode(stepResult)
            var jsonString: Any?
            jsonString = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        
            channel?.invokeMethod(
              "onStepResult",
              arguments: ["stepId": stepId,"stepResult": jsonString] as [String : Any])
        
        } catch {
            channel?.invokeMethod(
              "onStepResult",
              arguments: ["stepId": stepId] as [String : Any])
        
        }
       
    }
    
    func onStepConfirmed(stepId: String) {
        
    }
    
    
}
