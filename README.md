# Integrating IDDataWeb service with Incode IOS SDK
## Prerequisites 
* IDDataWeb Incode BioGovID service API key and client secret
* API key and Client Secret of your BioGovID service
* IDDataWeb account setup to use the Admin API
* CocoaPod installed
* Access to the [Incode-Technologies-Example-Repos/IncdDistributionPodspecs](https://github.com/Incode-Technologies-Example-Repos/IncdDistributionPodspecs) and IncodeTechnologies/IncdOnboarding-distribution repos 
  * SSH authentication with Git is required to be setup on your mac
* Incode iOS SDK installed

**Note:** The Incode iOS SDK is based off of the UIKit development environment so your app will need to be setup to use it as well

## Getting access to SDK repos
In order to be able to install the Incode iOS SDK, you need access to the [Incode-Technologies-Example-Repos/IncdDistributionPodspecs](https://github.com/Incode-Technologies-Example-Repos/IncdDistributionPodspecs) and IncodeTechnologies/IncdOnboarding-distribution repos in Github. To gain access, send an email to support@incode.com that explains which repos you would like access to and your Github username. They will reply once they have granted you access to the repos.

## Installing the Incode iOS SDK
### Installing via CocoaPods

TO install the SDK via CocoaPods (or other installation methods), refer to the official Incode SDK Installation [documentation](https://developer.incode.com/docs/manual-installation)

## Integrating the Incode SDK with your app

### Finding your Incode API key and Config ID
Before we utilize the IncdOnbaording framework in our app, we will need to find the Incode API key and Config ID our service uses so we can provide them to the Incode API. To find this information, follow these steps:
* Navigate to your Incode verification service in the AXN Admin Console
* In your verification service's settings, select the "Attribute Providers" tab at the top and then open the "Properties" tab below
* Here you will find the Incode API key and Config ID that you will need when integrating the Incode SDK to your app
  <img src="readme_images/service_details.png" width="800" height="400">

### Making structs
We will need to make a few structs to include a payload in our AXN API requests and handle their responses. Create a separate swift file and include these structs:
```
// Handle response from token endpoint
struct tokenResponse: Codable {
    var errorcode: String?
    var errorDescription: String?
    var access_token: String?
    var expires_in: Int?
    var token_type: String?
}

struct userAttribute: Codable {
    var attributeType: String?
    var values: [String: String]?
}

// payload for API requests
struct messageBody: Codable {
    var asi: String?
    var apikey: String?
    var credential: String?
    var appID: String?
    var country: String?
    var userAttributes: [userAttribute]?
}

// Handle API responses
struct responseBody: Decodable {
    var errorCode: String?
    var errorDescription: String?
    var transaction_id: String?
    var asi: String?
    var incodeUrl: String?
    var policyDecision: String?
    var forwardApiKey: String?
    var status: String?
}
```

Sample code in the repo can be found [here](https://github.com/bengouma/appClipIncode-public/blob/main/appClipIncode/appClipIncodeModel.swift).

### Creating functions to make API requests and parse their responses
Since the structure of the API calls are the same, it is easier to make a class with methods for our API calls and call them in ouir view controller. Here is a [sample code block](https://github.com/bengouma/appClipIncode-public/blob/main/appClipIncode/appClipIncodeViewModel.swift) that establishes an `axnObject` class and has a method to get the session token and make calls to the BioGovID service:
```
class axnObject: ObservableObject {
    
    public func getToken(baseUrl: String, apiEndpoint: String, apiKey: String, sharedSecret: String) -> String {
        let basicAuth = apiKey + ":" + sharedSecret
        let utf8str = basicAuth.data(using: .utf8)
        
        let url = URL(string: baseUrl + apiEndpoint)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("client_credentials", forHTTPHeaderField: "grant_type")
        request.setValue("Basic " + utf8str!.base64EncodedString(), forHTTPHeaderField: "Authorization")
        
        var tokenString: String? = nil
        
        let (data, _, error) = URLSession.shared.synchronousDataTask(urlrequest: request)
        if let error = error {
            print("there was an error: \(error)")
        } else {
            do {
                let decoder = JSONDecoder()
                let json = try decoder.decode(tokenResponse.self, from: data!)
                tokenString = json.access_token
            } catch {
                print("cant serialize due to error: \(error)")
            }
        }

        return tokenString!
    }
    
    public func callBioGovID(baseUrl: String, apiEndpoint: String, bearerToken: String, forwardApiKey: String, asi: String?) -> [String: String] {
        var attributeList: [userAttribute] = []
        
        let nameAttribute = userAttribute(
            attributeType: "FullName",
            values: ["fname": "xxxxxx", "lname": "xxxxxx"]
        )
        
        let phoneAttribute = userAttribute(
            attributeType: "InternationalTelephone",
            values: ["dialCode": "1", "telephone": "xxxxxx"]
        )
        
        attributeList = [nameAttribute, phoneAttribute]
        
        let messageBody = messageBody(
            asi: asi!,
            apikey: forwardApiKey,
            credential: "appClipTest",
            appID: "IDWAppClipTest",
            country: "US",
            userAttributes: attributeList
        )
        let payload = try! JSONEncoder().encode(messageBody)
        
        let url = URL(string: baseUrl + apiEndpoint)
        var request = URLRequest(url: url!)
        
        request.httpMethod = "POST"
        request.httpBody = payload
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("Bearer " + bearerToken, forHTTPHeaderField: "Authorization")
        
        var transaction_id: String = ""
        var newForwardApiKey: String = ""
        var policyDecision: String = ""
        var apTransactionId: String? = ""
        var apSessionId: String? = ""
        
        let (data, _, error) = URLSession.shared.synchronousDataTask(urlrequest: request)
        if let error = error {
            print("ERROR making request: \(error)")
        } else {
            do {
                let decoder = JSONDecoder()
                let json = try decoder.decode(responseBody.self, from: data!)
                
                if json.asi != nil {
                    apTransactionId = json.services?[0]["apTransactionId"]!
                    apSessionId = json.services?[0]["apSessionId"]!
                    transaction_id = json.asi!
                } else {
                    transaction_id = json.transaction_id!
                    newForwardApiKey = json.forwardApiKey!
                    policyDecision = json.policyDecision!
                }
            } catch {
                print("ERROR serializing JSON: \(error)")
            }
        }
        
        let response = ["policyDecision": policyDecision, "forwardApiKey": newForwardApiKey, "transaction_id": transaction_id, "apTransactionId": apTransactionId!, "apSessionId": apSessionId!]
        return response
    }  

    public func redirect(redirectUrl: URL) {
        var request = URLRequest(url: redirectUrl)
        
        let (data, _, error) = URLSession.shared.synchronousDataTask(urlrequest: request)
        if let error = error {
            print("ERROR making request: \(error)")
        } else {
            do {
                print("Redirect successful")
            } 
        }
    }
}

// URLSession extension to make synchronous data tasks
// This function is used to make the API calls and we parse the data response after the call is made
extension URLSession {
    func synchronousDataTask(urlrequest: URLRequest) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?

        let semaphore = DispatchSemaphore(value: 0)

        let dataTask = self.dataTask(with: urlrequest) {
            data = $0
            response = $1
            error = $2

            semaphore.signal()
        }
        dataTask.resume()

        _ = semaphore.wait(timeout: .distantFuture)

        return (data, response, error)
    }
}
```

### AppDelegate
In your AppDelegate, we will need to initialize the IncdOnboarding object during launch.
* Import the `IncdOnboarding` framework
* In your `didFinishLaunchingWithOptions` application function, initialize the IncdOnboarding object with this line of code:
  * `IncdOnboardingManager.shared.initIncdOnboarding(url: "https://saas-api.incodesmile.com", apiKey: "<< your_incode_api_key >>")`

### ViewController
Once the IncdOnboarding object is initialized, we will define a few functions in the ViewController to configure our flow and start the Incode Onbaording flow.
* Import the `IncdOnboarding` framework

* **apTransactionId:**
  Before the user starts the Incode verificaiton flow on their device, we need to start an Incode session on the IDW side, get the apTransactionId, and then pass it to the Incode SDK. In order to do this, we need to call the `getToken` and `callBioGovID` methods from our axnObject class to call the /token endpoint and the /async-ui/get-link endpoint to get the apTransactionId. A sample code block looks like this:
  ```
  var axnApiObject: axnObject = axnObject()
  var baseUrl: String = "https://api.preprod.iddataweb.com"
  var token: String = ""
  var transaction_id: String = ""
  var apTransactionId: String = ""
  var apSessionId: String = ""

  @IBAction func startOnboardingBtn(_ sender: UIButton) {
    var apiResponse: [String: String]?
    
    token = axnApiObject.getToken(baseUrl: baseUrl, apiEndpoint: "/v1/token?grant_type=client_credentials", apiKey: "xxxxxx", sharedSecret: "xxxxxx")
    apiResponse = axnApiObject.callBioGovID(baseUrl: baseUrl, apiEndpoint: "/v1/async-ui/get-link", bearerToken: token, forwardApiKey: "xxxxxx", asi: "")
    apTransactionId = apiResponse!["apTransactionId"]!
    apSessionId = apiResponse!["apSessionId"]!
    transaction_id = apiResponse!["transaction_id"]!

    startOnboarding(apTransactionId: apTransactionId)
  }
  ```
  **Note:** These API calls are made in an IBAction function, meaning they will be ran when a button is pressed. You will need to add a button to the storyboard and link it to this function.

* **createSessionConfig():**
  Create a function called `createSessionConfig`. This function will be responsible for providing Incode our Config ID and the Incode InterviewID we get when calling the /async-ui/get-link endpoint. The function should look like this:
  ```
  func createSessionConfig(apTransactionId: String?) -> IncdOnboardingSessionConfiguration {
    let sessionConfig = IncdOnboardingSessionConfiguration(configurationId: "xxxxxx", interviewId: apTransactionId)
    return sessionConfig
  }
  ```

* **createFlowConfig():**
  Create a second function called `createFlowConfig`. This function is responsible for specifying the various steps in our onboarding flow. Even though we have our flow steps setup on the IDW side, we need to specify them here as well so we go through the steps we want. Here is an example of this function:
  ```
  func createFlowConfig() -> IncdOnboardingFlowConfiguration {
    let flowConfig = IncdOnboardingFlowConfiguration()
    flowConfig.addUserConsent(title: "Privacy Consent")
    flowConfig.addIdScan(showTutorials: false)
    flowConfig.addSelfieScan(showTutorials: false)
    flowConfig.addFaceMatch()
    
    return flowConfig
  }
  ```

* **startOnboarding():**
  This function is responsible for passing off the session and flow configs to the Incode Onbaording Manager and actually starting the flow on the user's end. 
  ```
  func startOnboarding(apTransactionId: String?) {
      IncdOnboardingManager.shared.presentingViewController = self
      IncdOnboardingManager.shared.startOnboarding(sessionConfig: createSessionConfig(apTransactionId: apTransactionId), flowConfig: createFlowConfig(), delegate: self)
  }
  ```

* **Sending verification results to IDDataWeb and getting the policy decision:**
  Once the user completes the Incode BioGovID verification flow, we need to call a redirect URL to send the results to IDDataWeb and then call the `/slverify` endpoint to get the policy decision. 
  * **Sending results:**
  To send the results to IDDataWeb, we need to call the redirect() function with the redirect URL passed in.

  We need to add an extension to the IncdOnboardingDelegate `onSuccess()` function and call the `redirect()` method with the redirect URL passed in.
  ```
  extension ViewController: IncdOnboardingDelegate {
    func onSuccess() {
      print("onSuccess")
      
      // "Redirect Successful" will print in the logs if the call was successful
      let url = URL(string: "https://preprod1.iddataweb.com/axn/api/async-ui/redirect?apSessionId=\(apSessionId)&processResult=true&asi=\(transaction_id)")
      var redirectCall = axnApiObject.redirect(redirectUrl: url!)
    }
  }
  ```

* **Retrieving AXN policy decision:** 
  After the Incode verification data has been sent to IDDataWeb, it takes a few seconds for a policy decision to be made so we will make a separate button that calls the `/slverify` endpoint so our app does not immediately try to retrieve the decision. 
  ```
  @IBAction func getOnboardingResults(_ sender: UIButton) {
    var policyDecsionResult: [String: String]?
    policyDecsionResult = axnApiObject.callBioGovID(baseUrl: baseUrl, apiEndpoint: "/v1/slverify", bearerToken: token, forwardApiKey: "xxxxxx", asi: transaction_id)
    
    print(policyDecsionResult)
  }
  ```
  This example simply prints the policyDecision variable, but you can add a UILabel to display the results on the screen. After the button is pressed you will see if the user was approved, denied, or obligated to another verification service. You will also see the AXN transaction ID so you can look it up in the Admin Console and get more details about the transaction.
