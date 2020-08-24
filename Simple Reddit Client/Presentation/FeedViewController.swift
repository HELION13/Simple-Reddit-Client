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
    var viewModel: FeedViewModel!
    private var dataSource: UITableViewDiffableDataSource<FeedSection, PostViewModel>!
    private var visibleItemID: String?
    private var lastItemID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRefreshControll()
        setupDatasource()
        
        viewModel.handle(action: .resotorePostsBefore(lastItemID))
    }
    
    private func setupRefreshControll() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        refreshControl.tintColor = #colorLiteral(red: 0.1411764706, green: 0.6274509804, blue: 0.9294117647, alpha: 1)
        tableView.refreshControl = refreshControl
    }
    
    private func setupDatasource() {
        dataSource = UITableViewDiffableDataSource<FeedSection, PostViewModel>(tableView: tableView) { [weak self] (tableView, ip, viewModel) -> UITableViewCell? in
            return self?.setupCell(for: ip, with: viewModel)
        }
        
        viewModel.stateUpdated = { [weak self] (state) in
            guard let self = self else { return }
            
            self.updateFeed(with: state)
        }
        
        dataSource.defaultRowAnimation = .fade
        tableView.prefetchDataSource = self
    }
    
    private func presentAlert(with message: String?) {
        guard let message = message else { return }
        
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "Ok", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func updateFeed(with state: FeedState) {
        presentAlert(with: state.errorMessage)
        
        if state.loading != tableView.refreshControl?.isRefreshing ?? false {
            state.loading ? tableView.refreshControl?.beginRefreshing() : tableView.refreshControl?.endRefreshing()
        }
        
        lastItemID = state.posts.last?.id
        
        var snap = NSDiffableDataSourceSnapshot<FeedSection, PostViewModel>()
        snap.appendSections([.all])
        snap.appendItems(state.posts)
        
        dataSource.apply(snap)
        
        guard let visibleItemID = visibleItemID, let vm = state.posts.first(where: { $0.id == visibleItemID }) else { return }
        
        self.scrollToRow(with: vm)
    }
    
    private func scrollToRow(with model: PostViewModel) {
        guard let index = dataSource.indexPath(for: model) else { return }
        
        tableView.scrollToRow(at: index, at: .top, animated: false)
        visibleItemID = nil
    }
    
    private func setupCell(for ip: IndexPath, with viewModel: PostViewModel) -> UITableViewCell? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: ip) as? PostTableViewCell
        
        cell?.viewModel = viewModel
        
        cell?.thumbnailPressed = { [weak self] in
            guard let vm = self?.dataSource.itemIdentifier(for: ip), let imageURL = vm.originalContent else { return }
            UIApplication.shared.open(imageURL, options: [:], completionHandler: nil)
        }
        
        cell?.sharePressed = { [weak self] image, originalURL in
            let imageProvider = RedditImageItemProvider(placeholderImage: image, image: originalURL)
            
            let acivityController = UIActivityViewController(activityItems: [imageProvider], applicationActivities: nil)
            self?.present(acivityController, animated: true, completion: nil)
        }
        
        return cell
    }
    
    @objc private func refresh() {
        viewModel.handle(action: .refresh)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let index = tableView.indexPathsForVisibleRows?.min()
        guard let ip = index else { return }

        tableView.scrollToRow(at: ip, at: .top, animated: true)

        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        super.restoreUserActivityState(activity)
        
        visibleItemID = activity.userInfo?[Constants.Keys.visibleItem] as? String
        lastItemID = activity.userInfo?[Constants.Keys.lastItem] as? String
    }
}

// MARK: - UITableViewDataSourcePrefetching
extension FeedViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let max = indexPaths.map { $0.row }.max() ?? 0
        viewModel.handle(action: .loadPostsAfter(max))
    }
}
