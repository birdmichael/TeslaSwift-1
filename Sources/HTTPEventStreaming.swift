//
//  HTTPEventStreaming.swift
//  TeslaSwift
//
//  Created by Joao Nunes on 29/04/2017.
//  Copyright © 2017 Joao Nunes. All rights reserved.
//

import Foundation

class HTTPEventStreaming: NSObject {
	
	var retryTime = 3000
	
	var configuration: URLSessionConfiguration
	var task: URLSessionDataTask?
	var session: URLSession?
	
	var url: URL?
	var username: String?
	var password: String?
	
	var openCallback: (() -> ())?
	var callback: ((String) -> ())?
	var errorCallback: ((Error?) -> ())?
	
	override init() {
		configuration = URLSessionConfiguration.default
		configuration.timeoutIntervalForRequest = TimeInterval(INT_MAX)
		configuration.timeoutIntervalForResource = TimeInterval(INT_MAX)
		
		super.init()
	}
	
	func connect(url: URL, username: String, password: String) {
		
		session = URLSession(configuration: configuration,
		                     delegate: self,
		                     delegateQueue: nil)
		
		self.url = url
		self.username = username
		self.password = password
		
		let request = prepareRequest(url: url, username: username, password: password)
		task = session?.dataTask(with: request)
		task?.resume()
	}
	
	func prepareRequest(url: URL, username: String, password: String) -> URLRequest {
		var request = URLRequest(url: url)
		request.allHTTPHeaderFields = prepareHeaders(username: username, password: password)
		return request
	}
	
	func prepareHeaders(username: String, password: String) -> [String:String] {
		var headers: [String: String] = [:]
		headers["Accept"] = "*/*"
		headers["Cache-Control"] = "no-cache"
		headers["Authorization"] = basicAuth(username: username, password: password)
		return headers
	}
	
	func basicAuth(username: String, password: String) -> String {
		let authString = "\(username):\(password)"
		let authData = authString.data(using: String.Encoding.utf8)
		let base64String = authData!.base64EncodedString(options: [])
		
		return "Basic \(base64String)"
	}
	
	func disconnect() {
		task?.cancel()
		session?.invalidateAndCancel()
		openCallback = nil
		callback = nil
		errorCallback = nil
	}
}

extension HTTPEventStreaming: URLSessionDataDelegate {
	
	open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		
		if let stringData = String(data: data, encoding: String.Encoding.utf8) {
			for string in stringData.components(separatedBy: "\r\n").dropLast() {
				callback?(string)
			}
		}
	}
	
	open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
		completionHandler(URLSession.ResponseDisposition.allow)
		
		openCallback?()
	}
	
	open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		
		if error == nil || (error as NSError?)?.code != -999 {
			let nanoseconds = Double(retryTime) / 1000.0 * Double(NSEC_PER_SEC)
			let delayTime = DispatchTime.now() + Double(Int64(nanoseconds)) / Double(NSEC_PER_SEC)
			DispatchQueue.main.asyncAfter(deadline: delayTime) {
				if let url = self.url, let username = self.username, let password = self.password {
					self.connect(url: url, username: username, password: password)
				}
			}
		}
		
		self.errorCallback?(error)
	}
}
