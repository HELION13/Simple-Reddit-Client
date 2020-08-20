//
//  FeedViewModel.swift
//  Simple Reddit Client
//
//  Created by Артур Фещенко on 20.08.2020.
//  Copyright © 2020 Arthur Feshchenko. All rights reserved.
//

import Foundation

protocol FeedViewModel {
    var postsUpdated: (([PostViewModel]) -> Void)? { get set }
    func didLoad()
    func refresh()
    func loadPosts(at index: Int)
}

class FeedViewModelImpl: FeedViewModel {
    private let networkService: NetworkService
    private var posts: [Post] = []
    private var postVms: [PostViewModel] = []
    private var lastItemIdentifier: String?
    private var loading = false
    private let calendar = Calendar.autoupdatingCurrent
    
    var postsUpdated: (([PostViewModel]) -> Void)?
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func didLoad() {
        refresh()
    }
    
    func refresh() {
        guard !loading else { return }
        
        let request = Request.top(.init(after: nil, before: nil, limit: 25, count: nil))
        loading = true
        performRequest(request, reset: true)
    }
    
    func loadPosts(at index: Int) {
        guard !loading, index >= posts.count - 5 else { return }
        
        let request = Request.top(.init(after: lastItemIdentifier, before: nil, limit: 25, count: posts.count))
        loading = true
        performRequest(request, reset: false)
    }
    
    private func performRequest(_ request: Request, reset: Bool) {
        networkService.execute(request) { [weak self] (result: Result<Listing<Post>, NetworkServiceError>) in
            guard let self = self else { return }
            switch result {
            case .success(let list):
                self.lastItemIdentifier = list.children.last?.name
                UserDefaults.standard.set(self.lastItemIdentifier, forKey: "lastItem")
                if reset {
                    self.replaceItems(list)
                } else {
                    self.appendItems(list)
                }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.postsUpdated?(self.postVms)
                }
            case .failure(let error):
                debugPrint(error.localizedDescription)
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.loading = false
            }
        }
    }
    
    private func replaceItems(_ list: Listing<Post>) {
        let currentDate = Date()
        self.posts = list.children
        let vms = list.children.map { PostViewModel(model: $0,
                                                    dateString: self.timeStringFrom(currentDate: currentDate, to: $0.createdUtc)) }
        self.postVms = vms
    }
    
    private func appendItems(_ list: Listing<Post>) {
        let currentDate = Date()
        self.posts.append(contentsOf: list.children)
        let vms = list.children.map { PostViewModel(model: $0,
                                                    dateString: self.timeStringFrom(currentDate: currentDate, to: $0.createdUtc)) }
        self.postVms.append(contentsOf: vms)
    }
    
    private func timeStringFrom(currentDate: Date, to postDate: Date) -> String {
        let timeDifference = currentDate.timeIntervalSince1970 - postDate.timeIntervalSince1970
        let dateDifference = Date(timeIntervalSince1970: timeDifference)
        if calendar.isDateInToday(postDate) {
            let hours = calendar.component(.hour, from: dateDifference)
            if hours == 0 {
                return "now"
            } else {
                return "\(hours)h"
            }
        } else {
            let days = calendar.component(.day, from: dateDifference)
            return "\(days)d"
        }
    }
}

