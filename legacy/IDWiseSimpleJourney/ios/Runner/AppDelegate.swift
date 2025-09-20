import UIKit
import Flutter
import IDWiseSDK

@main
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
              IDWise.initialize(clientKey: clientKey,theme: IDWiseTheme.dark) { error in
                  result("got some error")
                  if let err = error {
                      channel.invokeMethod(
                        "onError",
                        arguments: ["errorCode": err.code,"message": err.message] as [String : Any])
                  }
              }

          case "startJourney":
              // receiving arguments from Dart side and consuming here

                var referenceNo: String = ""  // optional parameter
                var locale: String = "en"
                var journeyDefinitionId = ""
                var applicantDetails :[String:String]? 
                if let parameteres = call.arguments as? [String: Any] {
                    if let refNo = parameteres["referenceNo"] as? String {
                        referenceNo = refNo
                    }
                    if let loc = parameteres["locale"] as? String {
                        locale = loc
                    }

                    if let appctDetails = parameteres["applicantDetails"] as? [String:String] {
                        applicantDetails = appctDetails
                    }

                    if let journeyDefId = parameteres["flowId"] as? String {
                        journeyDefinitionId = journeyDefId
                    }
                }

                IDWise.startJourney(
                    flowId: journeyDefinitionId, referenceNumber: referenceNo, locale: locale,applicantDetails: applicantDetails,
                    journeyCallbacks: self)

          default:
              result(FlutterMethodNotImplemented)
          }
          
      })
      
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}





extension AppDelegate:IDWiseJourneyCallbacks  {
  public func onJourneyBlocked(journeyBlockedInfo: IDWiseSDK.JourneyBlockedInfo) {
      do{
          let jsonEncoder = JSONEncoder()
          let jsonData = try jsonEncoder.encode(journeyBlockedInfo)
          let jsonResp = String(data: jsonData, encoding: String.Encoding.utf8)
          channel?.invokeMethod(
              "onJourneyBlocked", arguments: jsonResp)
      }catch{
          print(error)
      }
  }
    
  public func  onJourneyResumed(journeyResumedInfo: JourneyResumedInfo)  {
      do{
          let jsonEncoder = JSONEncoder()
          let jsonData = try jsonEncoder.encode(journeyResumedInfo)
          let jsonResp = String(data: jsonData, encoding: String.Encoding.utf8)
          channel?.invokeMethod(
            "onJourneyResumed", arguments: jsonResp)
      }catch{
          print(error)
      }
    
  }

  public func onError(error : IDWiseError)  {
   
          do {
              let jsonEncoder = JSONEncoder()
              let jsonData = try jsonEncoder.encode(error)
              let jsonResp = String(data: jsonData, encoding: String.Encoding.utf8)
              channel?.invokeMethod("onError", arguments: jsonResp)
          } catch{
            print(error)
          }
          
        
  }

  public func onJourneyStarted(journeyStartedInfo: JourneyStartedInfo) {
      do{
          let jsonEncoder = JSONEncoder()
          let jsonData = try jsonEncoder.encode(journeyStartedInfo)
          let jsonResp = String(data: jsonData, encoding: String.Encoding.utf8)
          channel?.invokeMethod(
            "onJourneyStarted", arguments: jsonResp)
      } catch {
          print(error)
      }
  }

    public func onJourneyCompleted(journeyCompletedInfo: JourneyCompletedInfo) {
        
        do{
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(journeyCompletedInfo)
            let jsonResp = String(data: jsonData, encoding: String.Encoding.utf8)
            channel?.invokeMethod(
                "onJourneyCompleted", arguments: jsonResp)
        }catch{
            print(error)
        }
    }

    public func onJourneyCancelled(journeyCancelledInfo: JourneyCancelledInfo) {
        do{
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(journeyCancelledInfo)
            let jsonResp = String(data: jsonData, encoding: String.Encoding.utf8)
            channel?.invokeMethod(
                "onJourneyCancelled", arguments: jsonResp)
        }catch{
            print(error)
        }
    }

}
