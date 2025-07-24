//
//  ViewController.swift
//  appClipIncode
//
//  Created by Ben Goumalatsos on 5/16/25.
//

import Foundation
import UIKit
import IncdOnboarding
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate {
    var axnApiObject: axnObject = axnObject()
    var baseUrl: String = "https://api.preprod.iddataweb.com"
    var token: String = ""
    var transaction_id: String = ""
    var apTransactionId: String = ""
    var apSessionId: String = ""
    var locationManager: CLLocationManager!
    
    @IBOutlet var td: TMXProfileController!
    @IBOutlet weak var policyDecisionText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view such as
        // getting location permissions from user
        locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        // td.doProfile()
    }
    
    @IBAction func startOnboardingBtn(_ sender: UIButton) {
        var apiResponse: [String: String]?
        
        token = axnApiObject.getToken(baseUrl: baseUrl, apiEndpoint: "/v1/token?grant_type=client_credentials", apiKey: "xxxxxx", sharedSecret: "xxxxxx")
        apiResponse = axnApiObject.callBioGovID(baseUrl: baseUrl, apiEndpoint: "/v1/async-ui/get-link", bearerToken: token, forwardApiKey: "xxxxxxx", asi: "")
        apTransactionId = apiResponse!["apTransactionId"]!
        apSessionId = apiResponse!["apSessionId"]!
        transaction_id = apiResponse!["transaction_id"]!

        startOnboarding(apTransactionId: apTransactionId)
    }
    
    @IBAction func getOnboardingResults(_ sender: UIButton) {
        var policyDecsionResult: [String: String]?
        policyDecsionResult = axnApiObject.callBioGovID(baseUrl: baseUrl, apiEndpoint: "/v1/slverify", bearerToken: token, forwardApiKey: "xxxxxx", asi: transaction_id)
        print(policyDecsionResult)
        
        DispatchQueue.main.async {
            self.policyDecisionText.text = "Policy decision: \(policyDecsionResult!["policyDecision"]!), ASI: \(policyDecsionResult!["transaction_id"]!)"
        }
    }
    
    func createSessionConfig(apTransactionId: String?) -> IncdOnboardingSessionConfiguration {
        let sessionConfig = IncdOnboardingSessionConfiguration(configurationId: "xxxxxx", interviewId: apTransactionId)
        return sessionConfig
    }

    func createFlowConfig() -> IncdOnboardingFlowConfiguration {
        let flowConfig = IncdOnboardingFlowConfiguration()
        flowConfig.addUserConsent(title: "Privacy Consent")
        flowConfig.addIdScan(showTutorials: false)
        flowConfig.addSelfieScan(showTutorials: false)
        flowConfig.addFaceMatch()
        
        return flowConfig
    }

    func startOnboarding(apTransactionId: String?) {
        IncdOnboardingManager.shared.presentingViewController = self
        IncdOnboardingManager.shared.startOnboarding(sessionConfig: createSessionConfig(apTransactionId: apTransactionId), flowConfig: createFlowConfig(), delegate: self)
    }
    
    @IBAction func uploadTMXProfilingData(_ sender: UIButton) {
        td.profileHandle.sendBehavioSecData()
        var token = ""
        var uploadProfileData: [String: String]?
        
        token = axnApiObject.getToken(baseUrl: baseUrl, apiEndpoint: "/v1/token?grant_type=client_credentials", apiKey: "xxxxxx", sharedSecret: "xxxxxx")
        
        uploadProfileData = axnApiObject.uploadTMXData(baseUrl: baseUrl, apiEndpoint: "/v1/slverify", bearerToken: token, forwardApiKey: "xxxxxx", asi: "", apSessionId: td.sessionID)
    }

}

extension ViewController: IncdOnboardingDelegate {
    func onOnboardingSessionCreated(_ result: OnboardingSessionResult) {
        print("onOnboardingSessionCreated: \(result)")
    }
    
    func onIdFrontCompleted(_ result: IdScanResult) {
        print("onIdFrontCompleted: \(result)")
    }
    
    func onIdBackCompleted(_ result: IdScanResult) {
        print("onIdBackCompleted: \(result)")
    }
    
    func onIdProcessed(_ result: IdProcessResult) {
        print("onIdProcessed: \(result)")
    }
    
    func onSelfieScanCompleted(_ result: SelfieScanResult) {
        print("onSelfieScanCompleted: \(result)")
    }
    
    func onFaceMatchCompleted(_ result: FaceMatchResult) {
        print("onFaceMatchCompleted: \(result)")
    }
    
    func onEvents(_ eventsWithDetails: [EventWithDetails]) {
        print(eventsWithDetails.first)
    }
    
    func userCancelledSession() {
        print("userCancelledSession")
    }
    
    func onError(_ error: IncdFlowError) {
        print("onError: \(error.description)")
    }
    
    func onSuccess() {
        print("onSuccess")
        
        let url = URL(string: "https://preprod1.iddataweb.com/axn/api/async-ui/redirect?apSessionId=\(apSessionId)&processResult=true&asi=\(transaction_id)")
        var redirectCall = axnApiObject.redirect(redirectUrl: url!)
    }
}
