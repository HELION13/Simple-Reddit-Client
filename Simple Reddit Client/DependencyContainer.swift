//
//  DependencyContainer.swift
//  Simple Reddit Client
//
//  Created by Артур Фещенко on 21.08.2020.
//  Copyright © 2020 Arthur Feshchenko. All rights reserved.
//

import Foundation

class DependencyContainer {
    func resolve() -> AutorizationService {
        return AuthorizationServiceImpl()
    }
    
    func resolve() -> NetworkService {
        return NetworkServiceImpl(authorizationService: resolve())
    }
    
    func resolve() -> FeedViewModel {
        return FeedViewModelImpl(networkService: resolve())
    }
}
