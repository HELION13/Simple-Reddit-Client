//
//  DependencyContainer.swift
//  Simple Reddit Client
//
//  Created by Артур Фещенко on 21.08.2020.
//  Copyright © 2020 Arthur Feshchenko. All rights reserved.
//

import Foundation
import class UIKit.UIStoryboard

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
    
    func resolve() -> FeedViewController {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "Feed") as! FeedViewController
        controller.viewModel = resolve()
        
        return controller
    }
}
