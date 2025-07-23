//
//  appClipDemoViewModel.swift
//  appClipDemo
//
//  Created by Ben Goumalatsos on 10/8/24.
//

import Foundation

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

        // print(payload.prettyPrintedJSONString ?? "Couldnt format JSON")
        
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
    
    public func uploadTMXData(baseUrl: String, apiEndpoint: String, bearerToken: String, forwardApiKey: String, asi: String?, apSessionId: String?) -> [String: String] {
        var newForwardApiKey: String = ""
        var policyDecision: String = ""
        var transaction_id: String = ""
        var attributeList: [userAttribute] = []
        
        let apSessionIDAttribute = userAttribute(
            attributeType: "APSessionID",
            values: ["apSessionId": apSessionId!]
        )
        
        attributeList = [apSessionIDAttribute]
        
        let messageBody = messageBody(
            asi: asi,
            apikey: forwardApiKey,
            credential: "appClipTest",
            appID: "IDWAppClipTest",
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
        
        let (data, _, error) = URLSession.shared.synchronousDataTask(urlrequest: request)
        if let error = error {
            print("there was an error")
        } else {
            do {
                let decoder = JSONDecoder()
                let json = try decoder.decode(responseBody.self, from: data!)
                
                print(json)
                
                if json.forwardApiKey != nil {
                    newForwardApiKey = json.forwardApiKey!
                    policyDecision = json.policyDecision!
                } else {
                    print("forwardApiKey is nil")
                }
                
                if json.transaction_id != nil {
                    transaction_id = json.transaction_id!
                }
                
            } catch {
                print("cant serialize: \(error)")
            }
        }
        
        let response = ["policyDecision": policyDecision, "forwardApiKey": newForwardApiKey, "transaction_id": transaction_id]
        return response
    }
}

class adminApi: ObservableObject {
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
            print("there was an error making the request: \(error)")
        } else {
            do {
                let decoder = JSONDecoder()
                let json = try decoder.decode(tokenResponse.self, from: data!)
                tokenString = json.access_token
            } catch {
                print("cant serialize")
            }
        }

        return tokenString!
    }
    
    public func getServiceInfo(baseUrl: String, apiEndpoint: String, bearerToken: String, method: String) -> [String]? {
        let url = URL(string: baseUrl + apiEndpoint)
        var request = URLRequest(url: url!)
        
        request.httpMethod = method
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer " + bearerToken, forHTTPHeaderField: "Authorization")
        
        var apiKey: String?
        var sharedSecret: String?
        var logoUrlProperty: String?
        
        let (data, _, error) = URLSession.shared.synchronousDataTask(urlrequest: request)
        if let error = error {
            print("there was an error making the request: \(error)")
        } else {
            do {
                let decoder = JSONDecoder()
                let json = try decoder.decode(adminResponseBody?.self, from: data!)
                apiKey = json?.apiKey!
                sharedSecret = json?.sharedSecret!
                for property in json!.properties! {
                    if property["propertyID"] == "259" {
                        logoUrlProperty = String(property["value"]!.split(separator: "\"")[5])
                    }
                }
                
                // Handle cases where services dont have a logo property configured
                if logoUrlProperty == nil {
                    // Set logo to default "Identity Proofing" image
                    logoUrlProperty = "https://rpservice-images-preprod.s3.amazonaws.com/logo/logo-w100246-085835.png"
                }
                
                return [logoUrlProperty!, apiKey!, sharedSecret!]
                
            } catch {
                print("Error decoding JSON response: \(error)")
            }
        }
                
        return nil
    }
}

extension Data {
    var prettyPrintedJSONString: NSString? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
        let data = try? JSONSerialization.data(withJSONObject: jsonObject,
                                               options: [.prettyPrinted]),
        let prettyJSON = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            return nil
         }

        return prettyJSON
    }
}
