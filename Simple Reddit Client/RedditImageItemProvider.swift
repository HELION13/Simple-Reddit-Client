//
//  RedditImageItemProvider.swift
//  Simple Reddit Client
//
//  Created by Артур Фещенко on 21.08.2020.
//  Copyright © 2020 Arthur Feshchenko. All rights reserved.
//

import UIKit

class RedditImageItemProvider: UIActivityItemProvider {
    let imageURL: URL
    init(placeholderImage: UIImage, image: URL) {
        self.imageURL = image
        super.init(placeholderItem: placeholderImage)
    }
    
    override var item: Any {
        guard let imageData = try? Data(contentsOf: imageURL), let image = UIImage(data: imageData) else { return UIImage() }
        return image
    }
}
