//
//  SceneDelegate.swift
//  appClipIncode-clip
//
//  Created by Ben Goumalatsos on 5/20/25.
//

import UIKit
import Foundation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        let adminApiObject: adminApi = adminApi()
        
        if let activity = connectionOptions.userActivities.filter({ $0.activityType == NSUserActivityTypeBrowsingWeb }).first {
            // Get invocation URL and retrieve the service ID
            // so we can dynamically get the logo URL via the admin API
            guard
                activity.activityType == NSUserActivityTypeBrowsingWeb,
                let incomingUrl = activity.webpageURL,
                let components = NSURLComponents(url: incomingUrl, resolvingAgainstBaseURL: true)
            else { return }
            
            var logoPath = components.path!
            
            // Hard code a service ID if blank since local testing
            // returns an empty string and causes the app to crash
            if logoPath == "" {
                logoPath = "/2004883"
            }
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            let adminApiBaseUrl: String = "https://preprod.admin.iddataweb.com"
            
            // Get token for admin API session
            let adminApiToken: String = adminApiObject.getToken(baseUrl: adminApiBaseUrl, apiEndpoint: "/axnadmin-core/token?grant_type=client_credentials", apiKey: "xxxxxx", sharedSecret: "xxxxxx")
            
            let apiEndpoint: String = "/service-configuration/rpservice-config/rpservice" + logoPath + "/export"
            
            // Get Logo URL via Admin API calls
            let serviceInfo: [String] = adminApiObject.getServiceInfo(baseUrl: adminApiBaseUrl, apiEndpoint: apiEndpoint, bearerToken: adminApiToken, method: "GET")!
            
            appDelegate.logoUrl = serviceInfo[0]
            appDelegate.apiKey = serviceInfo[1]
            appDelegate.sharedSecret = serviceInfo[2]
            
        }
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        print(userActivity.activityType)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

