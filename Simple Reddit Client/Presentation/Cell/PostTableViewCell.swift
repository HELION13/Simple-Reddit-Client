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
    private weak var thumbnailAspect: NSLayoutConstraint? {
        didSet {
            if let oldValue = oldValue {
                thumbnail.removeConstraint(oldValue)
            }
            if let thumbnailAspect = thumbnailAspect {
                thumbnail.addConstraint(thumbnailAspect)
            }
        }
    }
    @IBOutlet private weak var downloadProgress: UIProgressView!
    @IBOutlet private weak var commentCount: UILabel!
    @IBOutlet private weak var thumbButton: UIButton!
    @IBOutlet private weak var shareButton: UIButton!
    
    private var handle: TaskHandle?
    
    var viewModel: PostViewModel! {
        didSet {
            title.text = viewModel.title
            subreddit.text = viewModel.subredditNamePrefixed
            user.text = "u/\(viewModel.author)"
            time.text = viewModel.postDate
            commentCount.text = "\(viewModel.numComments)"
            thumbContainer.isHidden = viewModel.thumbnailAspect == nil
            shareButton.isHidden = !imageValid()
            
            if let ratio = viewModel.thumbnailAspect {
                let constraint = thumbnail.widthAnchor.constraint(equalTo: thumbnail.heightAnchor, multiplier: CGFloat(ratio))
                constraint.priority = .defaultHigh

                thumbnailAspect = constraint
            }
            
            handle = viewModel.thumbnailTask(completion: { [weak self] (image) in
                guard let self = self else { return }
                self.downloadProgress.isHidden = true
                self.thumbContainer.isHidden = image == nil
                self.thumbnail.image = image
            })
            
            downloadProgress.isHidden = false
            downloadProgress.observedProgress = handle?.taskProgress
            handle?.resume()
        }
    }
    
    var thumbnailPressed: (() -> Void)?
    var sharePressed: ((UIImage, URL) -> Void)?
    
    private func imageValid() -> Bool {
        guard let originalURL = viewModel.originalContent, originalURL.pathExtension == "jpg" || originalURL.pathExtension == "png", viewModel.thumbnailAspect != nil else { return false }
        return true
    }
    
    @IBAction private func thumbnailButtonPressed() {
        thumbnailPressed?()
    }
    
    @IBAction private func shareButtonPressed() {
        guard let placeholder = thumbnail.image, let originalURL = viewModel.originalContent,
            originalURL.pathExtension == "jpg" || originalURL.pathExtension == "png" else { return }
        sharePressed?(placeholder, originalURL)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        handle?.cancel()
        handle = nil
        downloadProgress.observedProgress = nil
        downloadProgress.isHidden = true
        thumbContainer.isHidden = true
        thumbnail.image = nil
    }
}
