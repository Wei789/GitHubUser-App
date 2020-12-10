//
//  Router.swift
//  PureSwiftNetwork
//
//  Created by Weichen Cheng_鄭惟臣 on 2018/5/31.
//  Copyright © 2018年 Weichen Cheng_鄭惟臣. All rights reserved.
//

import Foundation


protocol NetworkRouter: class {
    associatedtype EndPoint: EndPointType
    func request<T: Codable>(_ route: EndPoint, completion: ((_ data: T?, _ error: String?, _ linkHeader: String?) -> ())?)
    func cancel()
}

class Router<EndPoint: EndPointType>: NetworkRouter {
    private let environment : NetworkEnvironment = .production
    private let session = URLSession(configuration: .default)
    private var task: URLSessionTask!
    private var environmentBaseURL: URL {
        switch environment {
        case .production: return URL(string: "https://api.github.com/")!
        case .qa: return URL(string: "")!
        case .staging: return URL(string: "")!
        }
    }
    
    func request<T: Codable>(_ route: EndPoint, completion: ((_ data: T?, _ error: String?, _ linkHeader: String?) -> ())?) {
        do {
            let request = try self.buildRequest(from: route)
            print(request.url ?? "")
            task = session.dataTask(with: request) { (data, response, error) in
                if let response = response as? HTTPURLResponse {
                    let linkHeader = response.allHeaderFields["Link"] as? String
                    let responseResult: Result<T> = self.handleNetworkResponse(response, data)
                    switch responseResult {
                    case .success(let result):
                        completion?(result, nil, linkHeader)
                    case .failure(let networkFailureError):
                        completion?(nil, networkFailureError, nil)
                    case .parserDataFailure(let parserDataFailureError):
                        completion?(nil, parserDataFailureError, nil)
                    case .buildRequestFailure(let buildRequestFailureError):
                        completion?(nil, buildRequestFailureError, nil)
                    }
                }
            }
        } catch {
            completion?(nil, "requestFailure", nil)
        }
        
        self.task.resume()
    }
    
    func cancel() {
        self.task?.cancel()
    }
}

extension Router {
    fileprivate func buildRequest(from route: EndPointType) throws -> URLRequest {
        var baseURL = environmentBaseURL
        if let url = route.baseURL {
            baseURL = url
        }
        
        var request = URLRequest(url: baseURL.appendingPathComponent(route.path), cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0)
        request.httpMethod = route.httpMethod.rawValue
        do {
            switch route.task {
            case .request:
                request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "accept")
            case .requestPath(let path):
                request.url?.appendPathComponent(path)
            case .requestQuery(let queryString):
                if var urlStr = request.url?.absoluteString {
                    urlStr.append(queryString)
                    if let url = URL(string: urlStr) {
                        request.url = url
                    }
                }
            case .requestParameters(let bodyParameters, let urlParameters):
                try self.configueParameters(bodyParameters: bodyParameters,
                                            urlParameters: urlParameters,
                                            request: &request)
            case .requestParametersAndHeaders(let bodyParameters, let urlParameters, let additionHeaders):
                self.addAdditionalHeaders(additionHeaders, request: &request)
                try self.configueParameters(bodyParameters: bodyParameters,
                                            urlParameters: urlParameters,
                                            request: &request)
            }
            
            return request
        } catch {
            throw error
        }
    }
    
    fileprivate func configueParameters(bodyParameters: Parameters?, urlParameters: Parameters?, request:inout URLRequest) throws {
        do {
            if let bodyParameters = bodyParameters {
                try JSONParameterEncoder.encode(urlRequest: &request, with: bodyParameters)
            }
            
            if let urlParameters = urlParameters {
                try URLParameterEncoder.encode(urlRequest: &request, with: urlParameters)
            }
        } catch {
            throw error
        }
    }
    
    fileprivate func addAdditionalHeaders(_ additionalHeaders: HTTPHeaders?, request: inout URLRequest) {
        guard let headers = additionalHeaders else { return }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
    
    fileprivate func handleNetworkResponse<T: Codable>(_ response: HTTPURLResponse, _ data: Data?) -> Result<T> {
        switch response.statusCode {
        case 200...299:
            guard let data = data else {
                return .failure(NetworkResponse.noData.rawValue)
            }
            
            do {
                guard let result: T = try JSONParameterEncoder.decodeData(data: data) else {
                    return .parserDataFailure(NetworkResponse.unableToDecode.rawValue)
                }

                return .success(result)
            } catch {
                return .failure(NetworkResponse.unableToDecode.rawValue)
            }
        case 401...500:
            do {
                guard let data = data else {
                    return .failure(NetworkResponse.authenticationError.rawValue)
                }
                
                let message = try JSONParameterEncoder.decode(data: data)
                return .failure(message)
            } catch {
                return .failure(NetworkResponse.authenticationError.rawValue)
            }
        case 501...599: return .failure(NetworkResponse.badRequest.rawValue)
        case 600: return .failure(NetworkResponse.outdated.rawValue)
        default: return .failure(NetworkResponse.failed.rawValue)
        }
    }
}

enum Result<T: Codable>{
    case success(T)
    case failure(String)
    case parserDataFailure(String)
    case buildRequestFailure(String)
}

enum NetworkResponse:String {
    case success
    case authenticationError = "You need to be authenticated first."
    case badRequest = "Bad request"
    case outdated = "The url you requested is outdated."
    case failed = "Network request failed."
    case noData = "Response returned with no data to decode."
    case unableToDecode = "We could not decode the response."
}

enum NetworkEnvironment {
    case qa
    case production
    case staging
}
