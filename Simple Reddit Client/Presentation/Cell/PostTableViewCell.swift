//
//  PostTableViewCell.swift
//  Simple Reddit Client
//
//  Created by Артур Фещенко on 20.08.2020.
//  Copyright © 2020 Arthur Feshchenko. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {
    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var subreddit: UILabel!
    @IBOutlet private weak var user: UILabel!
    @IBOutlet private weak var time: UILabel!
    @IBOutlet private weak var thumbContainer: UIView!
    @IBOutlet private weak var thumbnail: UIImageView!
    @IBOutlet private weak var downloadProgress: UIProgressView!
    @IBOutlet private weak var commentCount: UILabel!
    @IBOutlet private weak var thumbButton: UIButton!
    @IBOutlet private weak var shareButton: UIButton!
    
    var viewModel: PostViewModel! {
        didSet {
            title.text = viewModel.title
            subreddit.text = viewModel.subredditNamePrefixed
            user.text = "u/\(viewModel.author)"
            time.text = viewModel.postDate
            commentCount.text = "\(viewModel.numComments)"
            thumbContainer.isHidden = viewModel.thumbnail == nil
        }
    }
    
    var thumbnailPressed: (() -> Void)?
    
    @IBAction private func thumbnailButtonPressed() {
        thumbnailPressed?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        downloadProgress.observedProgress = nil
        downloadProgress.isHidden = true
        thumbContainer.isHidden = true
        thumbnail.image = nil
    }
}
