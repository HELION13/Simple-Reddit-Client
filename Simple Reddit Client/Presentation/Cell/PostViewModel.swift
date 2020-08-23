//
//  PostViewModel.swift
//  Simple Reddit Client
//
//  Created by Артур Фещенко on 20.08.2020.
//  Copyright © 2020 Arthur Feshchenko. All rights reserved.
//

import Foundation

class PostViewModel {
    let id: String
    let title: String
    let author: String
    let numComments: Int
    let subredditNamePrefixed: String
    let postDate: String
    var thumbnail: ((URL?) -> Void)?
    let thumbnailAspect: Double?
    private(set) var localThumbURL: URL?
    private(set) var thumbnailTask: URLSessionDownloadTask?
    let originalImage: URL?
    
    init(model: Post, dateString: String, networkService: NetworkService) {
        id = model.id
        title = model.title
        author = model.author
        numComments = model.numComments
        subredditNamePrefixed = model.subredditNamePrefixed
        postDate = dateString
        originalImage = model.url
        thumbnailTask = nil
        
        if let width = model.thumbnailWidth, let height = model.thumbnailHeight {
            thumbnailAspect = Double(width) / Double(height)
        } else {
            thumbnailAspect = nil
        }
        
        if let thumbnailURL = model.thumbnail {
            thumbnailTask = networkService.imageTask(for: thumbnailURL, completion: { [weak self] (result: Result<URL, NetworkServiceError>) in
                switch result {
                case .success(let url):
                    self?.localThumbURL = url
                    self?.thumbnail?(url)
                case .failure(_):
                    print(thumbnailURL)
                    self?.thumbnail?(nil)
                }
            })
        }
    }
}

extension PostViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension PostViewModel: Equatable {
    static func == (lhs: PostViewModel, rhs: PostViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
