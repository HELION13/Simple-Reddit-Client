//
//  PostViewModel.swift
//  Simple Reddit Client
//
//  Created by Артур Фещенко on 20.08.2020.
//  Copyright © 2020 Arthur Feshchenko. All rights reserved.
//

import Foundation
import class UIKit.UIImage

class PostViewModel {
    let id: String
    let title: String
    let author: String
    let numComments: Int
    let subredditNamePrefixed: String
    let postDate: String
    let thumbnailAspect: Double?
    let originalContent: URL?
    private var thumbTaskHandle: TaskHandle?
    private let thumbURL: URL?
    private var localThumbURL: URL?
    private let networkService: NetworkService
    
    init(model: Post, dateString: String, networkService: NetworkService) {
        id = model.id
        title = model.title
        author = model.author
        numComments = model.numComments
        subredditNamePrefixed = model.subredditNamePrefixed
        postDate = dateString
        originalContent = model.url
        thumbURL = model.thumbnail
        
        if let width = model.thumbnailWidth, let height = model.thumbnailHeight {
            thumbnailAspect = Double(width) / Double(height)
        } else {
            thumbnailAspect = nil
        }
        
        self.networkService = networkService
    }
    
    func thumbnailTask(completion: @escaping ((UIImage?) -> Void)) -> TaskHandle? {
        guard let thumbnailURL = thumbURL else {
            completion(nil)
            return nil
        }
        
        if let localURL = localThumbURL {
            DispatchQueue.global(qos: .userInitiated).async {
                guard let imageData = try? Data(contentsOf: localURL), let image = UIImage(data: imageData) else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                
                DispatchQueue.main.async { completion(image) }
            }
            
            return nil
        }
        
        thumbTaskHandle = networkService.imageTask(for: thumbnailURL, completion: { [weak self] (result: Result<URL, NetworkServiceError>) in
            guard let self = self else { return }
            switch result {
            case .success(let url):
                self.localThumbURL = url
                guard let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData) else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                DispatchQueue.main.async { completion(image) }
            case .failure(_):
                DispatchQueue.main.async { completion(nil) }
            }
        })
        
        return thumbTaskHandle
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
