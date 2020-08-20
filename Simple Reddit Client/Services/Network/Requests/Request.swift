//
//  Request.swift
//  Simple Reddit Client
//
//  Created by Артур Фещенко on 20.08.2020.
//  Copyright © 2020 Arthur Feshchenko. All rights reserved.
//

import Foundation

enum Request {
    enum Method: String {
        case GET
        case POST
        case PUT
        case UPDATE
        case DELETE
    }
    
    case token(TokenParams)
    
    var url: URL {
        switch self {
        case .token:
            return Constants.authURL.appendingPathComponent("/access_token")
        }
    }
    
    var method: Method {
        switch self {
        case .token:
            return .POST
        }
    }
    
    var body: Data? {
        switch self {
        case .token(let params):
            let params = "grant_type=\(params.grantType)&device_id=\(Constants.deviceId)"
            return params.data(using: .utf8)
        }
    }
    
    var additionalHeaders: [String: String]? {
        switch self {
        case .token(let params):
            return ["Content-Type": "application/x-www-form-urlencoded",
                    "Authorization": "Basic \(params.baseAuth)"]
        }
    }
    
    var urlRequest: URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = additionalHeaders
        request.httpBody = body
        
        return request
    }
}
