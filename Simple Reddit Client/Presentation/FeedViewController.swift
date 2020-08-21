//
//  FeedViewController.swift
//  Simple Reddit Client
//
//  Created by Артур Фещенко on 20.08.2020.
//  Copyright © 2020 Arthur Feshchenko. All rights reserved.
//

import UIKit

enum FeedSection {
    case all
}

class FeedViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var viewModel: FeedViewModel! = DependencyContainer().resolve()
    var dataSource: UITableViewDiffableDataSource<FeedSection, PostViewModel>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRefreshControll()
        setupDatasource()
        viewModel.didLoad()
    }
    
    private func setupRefreshControll() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        refreshControl.tintColor = #colorLiteral(red: 0.1411764706, green: 0.6274509804, blue: 0.9294117647, alpha: 1)
        tableView.refreshControl = refreshControl
        refreshControl.beginRefreshing()
    }
    
    private func setupDatasource() {
        dataSource = UITableViewDiffableDataSource<FeedSection, PostViewModel>(tableView: tableView) { [weak self] (tableView, ip, viewModel) -> UITableViewCell? in
            return self?.setupCell(for: ip, with: viewModel)
        }
        
        viewModel.postsUpdated = { [weak self] (viewModels) in
            guard let self = self else { return }
            self.tableView.refreshControl?.endRefreshing()
            var snap = NSDiffableDataSourceSnapshot<FeedSection, PostViewModel>()
            snap.appendSections([.all])
            snap.appendItems(viewModels)
            
            self.dataSource.apply(snap)
        }
        
        dataSource.defaultRowAnimation = .fade
        tableView.prefetchDataSource = self
    }
    
    private func setupCell(for ip: IndexPath, with viewModel: PostViewModel) -> UITableViewCell? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: ip) as? PostTableViewCell
        
        cell?.viewModel = viewModel
        
        cell?.thumbnailPressed = { [weak self] in
            guard let vm = self?.dataSource.itemIdentifier(for: ip), let imageURL = vm.originalImage else { return }
            UIApplication.shared.open(imageURL, options: [:], completionHandler: nil)
        }
        
        cell?.sharePressed = { [weak self] image, originalURL in
            let imageProvider = RedditImageItemProvider(placeholderImage: image, image: originalURL)
            
            let acivityController = UIActivityViewController(activityItems: [imageProvider], applicationActivities: nil)
            self?.present(acivityController, animated: true, completion: nil)
        }
        
        return cell
    }
    
    @objc func refresh() {
        viewModel.refresh()
    }
}

// MARK: - UITableViewDataSourcePrefetching
extension FeedViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let max = indexPaths.map { $0.row }.max() ?? 0
        viewModel.loadPosts(at: max)
    }
}
