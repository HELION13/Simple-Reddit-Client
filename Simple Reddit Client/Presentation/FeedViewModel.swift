//
//  FeedViewModel.swift
//  Simple Reddit Client
//
//  Created by Артур Фещенко on 20.08.2020.
//  Copyright © 2020 Arthur Feshchenko. All rights reserved.
//

import Foundation

protocol FeedViewModel {
    var stateUpdated: ((FeedState) -> Void)? { get set }
    func handle(action: FeedAction)
}

struct FeedState {
    let posts: [PostViewModel]
    let loading: Bool
    let errorMessage: String?
}

enum FeedAction {
    case resotorePostsBefore(String?)
    case refresh
    case loadPostsAfter(Int)
}

class FeedViewModelImpl: FeedViewModel {
    private let networkService: NetworkService
    private var posts: [Post] = []
    private var postVms: [PostViewModel] = []
    private var lastItemIdentifier: String?
    private var loading = false
    private let calendar = Calendar.autoupdatingCurrent
    
    var stateUpdated: ((FeedState) -> Void)?
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func handle(action: FeedAction) {
        switch action {
        case .resotorePostsBefore(let lastItemID):
            guard let lastID = lastItemID else {
                refresh()
                return
            }
            
            lastItemIdentifier = lastID
            restoreContent()
        case .refresh:
            refresh()
        case .loadPostsAfter(let lastIndex):
            loadPosts(after: lastIndex)
        }
    }
    
    private func restoreContent() {
        guard !loading else { return }
        
        let request = Request.top(.init(after: nil, before: lastItemIdentifier, limit: Constants.pageSize * 2, count: nil))
        loading = true
        stateUpdated?(.init(posts: postVms, loading: true, errorMessage: nil))
        performRequest(request, reset: true)
    }
    
    private func refresh() {
        guard !loading else { return }
        
        let request = Request.top(.init(after: nil, before: nil, limit: Constants.pageSize, count: nil))
        loading = true
        stateUpdated?(.init(posts: postVms, loading: true, errorMessage: nil))
        performRequest(request, reset: true)
    }
    
    private func loadPosts(after index: Int) {
        guard !loading, index >= posts.count - 5 else { return }
        
        let request = Request.top(.init(after: lastItemIdentifier, before: nil, limit: Constants.pageSize, count: posts.count))
        loading = true
        stateUpdated?(.init(posts: postVms, loading: true, errorMessage: nil))
        performRequest(request, reset: false)
    }
    
    private func performRequest(_ request: Request, reset: Bool) {
        networkService.execute(request) { [weak self] (result: Result<Listing<Post>, NetworkServiceError>) in
            guard let self = self else { return }
            switch result {
            case .success(let list):
                self.lastItemIdentifier = list.children.last?.name
                if reset {
                    self.replaceItems(list)
                } else {
                    self.appendItems(list)
                }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.stateUpdated?(.init(posts: self.postVms,
                                             loading: false,
                                             errorMessage: nil))
                    self.loading = false
                }
            case .failure(let error):
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.stateUpdated?(.init(posts: self.postVms,
                                             loading: false,
                                             errorMessage: error.localizedDescription))
                    self.loading = false
                }
            }
        }
    }
    
    private func replaceItems(_ list: Listing<Post>) {
        let currentDate = Date()
        self.posts = list.children
        let vms = list.children.map { PostViewModel(model: $0,
                                                    dateString: self.timeStringFrom(currentDate: currentDate, to: $0.createdUtc),
                                                    networkService: networkService) }
        self.postVms = vms
    }
    
    private func appendItems(_ list: Listing<Post>) {
        let currentDate = Date()
        self.posts.append(contentsOf: list.children)
        let vms = list.children.map { PostViewModel(model: $0,
                                                    dateString: self.timeStringFrom(currentDate: currentDate, to: $0.createdUtc),
                                                    networkService: networkService) }
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

