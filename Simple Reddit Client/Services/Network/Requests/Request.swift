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
    case top(ListingParams)
    
    var url: URL {
        switch self {
        case .token:
            return Constants.authURL.appendingPathComponent("/access_token")
        case .top(let params):
            let limitItem = URLQueryItem(name: "limit", value: "\(params.limit)")
            let beforeItem = URLQueryItem(name: "before", value: params.before)
            let afterItem = URLQueryItem(name: "after", value: params.after)
            var items = [limitItem, beforeItem, afterItem]
            if let count = params.count {
                items.append(URLQueryItem(name: "count", value: "\(count)"))
            }
            let url = Constants.baseURL.appendingPathComponent("/r/all/top")
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            comps.queryItems = items
            return comps.url!
        }
    }
    
    var method: Method {
        switch self {
        case .token:
            return .POST
        case .top:
            return .GET
        }
    }
    
    var body: Data? {
        switch self {
        case .token(let params):
            let params = "grant_type=\(params.grantType)&device_id=\(Constants.deviceId)"
            return params.data(using: .utf8)
        case .top:
            return nil
        }
    }
    
    var additionalHeaders: [String: String]? {
        switch self {
        case .token(let params):
            return ["Content-Type": "application/x-www-form-urlencoded",
                    "Authorization": "Basic \(params.baseAuth)"]
        case .top:
            return nil
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
