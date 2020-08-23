//
//  Constants.swift
//  Simple Reddit Client
//
//  Created by Артур Фещенко on 20.08.2020.
//  Copyright © 2020 Arthur Feshchenko. All rights reserved.
//

import Foundation

enum Constants {
    static let baseAuth = "LXhBdGp0OGlMRG0wRWc6"
    static let deviceId = "DO_NOT_TRACK_THIS_DEVICE"
    static let grantType = "https://oauth.reddit.com/grants/installed_client"
    static let authURL = URL(string: "https://www.reddit.com/api/v1")!
    static let baseURL = URL(string: "https://oauth.reddit.com")!
    static let selfThumbURL = URL(string: "https://www.reddit.com/static/self_default2.png")!
    static let defaultThumbURL = URL(string: "https://www.reddit.com/static/noimage.png")!
    static let nsfwThumbURL = URL(string: "https://www.reddit.com/static/nsfw2.png")!
    static let pageSize: Int = 25
    
    enum Keys {
        static let tableOffset = "tableOffset"
        static let lastItem = "lastItem"
        static var activityKey: String {
            (Bundle.main.object(forInfoDictionaryKey: "NSUserActivityTypes") as? [String])?.first ?? ""
        }
    }
}
