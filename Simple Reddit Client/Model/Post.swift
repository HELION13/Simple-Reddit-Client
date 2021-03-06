//
//  Post.swift
//  Simple Reddit Client
//
//  Created by Артур Фещенко on 20.08.2020.
//  Copyright © 2020 Arthur Feshchenko. All rights reserved.
//

import Foundation

struct Post {
    enum ContainerKeys: String, CodingKey {
        case data
    }
    
    enum PostKeys: String, CodingKey {
        case id
        case name
        case title
        case author
        case numComments
        case subredditNamePrefixed
        case thumbnail
        case thumbnailWidth
        case thumbnailHeight
        case url
        case createdUtc
    }
    
    let id: String
    let name: String
    let title: String
    let author: String
    let numComments: Int
    let subredditNamePrefixed: String
    let thumbnail: URL?
    let thumbnailWidth: Int?
    let thumbnailHeight: Int?
    let url: URL?
    let createdUtc: Date
}

extension Post: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ContainerKeys.self)
        let dataContainer = try container.nestedContainer(keyedBy: PostKeys.self, forKey: .data)
        
        id = try dataContainer.decode(String.self, forKey: .id)
        name = try dataContainer.decode(String.self, forKey: .name)
        title = try dataContainer.decode(String.self, forKey: .title)
        author = try dataContainer.decode(String.self, forKey: .author)
        numComments = try dataContainer.decode(Int.self, forKey: .numComments)
        subredditNamePrefixed = try dataContainer.decode(String.self, forKey: .subredditNamePrefixed)
        
        if let urlString = try dataContainer.decodeIfPresent(String.self, forKey: .thumbnail) {
            switch urlString {
            case "self":
                thumbnail = nil
            case "default":
                thumbnail = Constants.defaultThumbURL
            case "nsfw":
                thumbnail = nil
            case "image":
                thumbnail = nil
            default:
                thumbnail = URL(string: urlString)
            }
        } else {
            thumbnail = nil
        }
        
        thumbnailWidth = try dataContainer.decodeIfPresent(Int.self, forKey: .thumbnailWidth)
        thumbnailHeight = try dataContainer.decodeIfPresent(Int.self, forKey: .thumbnailHeight)
        url = try? dataContainer.decodeIfPresent(URL.self, forKey: .url)
        createdUtc = try dataContainer.decode(Date.self, forKey: .createdUtc)
    }
}
