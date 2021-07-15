//
//  TapNetworkManager.swift
//  TapNetworkManager/Core
//
//  Copyright © 2019 Tap Payments. All rights reserved.
//
import Foundation

/// Network Manager class.
public class TapNetworkManager {
    
    // MARK: - Public -
    
    /// The logged in requests/responses since the init of the network manager till the moment
    public var loggedInApiCalls:[String] = []
    
    /// Request completion closure.
    public typealias RequestCompletionClosure = (URLSessionDataTask?, Any?, Error?) -> Void
    
    // MARK: Properties
    /// Defines if request logging enabled.
    public var isRequestLoggingEnabled = false
    
    /// Base URL.
    public private(set) var baseURL: URL
    
    /// Current active request operations
    public private(set) var currentRequestOperations: [TapNetworkRequestOperation] = []
    
    // MARK: Methods
    /// Creates an instance of TapNetworkManager with the base URL and session configuration.
    public required init(baseURL: URL, configuration: URLSessionConfiguration = .default) {
        
        self.baseURL = baseURL
        self.session = URLSession(configuration: configuration)
        // Clear the previous api calls, this should be empty by default but just in case :)
        loggedInApiCalls = []
    }
    
    /// Performs request operation and calls completion when request finishes.
    ///
    /// - Parameters:
    ///   - operation: Network request operation.
    ///   - completion: Completion closure that is called when request finishes.
    public func performRequest(_ operation: TapNetworkRequestOperation, completion: RequestCompletionClosure?) {
        
        var request: URLRequest
        do {
            
            request = try self.createURLRequest(from: operation)
            //TapLogger.log(with: request, bodyParmeters: operation.bodyModel?.body)
            if self.isRequestLoggingEnabled {
                
                loggedInApiCalls.append(self.log(request))
            }
            
            var dataTask: URLSessionDataTask?
            let dataTaskCompletion: (Data?, URLResponse?, Error?) -> Void = { [weak self] (data, response, anError) in
                
                //                guard let strongSelf = self else { return }
                if let operationIndex = self?.currentRequestOperations.firstIndex(of: operation) {
                    
                    self?.currentRequestOperations.remove(at: operationIndex)
                }
                
                if self?.isRequestLoggingEnabled ?? false {
                    
                    self?.loggedInApiCalls.append(self?.log(response, data: data, serializationType: operation.responseType) ?? "\n")
                    self?.loggedInApiCalls.append(self?.log(anError) ?? "\n")
                }
                
                if let d = data {
                    
                    do {
                        
                        let responseObject = try TapSerializer.deserialize(d, with: operation.responseType)
                        completion?(dataTask, responseObject, anError)
                        
                    } catch {
                        
                        completion?(dataTask, nil, error)
                    }
                    
                } else {
                    
                    completion?(dataTask, nil, anError)
                }
            }
            
            
            var loggString:String = "Request :\n========\n\(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")\nHeaders :\n------\n\(String(data: try! JSONSerialization.data(withJSONObject: (request.allHTTPHeaderFields ?? [:]), options: .prettyPrinted), encoding: .utf8 )!)"
            
            if let body = request.httpBody {
                loggString = "\(loggString)\nBody :\n-----\n\(String(data: try! JSONSerialization.data(withJSONObject: JSONSerialization.jsonObject(with: body, options: []), options: .prettyPrinted), encoding: .utf8 )!)\n---------------\n"
            }else{
                loggString = "\(loggString)\nBody :\n-----\n{\n}\n---------------\n"
            }
            print(loggString)
            loggedInApiCalls.append(loggString)
            
            let task = self.session.dataTask(with: request, completionHandler: dataTaskCompletion)
            dataTask = task
            operation.task = task
            task.resume()
            
            self.currentRequestOperations.append(operation)
            
        } catch {
            if isRequestLoggingEnabled {
                loggedInApiCalls.append(log(error))
            }
            completion?(nil, nil, error)
        }
    }
    
    
    /// Performs request operation and calls completion when request finishes.
    ///
    /// - Parameters:
    ///   - operation: Network request operation.
    ///   - completion: Completion closure that is called when request finishes.
    public func performRequest<T:Decodable>(_ operation: TapNetworkRequestOperation, completion: RequestCompletionClosure?,codableType:T.Type) {
        
        performRequest(operation) { (dataTask, data, error) in
            
            let loggString:String = "Response :\n========\n\(operation.httpMethod.rawValue) \(operation.path)\nHeaders :\n------\n\(String(data: try! JSONSerialization.data(withJSONObject: (dataTask?.response as? HTTPURLResponse)?.allHeaderFields ?? [:], options: .prettyPrinted), encoding: .utf8 )!)\nBody :\n-----\n\(String(data: try! JSONSerialization.data(withJSONObject: (data ?? [:]), options: .prettyPrinted), encoding: .utf8 )!)\n---------------\n"
            print(loggString)
            
            if let nonNullError = error {
                //TapLogger.log(urlRequest: dataTask?.originalRequest, error: nonNullError)
                completion?(dataTask, nil, nonNullError)
            }else if let jsonObject = data {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .fragmentsAllowed)
                    let decodedResponse = try JSONDecoder().decode(codableType, from: jsonData)
                    //TapLogger.log(urlRequest: dataTask?.originalRequest, apiResponse: jsonObject)
                    DispatchQueue.main.async {
                        completion?(dataTask, decodedResponse, error)
                    }
                } catch {
                    //TapLogger.log(urlRequest: dataTask?.originalRequest, error: error)
                    DispatchQueue.main.async {
                        completion?(dataTask, jsonObject, error)
                    }
                }
            }else {
                //TapLogger.log(urlRequest: dataTask?.originalRequest, error: error)
                DispatchQueue.main.async {
                    completion?(nil, nil, error)
                }
            }
        }
    }
    
    
    /// Cancels network request operation.
    ///
    /// - Parameter operation: Operation to cancel.
    public func cancelRequest(_ operation: TapNetworkRequestOperation) {
        
        operation.task?.cancel()
    }
    
    /// Cancels all request operations.
    public func cancelAllOperations() {
        
        self.currentRequestOperations.forEach { self.cancelRequest($0) }
    }
    
    // MARK: - Private -
    private struct Constants {
        
        fileprivate static let contentTypeHeaderName        = "Content-Type"
        fileprivate static let jsonContentTypeHeaderValue   = "application/json"
        fileprivate static let plistContentTypeHeaderValue  = "application/x-plist"
        
        @available(*, unavailable) private init() {}
    }
    
    // MARK: Properties
    private var session: URLSession
    
    // MARK: Methods
    private func createURLRequest(from operation: TapNetworkRequestOperation) throws -> URLRequest {
        
        let url = try self.prepareFullRequestURL(for: operation)
        let configuration = self.session.configuration
        var request = URLRequest(url: url, cachePolicy: configuration.requestCachePolicy, timeoutInterval: configuration.timeoutIntervalForRequest)
        
        request.httpMethod = operation.httpMethod.rawValue
        
        for (headerField, headerValue) in operation.additionalHeaders {
            
            if request.value(forHTTPHeaderField: headerField) == nil {
                
                request.addValue(headerValue, forHTTPHeaderField: headerField)
            }
        }
        
        if let bodyModel = operation.bodyModel {
            
            guard bodyModel.serializationType != .url else {
                
                throw TapNetworkError.serializationError(.wrongData)
            }
            
            request.httpBody = try TapSerializer.serialize(bodyModel.body, with: bodyModel.serializationType) as? Data
            
            if request.value(forHTTPHeaderField: Constants.contentTypeHeaderName) == nil {
                
                let value = self.requestContentTypeHeaderValue(for: bodyModel.serializationType)
                request.setValue(value, forHTTPHeaderField: Constants.contentTypeHeaderName)
            }
        }
        
        return request
    }
    
    private func prepareFullRequestURL(for operation: TapNetworkRequestOperation) throws -> URL {
        
        var relativePath: String
        
        if let urlModel = operation.urlModel {
            
            guard let serializedQuery = try TapSerializer.serialize(urlModel, with: .url) as? String else {
                
                throw TapNetworkError.serializationError(.wrongData)
            }
            
            relativePath = operation.path + serializedQuery
            
        } else {
            
            relativePath = operation.path
        }
        
        guard let resultingURL = URL(string: relativePath, relativeTo: self.baseURL)?.absoluteURL else {
            
            throw TapNetworkError.wrongURL(self.baseURL.absoluteString + relativePath)
        }
        
        return resultingURL
    }
    
    private func requestContentTypeHeaderValue(for dataType: TapSerializationType) -> String {
        
        switch dataType {
        
        case .json:
            
            return Constants.jsonContentTypeHeaderValue
            
        case .propertyList:
            
            return Constants.plistContentTypeHeaderValue
            
        default: return ""
        }
    }
    
    private func log(_ request: URLRequest, serializationType: TapSerializationType? = nil) -> String {
        
        var toBeLogged:String = "Request:\n---------------------\n"
        toBeLogged = "\(toBeLogged)\(request.httpMethod ?? "nil") \(request.url?.absoluteString ?? "nil")\n"
        toBeLogged = "\(toBeLogged)\(request.httpMethod ?? "nil") \(request.url?.absoluteString ?? "nil")\n"
        toBeLogged = "\(toBeLogged)\(self.log(request.allHTTPHeaderFields))"
        toBeLogged = "\(toBeLogged)\(self.log(request.httpBody, serializationType: serializationType))"
        
        print("---------------------------")
        toBeLogged = "\(toBeLogged)------------------------\n"
        return toBeLogged
    }
    
    private func log(_ response: URLResponse?, data: Data?, serializationType: TapSerializationType? = nil) -> String {
        
        guard let nonnullResponse = response else { return "" }
        var toBeLoggedString = ""
        print("Response:\n---------------------")
        toBeLoggedString = "Response:\n---------------------\n"
        
        
        if let url = nonnullResponse.url {
            
            print("URL: \(url.absoluteString)")
            toBeLoggedString = "\(toBeLoggedString)URL: \(url.absoluteString)\n"
        }
        
        guard let httpResponse = nonnullResponse as? HTTPURLResponse else {
            
            print("------------------------")
            toBeLoggedString = "\(toBeLoggedString)------------------------\n"
            return toBeLoggedString
        }
        
        print("HTTP status code: \(httpResponse.statusCode)")
        toBeLoggedString = "\(toBeLoggedString)HTTP status code: \(httpResponse.statusCode)\n"
        
        
        toBeLoggedString = "\(toBeLoggedString)\(self.log(httpResponse.allHeaderFields))"
        toBeLoggedString = "\(toBeLoggedString)\(self.log(data, serializationType: serializationType))"
        
        
        print("------------------------")
        toBeLoggedString = "\(toBeLoggedString)------------------------\n"
        return toBeLoggedString
    }
    
    private func log(_ error: Error?) -> String {
        
        guard let nonnullError = error else { return "" }
        print("Error: \(nonnullError)")
        return "Error: \(nonnullError)\n"
    }
    
    private func log(_ headerFields: [AnyHashable: Any]?) -> String {
        
        guard let nonnullHeaderFields = headerFields, nonnullHeaderFields.count > 0 else { return "\n" }
        
        let headersString = (nonnullHeaderFields.map { "\($0.key): \($0.value)" }).joined(separator: "\n")
        print("Headers:\n\(headersString)")
        return "\(headersString)\n"
    }
    
    private func log(_ data: Data?, serializationType: TapSerializationType?) -> String {
        
        guard let body = data else { return "" }
        
        let type = serializationType ?? .json
        
        guard let object = try? TapSerializer.deserialize(body, with: type) else { return "" }
        
        var jsonWritingOptions: JSONSerialization.WritingOptions
        if #available(iOS 11.0, *) {
            
            jsonWritingOptions = [.prettyPrinted, .sortedKeys]
            
        } else {
            
            jsonWritingOptions = [.prettyPrinted]
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: object, options: jsonWritingOptions),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            print("Body:\n\(jsonString)")
            return "Body:\n\(jsonString)\n"
        }
        
        return ""
    }
}
