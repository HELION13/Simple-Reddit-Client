//
//  ListingParams.swift
//  Simple Reddit Client
//
//  Created by Артур Фещенко on 20.08.2020.
//  Copyright © 2020 Arthur Feshchenko. All rights reserved.
//

struct ListingParams: Encodable {
    let after: String?
    let before: String?
    let limit: Int
    let count: Int?
}
