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
    let thumbnail: URL?
    let originalImage: URL?
    
    init(model: Post, dateString: String) {
        id = model.id
        title = model.title
        author = model.author
        numComments = model.numComments
        subredditNamePrefixed = model.subredditNamePrefixed
        postDate = dateString
        thumbnail = model.thumbnail
        originalImage = model.url
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
