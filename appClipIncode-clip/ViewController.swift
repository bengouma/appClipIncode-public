//
//  ViewController.swift
//  appClipIncode-clip
//
//  Created by Ben Goumalatsos on 5/20/25.
//

import UIKit
import Foundation
import CoreLocation
import IncdOnboarding

class ViewController: UIViewController {
    @IBOutlet weak var urlText: UILabel!
    @IBOutlet weak var policyDecisionText: UILabel!
    @IBOutlet weak var serviceLogo: UIImageView!
    @IBOutlet var td_clip: TMXProfileController!

    var axnApiObject: axnObject = axnObject()
    var baseUrl: String = "https://api.preprod.iddataweb.com"
    var token: String = ""
    var transaction_id: String = ""
    var tmxText = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view such as
        // getting location permissions from user
        locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        // td_clip.doProfile()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        urlText.text = "Logo URL: \(appDelegate.logoUrl!)"
        serviceLogo.load(url: URL(string: appDelegate.logoUrl!)!)
    }
    
    @IBAction func startAXNSession(_ sender: UIButton) {
        var apiResponse: [String: String]?
        
        token = axnApiObject.getToken(baseUrl: baseUrl, apiEndpoint: "/v1/token?grant_type=client_credentials", apiKey: "xxxxxx", sharedSecret: "xxxxxx")
        apiResponse = axnApiObject.callBioGovID(baseUrl: baseUrl, apiEndpoint: "/v1/async-ui/get-link", bearerToken: token, forwardApiKey: "xxxxxx", asi: "")
        let apTransactionId: String = apiResponse!["apTransactionId"]!
        transaction_id = apiResponse!["transaction_id"]!
        
        startOnboarding(apTransactionId: apTransactionId)
    }
    
    @IBAction func uploadTMXData(_ sender: UIButton) {
        td_clip.profileHandle.sendBehavioSecData()
        let baseUrl: String = "https://api.preprod.iddataweb.com"
        var token = ""
        var uploadProfileData: [String: String]?
        
        token = axnApiObject.getToken(baseUrl: baseUrl, apiEndpoint: "/v1/token?grant_type=client_credentials", apiKey: "xxxxxx", sharedSecret: "xxxxxx")
        
        uploadProfileData = axnApiObject.uploadTMXData(baseUrl: baseUrl, apiEndpoint: "/v1/slverify", bearerToken: token, forwardApiKey: "xxxxxx", asi: "", apSessionId: td_clip.sessionID)
        
        tmxText.center = CGPoint(x: 200, y: 285)
        tmxText.textAlignment = .center
        tmxText.numberOfLines = 6
        tmxText.text = "TMX Session ID: \(td_clip.sessionID) ASI: \(uploadProfileData!["transaction_id"]!)"

        self.view.addSubview(tmxText)
    }
    
    func createSessionConfig(apTransactionId: String?) -> IncdOnboardingSessionConfiguration {
        let sessionConfig = IncdOnboardingSessionConfiguration(configurationId: "xxxxxx", interviewId: apTransactionId)
        return sessionConfig
    }

    func createFlowConfig() -> IncdOnboardingFlowConfiguration {
        let flowConfig = IncdOnboardingFlowConfiguration()
        flowConfig.addIdScan()
        flowConfig.addSelfieScan()
        flowConfig.addFaceMatch()
        
        return flowConfig
    }

    func startOnboarding(apTransactionId: String?) {
        IncdOnboardingManager.shared.presentingViewController = self
        IncdOnboardingManager.shared.startOnboarding(sessionConfig: createSessionConfig(apTransactionId: apTransactionId), flowConfig: createFlowConfig(), delegate: self)
    }
    
}

// UIImageView only loads local images,
// load() downloads the image and passes
// it to UIImageView once its present locally
extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
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
        var policyDecsionResult: [String: String]?
        policyDecsionResult = axnApiObject.callBioGovID(baseUrl: baseUrl, apiEndpoint: "/v1/slverify", bearerToken: token, forwardApiKey: "e6127ea024964156", asi: transaction_id)
        
        DispatchQueue.main.async {
            self.policyDecisionText.text = "Policy decision: \(policyDecsionResult!["policyDecision"]!)"
        }
    }
}
