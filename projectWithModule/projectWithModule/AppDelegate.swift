//
//  AppDelegate.swift
//  projectWithModule
//
//  Created by ankudinov aleksandr on 27.07.2023.
//

import UIKit
import UnityFramework
import LAModule
import FacebookCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        LAModule.shared.setupAnalytics(configuration: self, window: &self.window) {
            LAUnity.shared.show(in:self.window )
            return nil
        } virtualAppDidShow: {
            LAUnity.shared.hide()
        }
        
        return true
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

extension AppDelegate:LAConfigurationKeysProtocol  {
    func DontForgetIncludeFBKeysInInfo() -> LAModule.LAConfigurationKeys {
        return LAModule.LAConfigurationKeys(
            appsFlyerDevKey: "cvfFBQLVagfY3WrTi3LsvA",
            appleAppID: "6462696959",
            oneSignalAppId: "ae6c621f-4cd2-49ac-bb18-8d1b50d8d619",
            tikTokKeys: (TTAppId: "7269656196985047046", TTAppSecret: "MlWhJOxVCgG6IDeQwMyQmQBSAWPir4ob"),
            remoteConfigKeys: (remoteTargetKey: "settingsKey", remoteLKey: "L")
        )
    }
}

