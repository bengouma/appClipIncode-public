//
//  TMXProfileController.swift
//  appClipIncode
//
//  Created by Ben Goumalatsos on 6/18/25.
//

import UIKit
import TMXProfiling
import TMXProfilingConnections

class TMXProfileController: NSObject {
    var profile: TMXProfiling!
    var profileHandle: TMXProfileHandle!
    var profileTimeout: TimeInterval = 20
    var sessionID = ""
    
    override init() {
        super.init()

        var connectionInstance: TMXProfilingConnectionsProtocol
        
        let profilingConnections : TMXProfilingConnections = TMXProfilingConnections.init()
        profilingConnections.connectionTimeout    = 20 // Default value is 10 seconds
        profilingConnections.connectionRetryCount = 2  // Default value is 0 (no retry)
        connectionInstance = profilingConnections
        
        // connectionInstance = IDWProfilingConnections.init() as any TMXProfilingConnectionsProtocol
        
        //Get a singleton instance of TMXProfiling
        profile = TMXProfiling.sharedInstance()

        // The profile.configure method is effective only once and subsequent calls to it will be ignored.
        // Please note that configure may throw NSException if NSDictionary key/value(s) are invalid.
        // This only happen due to programming error, therefore we don't catch the exception to make sure there is no error in our configuration dictionary
        profile.configure(configData:[
                            // (REQUIRED) Organisation ID
                            TMXOrgID: "xxxxxx",
                            // (REQUIRED) Enhanced fingerprint server
                            TMXFingerprintServer: "content.maxconnector.com",
                            // (OPTIONAL) Set the profile timeout, in seconds
                            TMXProfileTimeout: profileTimeout,
                            // (OPTIONAL) Register for location service updates.
                            // Requires permission to access device location
                            TMXLocationServices: true,
                            // (OPTIONAL) Pass the configured instance of TMXProfilingConnections to TMX SDK.
                            // If not passed, configure method tries to create and instance of TMXProfilingConnections
                            // with the default settings.
                            TMXProfilingConnectionsInstance: connectionInstance
                            ])
    }

    func doProfile() {
        // (OPTIONAL) Pass a set of View Controllers to be monitored by TMXBehavioSec module.
        // If not passed all ViewControllers will be monitored.
        let includedViews : Set<String> = [NSStringFromClass(ViewController.self)]

        let profilingOptions : [String: Any] = [TMXBehavioSecIncludedViews : includedViews]

        // Fire off the profiling request
        self.profileHandle = profile.profileDevice(profileOptions: profilingOptions, callbackBlock:{(result: [AnyHashable : Any]?) -> Void in

            let results:NSDictionary! = result! as NSDictionary
            let status:TMXStatusCode  = TMXStatusCode(rawValue:(results.value(forKey: TMXProfileStatus) as! NSNumber).intValue)!

            self.sessionID = results.value(forKey: TMXSessionID) as! String
            if(status == .ok) {
                print("Profile success")
            }

            let statusString: String =
                status == .ok                  ? "OK"                   :
                status == .networkTimeoutError ? "Timed out"            :
                status == .connectionError     ? "Connection Error"     :
                status == .hostNotFoundError   ? "Host Not Found Error" :
                status == .internalError       ? "Internal Error"       :
                status == .interruptedError    ? "Interrupted Error"    :
                "Other"
                print("Profile completed with: \(statusString) and session ID: \(self.sessionID)")
        })

        // Session id can be collected here (to use in API call (AKA session query))
        self.sessionID = self.profileHandle.sessionID;
        print("Session id is \(self.sessionID)");


        /*
         * If needed profileHandle can be used to:
         * - cancel current profiling
         * profileHandle.cancel()
         *
         * - send collected biometrics information to backend (can be used once per profiling call)
         * profileHandle.sendBehavioSecData()
         *
         * - stop collecting biometrics information (call profile method to start collecting information again)
         * profileHandle.stopBehavioSecDataCollection()
         * */
    }
}

