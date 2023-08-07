//
//  AppDelegate.swift
//  projectWithModule
//
//  Created by ankudinov aleksandr on 27.07.2023.
//

import UIKit
import UnityFramework
import AppsFlyerLib
import AppTrackingTransparency
import FacebookCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let initialViewControlleripad : UIViewController = PreloadrViewController()
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = initialViewControlleripad
        self.window?.makeKeyAndVisible()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            LAHelper.shared.enableMetrics(launchOptions: launchOptions) {
                self.window?.rootViewController = nil;
                Unity.shared.setHostMainWindow(self.window)
                Unity.shared.show()
            }
        }
        
        NotificationCenter.default.addObserver(self,
                selector: #selector(didBecomeActiveNotification),
                name: UIApplication.didBecomeActiveNotification,
                object: nil)
        
        return true
    }
    
    @objc func didBecomeActiveNotification() {
        AppsFlyerLib.shared().start()
        ATTrackingManager.requestTrackingAuthorization { (status) in
            switch status {
            case .denied:
                print("AuthorizationSatus is denied")
            case .notDetermined:
                print("AuthorizationSatus is notDetermined")
            case .restricted:
                print("AuthorizationSatus is restricted")
            case .authorized:
                print("AuthorizationSatus is authorized")
            @unknown default:
                fatalError("Invalid authorization status")
            }
        }
    }
    
    func application(
            _ app: UIApplication,
            open url: URL,
            options: [UIApplication.OpenURLOptionsKey : Any] = [:]
        ) -> Bool {
            ApplicationDelegate.shared.application(
                app,
                open: url,
                sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                annotation: options[UIApplication.OpenURLOptionsKey.annotation]
            )
        }  

}

enum ConfigurationKeys: String {

    case appsFlyerDevKey = "hxEiGXhSZtjMoyqM8R566T"
    case appleAppID = "6450305857"
    case oneSignalAppId = "3f4154df-8be4-4066-9871-99c29cb1be21"
    
    case fbAppId = "1112449286808912"
    case fbAppSecret = "bd5fa6e9eece601c0c44e7c8d84abe5a"
    
    case tTAppId = "989222735538623"
    case tTAppSecret = "2f71cbe39e8228ba04481acb8875c400"
    
    case targetUrlKey = "settingsKey"
    case remoteConfigKey = "L"
    
    var value:String {
        return self.rawValue
    }
}
