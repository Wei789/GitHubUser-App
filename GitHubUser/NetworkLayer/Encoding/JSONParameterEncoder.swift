//
//  JSONParameterEncoder.swift
//  PureSwiftNetwork
//
//  Created by Weichen Cheng_鄭惟臣 on 2018/5/31.
//  Copyright © 2018年 Weichen Cheng_鄭惟臣. All rights reserved.
//

import Foundation


class JSONParameterEncoder: ParameterEncoder {
    static func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws {
        do {
            let jsonAsData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            urlRequest.httpBody = jsonAsData
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        } catch {
            throw NetworkError.encodingFailed
        }
    }
    
    static func encode<T: Encodable>(urlRequest: inout URLRequest, with input: T) throws {
        do {
            let jsonAsData = try encodeData(data: input)
            urlRequest.httpBody = jsonAsData
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        } catch {
            throw NetworkError.encodingFailed
        }
    }
    
    static func decodeData<T: Decodable>(data: Data) throws -> T? {
        let decoder = JSONDecoder()
        do {
            let result = try decoder.decode(T.self, from: data)
            return result
        }catch {
            throw NetworkError.decodingFailed
        }
    }
    
    static func encodeData<T: Encodable>(data: T) throws -> Data? {
        do {
            let encoder = JSONEncoder()
            let result = try encoder.encode(data)
            return result
        } catch {
            throw NetworkError.encodingFailed
        }
    }
}
