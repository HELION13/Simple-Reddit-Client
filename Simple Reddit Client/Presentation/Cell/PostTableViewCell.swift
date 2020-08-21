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
            thumbContainer.isHidden = viewModel.thumbnailTask == nil
            shareButton.isHidden = !imageValid()
            
            if let localURL = viewModel.localThumbURL {
                DispatchQueue.global(qos: .userInitiated).async {
                    guard let imageData = try? Data(contentsOf: localURL) else { return }
                    let image = UIImage(data: imageData)
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.thumbnail.image = image
                    }
                }
            } else {
                downloadProgress.isHidden = false
                downloadProgress.observedProgress = viewModel.thumbnailTask?.progress
                viewModel.thumbnail = { [weak self] (url) in
                    guard let url = url, let imageData = try? Data(contentsOf: url) else {
                        DispatchQueue.main.async { [weak self] in
                            self?.thumbContainer.isHidden = true
                        }
                        return
                    }
                    
                    let image = UIImage(data: imageData)
                    DispatchQueue.main.async { [weak self] in
                        self?.downloadProgress.isHidden = true
                        self?.thumbnail.image = image
                    }
                }
                viewModel.thumbnailTask?.resume()
            }
        }
    }
    
    var thumbnailPressed: (() -> Void)?
    var sharePressed: ((UIImage, URL) -> Void)?
    
    private func imageValid() -> Bool {
        guard let originalURL = viewModel.originalImage, originalURL.pathExtension == "jpg" || originalURL.pathExtension == "png" else { return false }
        return true
    }
    
    @IBAction private func thumbnailButtonPressed() {
        thumbnailPressed?()
    }
    
    @IBAction private func shareButtonPressed() {
        guard let placeholder = thumbnail.image, let originalURL = viewModel.originalImage,
            originalURL.pathExtension == "jpg" || originalURL.pathExtension == "png" else { return }
        sharePressed?(placeholder, originalURL)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel.thumbnailTask?.cancel()
        downloadProgress.observedProgress = nil
        downloadProgress.isHidden = true
        thumbContainer.isHidden = true
        thumbnail.image = nil
    }
}
