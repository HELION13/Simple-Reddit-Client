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
    private var dataSource: UITableViewDiffableDataSource<FeedSection, PostViewModel>!
    private var tableOffset: Int?
    private var lastItemID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRestoration()
        setupRefreshControll()
        setupDatasource()
        restoreStateIfNeeded()
    }
    
    private func restoreStateIfNeeded() {
        tableOffset = UserDefaults.standard.integer(forKey: Constants.Keys.tableOffset)
        let lastItem = UserDefaults.standard.value(forKey: Constants.Keys.lastItem) as? String
        
        viewModel.handle(action: .resotorePostsBefore(lastItem))
    }
    
    private func setupRestoration() {
        NotificationCenter.default.addObserver(self, selector: #selector(saveState), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc private func saveState() {
        let resultIndex = (tableView.indexPathsForVisibleRows?.max()?.row ?? 0) % (Constants.pageSize * 2)
        UserDefaults.standard.setValue(resultIndex, forKey: Constants.Keys.tableOffset)
        UserDefaults.standard.setValue(lastItemID, forKey: Constants.Keys.lastItem)
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
            
            state.loading ? self.tableView.refreshControl?.beginRefreshing() : self.tableView.refreshControl?.endRefreshing()
            self.lastItemID = state.posts.last?.id
            
            var snap = NSDiffableDataSourceSnapshot<FeedSection, PostViewModel>()
            snap.appendSections([.all])
            snap.appendItems(state.posts)
            
            self.dataSource.apply(snap)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let offset = self.tableOffset, offset < state.posts.count else { return }
                
                self.tableView.scrollToRow(at: IndexPath(row: offset, section: 0), at: .bottom, animated: false)
                self.tableOffset = nil
            }
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
        viewModel.handle(action: .refresh)
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }
}

// MARK: - UITableViewDataSourcePrefetching
extension FeedViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let max = indexPaths.map { $0.row }.max() ?? 0
        viewModel.handle(action: .loadPostsAfter(max))
    }
}
