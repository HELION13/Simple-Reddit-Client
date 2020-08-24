//
//  NetworkService.swift
//  Simple Reddit Client
//
//  Created by Артур Фещенко on 20.08.2020.
//  Copyright © 2020 Arthur Feshchenko. All rights reserved.
//

import Foundation

struct TaskHandle {
    private let task: URLSessionTask?
    var taskProgress: Progress? {
        task?.progress
    }
    
    init(task: URLSessionTask?) {
        self.task = task
    }
    
    func resume() {
        task?.resume()
    }
    
    func cancel() {
        task?.cancel()
    }
}

protocol NetworkService {
    @discardableResult func execute<Value: Decodable>(_ request: Request, completion: @escaping (Result<Value, NetworkServiceError>) -> Void) -> TaskHandle
    func imageTask(for url: URL, completion: @escaping (Result<URL, NetworkServiceError>) -> Void) -> TaskHandle
}

enum NetworkServiceError: Error {
    case unauthorized
    case decodingFailed
    case other(String)
    
    var localizedDescription: String {
        switch self {
        case .unauthorized:
            return "Application failed to authorize"
        case .decodingFailed:
            return "Hmm. Something is missing."
        case .other(let message):
            return message
        }
    }
}

class NetworkServiceImpl: NetworkService {
    let authorizationService: AutorizationService
    var session: URLSession?
    
    let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
    
    init(authorizationService: AutorizationService) {
        self.authorizationService = authorizationService
        
        authorizationService.authorize { [weak self] (result) in
            switch result {
            case .success(let session):
                self?.session = session
            case .failure:
                print(debugPrint("Authorization failed"))
            }
        }
    }
    
    
    private func retry<Value: Decodable>(request: Request, completion: @escaping (Result<Value, NetworkServiceError>) -> Void) {
        authorizationService.authorize { [weak self] (result) in
            switch result {
            case .success(let session):
                self?.session = session
                _ = self?.execute(request, completion: completion)
            case .failure:
                completion(.failure(.unauthorized))
            }
        }
    }
    
    func execute<Value: Decodable>(_ request: Request, completion: @escaping (Result<Value, NetworkServiceError>) -> Void) -> TaskHandle {
        guard let session = session else {
            retry(request: request, completion: completion)
            return TaskHandle(task: nil)
        }
        
        let urlRequest = request.urlRequest
        let task = session.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            if let error = error { return completion(.failure(.other(error.localizedDescription))) }
            guard let data = data, let response = response as? HTTPURLResponse else {
                completion(.failure(.other("No response")))
                return
            }
            guard response.statusCode != 401 else {
                self?.retry(request: request, completion: completion)
                return
            }
            guard (200..<300).contains(response.statusCode) else {
                completion(.failure(.other("Status - \(response.statusCode)")))
                return
            }
            guard let value = try? self?.decoder.decode(Value.self, from: data) else {
                completion(.failure(.decodingFailed))
                return
            }
            
            completion(.success(value))
        }
        
        task.resume()
        
        return TaskHandle(task: task)
    }
    
    func imageTask(for url: URL, completion: @escaping (Result<URL, NetworkServiceError>) -> Void) -> TaskHandle {
        let task = URLSession.shared.downloadTask(with: url) { (localURL, response, error) in
            if let error = error { return completion(.failure(.other(error.localizedDescription))) }
            guard let localURL = localURL, let response = response as? HTTPURLResponse else {
                completion(.failure(.other("No response")))
                return
            }
            guard (200..<300).contains(response.statusCode) else {
                completion(.failure(.other("Status - \(response.statusCode)")))
                return
            }
            
            completion(.success(localURL))
        }
        
        return TaskHandle(task: task)
    }
}
