//
//  Untitled.swift
//  appClipIncode
//
//  Created by Ben Goumalatsos on 5/20/25.
//

import Foundation

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

struct messageBody: Codable {
    var asi: String?
    var apikey: String?
    var credential: String?
    var appID: String?
    var country: String?
    var userAttributes: [userAttribute]?
}

struct responseBody: Decodable {
    var errorCode: String?
    var errorDescription: String?
    var transaction_id: String?
    var asi: String?
    var incodeUrl: String?
    var policyDecision: String?
    var forwardApiKey: String?
    var status: String?
    var services: [[String: String]]?
}

struct adminResponseBody: Decodable {
    var properties: [[String: String]]?
    var apiKey: String?
    var sharedSecret: String?
}

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
