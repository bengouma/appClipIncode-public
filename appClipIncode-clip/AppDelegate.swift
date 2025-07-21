//
//  AppDelegate.swift
//  appClipIncode-clip
//
//  Created by Ben Goumalatsos on 5/20/25.
//

import UIKit
import IncdOnboarding
import Foundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var logoUrl: String?
    var apiKey: String?
    var sharedSecret: String?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        IncdOnboardingManager.shared.initIncdOnboarding(url: "https://saas-onboarding.incodesmile.com", apiKey: "xxxxxx")
        
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

