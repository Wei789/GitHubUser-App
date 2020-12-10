//
//  HTTPTask.swift
//  PureSwiftNetwork
//
//  Created by Weichen Cheng_鄭惟臣 on 2018/5/28.
//  Copyright © 2018年 Weichen Cheng_鄭惟臣. All rights reserved.
//

import Foundation


public typealias HTTPHeaders = [String : String]

public enum HTTPTask {
    case request
    case requestParameters(bodyParameters: Parameters?, urlParameters: Parameters?)
    case requestParametersAndHeaders(bodyParameters: Parameters?, urlParameters: Parameters?, additionHeaders: HTTPHeaders?)
}
