//
//  Listing.swift
//  Simple Reddit Client
//
//  Created by Артур Фещенко on 20.08.2020.
//  Copyright © 2020 Arthur Feshchenko. All rights reserved.
//

struct Listing<Value: Decodable> {
    enum ContainerKeys: String, CodingKey {
        case data
    }
    
    enum ListingKeys: String, CodingKey {
        case children
        case after
        case before
    }
    
    let children: [Value]
    let after: String?
    let before: String?
}

extension Listing: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ContainerKeys.self)
        let dataContainer = try container.nestedContainer(keyedBy: ListingKeys.self, forKey: .data)
        
        children = try dataContainer.decode([Value].self, forKey: .children)
        after = try dataContainer.decodeIfPresent(String.self, forKey: .after)
        before = try dataContainer.decodeIfPresent(String.self, forKey: .before)
    }
}
