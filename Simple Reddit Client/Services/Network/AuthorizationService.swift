//
//  AuthorizationService.swift
//  Simple Reddit Client
//
//  Created by Артур Фещенко on 20.08.2020.
//  Copyright © 2020 Arthur Feshchenko. All rights reserved.
//

import Foundation

protocol AutorizationService {
    func authorize(completion: @escaping (Result<URLSession, AuthrizationServiceError>) -> Void)
}

enum AuthrizationServiceError: Error {
    case authorizationFailed
    case decodingFailed
    case other(String)
    
    var localizedDescription: String {
        switch self {
        case .authorizationFailed, .decodingFailed:
            return "Application failed to authorize"
        case .other(let message):
            return message
        }
    }
}

struct AuthorizationServiceImpl: AutorizationService {
    let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    func authorize(completion: @escaping (Result<URLSession, AuthrizationServiceError>) -> Void) {
        let request = Request.token(.init(grantType: Constants.grantType,
                                          deviceId: Constants.deviceId,
                                          baseAuth: Constants.baseAuth))
        let urlRequest = request.urlRequest
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                completion(.failure(.other(error.localizedDescription)))
                return
            }
            guard let data = data, let response = response as? HTTPURLResponse, response.statusCode != 401 else {
                completion(.failure(.authorizationFailed))
                return
            }
            guard let tokenResponse = try? self.decoder.decode(TokenResponse.self, from: data) else {
                completion(.failure(.decodingFailed))
                return
            }
            
            let config = URLSessionConfiguration.default
            config.httpAdditionalHeaders = ["Authorization": "Bearer \(tokenResponse.accessToken)"]
            config.timeoutIntervalForRequest = 15.0
            let session = URLSession(configuration: config)
            
            completion(.success(session))
        }
        
        task.resume()
    }
}
