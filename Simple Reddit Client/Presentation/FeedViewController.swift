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
            
            if state.loading != self.tableView.refreshControl?.isRefreshing ?? false {
                state.loading ? self.tableView.refreshControl?.beginRefreshing() : self.tableView.refreshControl?.endRefreshing()
            }
            
            self.lastItemID = state.posts.last?.id
            
            var snap = NSDiffableDataSourceSnapshot<FeedSection, PostViewModel>()
            snap.appendSections([.all])
            snap.appendItems(state.posts)
            
            self.dataSource.apply(snap)
            
            guard let visibleItemID = self.visibleItemID, let vm = state.posts.first(where: { $0.id == visibleItemID }) else { return }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let index = self.dataSource.indexPath(for: vm) else { return }
                
                self.tableView.scrollToRow(at: index, at: .top, animated: false)
                self.visibleItemID = nil
            }
        }
        
        dataSource.defaultRowAnimation = .fade
        tableView.prefetchDataSource = self
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
    
    @objc func refresh() {
        viewModel.handle(action: .refresh)
    }
    
    override func updateUserActivityState(_ activity: NSUserActivity) {
        super.updateUserActivityState(activity)
        
        guard let resultIndex = tableView.indexPathsForVisibleRows?.min(), let vm = dataSource.itemIdentifier(for: resultIndex) else { return }
        let info: [AnyHashable: Any] = [Constants.Keys.visibleItem: vm.id,
                                        Constants.Keys.lastItem: lastItemID as Any]
        activity.addUserInfoEntries(from: info)
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
