import Flutter
import IDWiseSDK
import UIKit

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
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let fchannel = FlutterMethodChannel(
      name: methodChannelName,
      binaryMessenger: controller.binaryMessenger)
    self.channel = fchannel
      
    channel?.setMethodCallHandler({
      [self]
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in

      switch call.method {
      case "initialize":
        // receiving arguments from Dart side and consuming here

        var clientKey: String = ""
        var sdkTheme: IDWiseTheme = IDWiseTheme.systemDefault
        if let parameteres = call.arguments as? [String: Any] {
          if let clientkey = parameteres["clientKey"] as? String {
            clientKey = clientkey
          }
          if let theme = parameteres["theme"] as? String {
            if theme == "LIGHT" {
              sdkTheme = IDWiseTheme.light
            } else if theme == "DARK" {
              sdkTheme = IDWiseTheme.dark
            } else {
              sdkTheme = IDWiseTheme.systemDefault
            }
          }

        }

        IDWise.initialize(clientKey: clientKey, theme: sdkTheme) { error in
          print("onInitializeError")
          if let err = error {
            do {
                let jsonEncoder = JSONEncoder()
                let jsonData = try jsonEncoder.encode(error)
                let jsonResp = String(data: jsonData, encoding: String.Encoding.utf8)
                channel?.invokeMethod("onInitializeError", arguments: jsonResp)
            } catch{
              print(error)
            }
            
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
      IDWiseDynamic.startJourney(
        flowId: journeyDefinitionId, referenceNumber: referenceNo, locale: locale,applicantDetails: applicantDetails,
        journeyCallbacks: self, stepCallbacks: self)
      result("successfully started journey")
      
      case "startStep":
        if let parameteres = call.arguments as? [String: Any] {
          if let stepId = parameteres["stepId"] as? String {
            IDWiseDynamic.startStep(stepId: stepId)
          }
        }
      case "skipStep":
        if let parameteres = call.arguments as? [String: Any] {
          if let stepId = parameteres["stepId"] as? String {
            IDWiseDynamic.skipStep(stepId: stepId)
          }
        }
      case "resumeJourney":
        var locale: String = "en"
        var journeyDefinitionId = ""
        var journeyId = ""
        if let parameteres = call.arguments as? [String: Any] {
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

        IDWiseDynamic.resumeJourney(
          flowId: journeyDefinitionId, journeyId: journeyId, locale: locale,
          journeyCallbacks: self, stepCallbacks: self)

      case "finishJourney":
        IDWiseDynamic.finishJourney()

      case "getJourneySummary":
        IDWiseDynamic.getJourneySummary { summary, summaryError in

          do {
            let responseSummary = JourneySummaryExposed(summary: summary,error: summaryError)
          
            let jsonData = try JSONEncoder().encode(responseSummary)
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            channel?.invokeMethod("journeySummary", arguments: jsonString)

          } catch {
              print(error)
          }
        }

      case "unloadSDK":
        IDWiseDynamic.unloadSDK()

      default:
        result(FlutterMethodNotImplemented)
      }

    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

extension AppDelegate: IDWiseJourneyCallbacks {
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

extension AppDelegate: IDWiseStepCallbacks {
  public func onStepCaptured(stepCapturedInfo:StepCapturedInfo) {
        do{
            let originalImage = convertImageToBase64String(img: stepCapturedInfo.originalImage)
            let croppedImage = convertImageToBase64String(img: stepCapturedInfo.croppedImage)
    
            let captureResponse = OnStepCapturedExposed(stepId: stepCapturedInfo.stepId, originalImage: originalImage, croppedImage: croppedImage)
            
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(captureResponse)
            let jsonResp = String(data: jsonData, encoding: String.Encoding.utf8)
            
            channel?.invokeMethod(
              "onStepCaptured",
              arguments: jsonResp)
        }catch{
            print(error)
        }
  }

  public func onStepResult(stepResultInfo:StepResultInfo) {

      do{
          let jsonEncoder = JSONEncoder()
          let jsonData = try jsonEncoder.encode(stepResultInfo)
          let jsonResp = String(data: jsonData, encoding: String.Encoding.utf8)
          channel?.invokeMethod("onStepResult", arguments: jsonResp)
      }catch{
          print(error)
      }

  }


    public func onStepCancelled(stepCancelledInfo: StepCancelledInfo) {
        do{
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(stepCancelledInfo)
            let jsonResp = String(data: jsonData, encoding: String.Encoding.utf8)
            channel?.invokeMethod(
                "onStepCancelled", arguments: jsonResp)
        }catch{
            print(error)
        }
  }

  public func onStepSkipped(stepSkippedInfo: StepSkippedInfo) {
      do{
          let jsonEncoder = JSONEncoder()
          let jsonData = try jsonEncoder.encode(stepSkippedInfo)
          let jsonResp = String(data: jsonData, encoding: String.Encoding.utf8)
          channel?.invokeMethod("onStepSkipped", arguments: jsonResp)
      }catch{
          print(error)
      }
  }

  func convertImageToBase64String(img: UIImage?) -> String {
    return img?.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
  }

}

private struct JourneySummaryExposed: Codable {
    var summary: IDWiseSDK.JourneySummary?
    var error: IDWiseError?
}

private struct OnStepCapturedExposed: Codable {
    var stepId: String
    var originalImage: String?
    var croppedImage: String?
}
