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
            appsFlyerDevKey: "hxEiGXhSZtjMoyqM8R566T",
            appleAppID: "",
            oneSignalAppId: "3f4154df-8be4-4066-9871-99c29cb1be21",
            tikTokKeys: (TTAppId: "989222735538623", TTAppSecret: "2f71cbe39e8228ba04481acb8875c400"),
            remoteConfigKeys: (remoteTargetKey: "settingsKey", remoteLKey: "L")
        )
    }
}

