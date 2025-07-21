//
//  LemonBankProfilingConnections.swift
//  LemonBankSwift
//
//  Created by Samin Pour on 29/4/20.
//  Copyright © 2020 ThreatMetrix. All rights reserved.
//

import Foundation
import TMXProfiling
import TMXProfilingConnections

class IDWProfilingConnections: NSObject, TMXProfilingConnectionsProtocol {
    var urlSession   : URLSession!
    let timeoutSec   : TimeInterval = 20
    var inputStream  : InputStream?
    var outputStream : OutputStream?

    override init() {
        super.init()

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest  = timeoutSec;
        config.timeoutIntervalForResource = timeoutSec;

        let delegateQueue = OperationQueue.init()
        delegateQueue.maxConcurrentOperationCount = 1
        delegateQueue.name = "content.maxconnector.com"

        urlSession   = URLSession.init(configuration:config, delegate:nil, delegateQueue:delegateQueue)
        inputStream  = nil
        outputStream = nil
    }

    deinit {
        urlSession.finishTasksAndInvalidate()
    }

    func sendData(data:Data) -> Bool {
        var sizeWritten: Int? = 0
        var sendSuccess: Bool = true;
        var start             = NSDate();
        var timedOut:Bool     = false;
        do
        {
            if(((self.outputStream?.streamError) == nil) &&
               (self.outputStream?.streamStatus == Stream.Status.open || self.outputStream?.streamStatus == Stream.Status.opening))
            {
                while(!(self.outputStream?.hasSpaceAvailable ?? false))
                {
                    if(NSDate().timeIntervalSince(start as Date) > 10)
                    {
                        sendSuccess = false;
                        timedOut    = true;
                        break;
                    }
                    Thread.sleep(forTimeInterval: 0.1);
                }
                
                if(self.outputStream?.streamError == nil && !timedOut)
                {
                    sizeWritten = self.outputStream?.write(data)
                }
            }
            else
            {
                sendSuccess = false;
            }
        }
        return sizeWritten != 0 ? sendSuccess: false;
    }

// MARK: TMXProfilingConnectionsProtocol methods

    func httpProfilingRequest(url:URL, method:TMXProfilingConnectionMethod, headers:[AnyHashable : Any]?, postData:Data?, completionHandler:(@Sendable (Data?, Error?) -> Void)? = nil) {
        
        var request = URLRequest.init(url:url, cachePolicy:URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval:timeoutSec)
        request.httpMethod = (method == TMXProfilingConnectionMethod.post) ? "POST" : "GET"
        request.httpBody   = postData
        request.httpShouldHandleCookies = false
        if let headers = headers, ((headers as? [String : String]) != nil)
        {
            request.allHTTPHeaderFields = (headers as! [String : String])
        }

        let task : URLSessionTask = urlSession.dataTask(with:request) { (data, response, error) in

            if let completionHandler = completionHandler
            {
                completionHandler(data, error)
            }
            else
            {
                // Should not happen but it is good to have an indication
                print("completionHandler is nil")
            }
        }

        task.resume()
    }

    func cancelProfiling() {
        urlSession.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) in
            if dataTasks.count > 0
            {
                for dataTask in dataTasks
                {
                    if dataTask.state == URLSessionTask.State.running
                    {
                        dataTask.cancel()
                    }
                }
            }
        }
    }

    func resolveProfilingHostName(host: String) {
        var hints = addrinfo(
                ai_flags: AI_PASSIVE,
                ai_family: AF_UNSPEC,
                ai_socktype: SOCK_STREAM,
                ai_protocol: 0,
                ai_addrlen: 0,
                ai_canonname: nil,
                ai_addr: nil,
                ai_next: nil
            )
        var res: UnsafeMutablePointer<addrinfo>? = nil
        var status = getaddrinfo(host, nil, &hints, &res)
        if(status == 0)
        {
            freeaddrinfo(res)
        }
    }

    func socketProfilingRequest(host: String, port: Int32, data: Data) {
        let task = urlSession.streamTask(withHostName:host, port:Int(port))
        task.resume()

        task.write(data, timeout:timeoutSec) {
            error in

            if let error = error
            {
                let code = (error as NSError).code
                print("Stream write failure: \(code)")
            }

            task.closeWrite()
            task.closeRead()
        }
    }

    func sendSocketRequest(host: String, port: UInt16, data: Data, closeSocket: Bool, completionHandler: ((InputStream?, Error?) -> Void)? = nil) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if(self.outputStream == nil)
        {
            if(self.inputStream != nil)
            {
                self.inputStream!.close();
                self.inputStream = nil;
            }
            
            var readStream : Unmanaged<CFReadStream>?
            var writeStream : Unmanaged<CFWriteStream>?
            let host : CFString = NSString(string: host)
            let port : UInt32 = UInt32(port)
            CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, host, port, &readStream, &writeStream)

            inputStream = readStream!.takeRetainedValue()
            outputStream = writeStream!.takeRetainedValue()
            self.outputStream!.open();
            self.inputStream!.open();
        }
        
        var connectionError : NSError? = nil;
        if(data.count == 0 || port < 1 || host.count == 0)
        {
            connectionError = NSError(domain: "Incorrect arguments", code: NSURLErrorCannotConnectToHost, userInfo: nil)
        }
        else
        {
            if(!self.sendData(data:data))
            {
                connectionError = NSError(domain: "Send Socket Request failed", code: NSURLErrorCannotConnectToHost, userInfo: nil)
            }
            
            if(closeSocket)
            {
                self.closeSocket(host: host, port: port);
            }
        }
        if let completionHandler = completionHandler
        {
            completionHandler(self.inputStream, connectionError)
        }
    }

    func closeSocket(host: String, port: UInt16) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        if(self.outputStream != nil)
        {
            self.outputStream!.close();
            self.outputStream = nil;
        }
        
        if(self.inputStream != nil)
        {
            self.inputStream!.close();
            self.inputStream = nil;
        }
    }
}

extension OutputStream {
    func write(_ data: Data) -> Int {
        return data.withUnsafeBytes({ (rawBufferPointer: UnsafeRawBufferPointer) -> Int in
            let bufferPointer = rawBufferPointer.bindMemory(to: UInt8.self)
            return self.write(bufferPointer.baseAddress!, maxLength: data.count)
        })
    }
}
