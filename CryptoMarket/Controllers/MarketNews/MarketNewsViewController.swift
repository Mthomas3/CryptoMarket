//
//  MarketNewsViewController.swift
//  CryptoMarket
//
//  Created by Thomas on 16/09/2019.
//  Copyright © 2019 Thomas Martins. All rights reserved.
//

import UIKit
import RxSwift
import SafariServices
import StoreKit

class MarketNewsViewController: UIViewController {
    
    //MARK: Members
    private let viewModel: MarketNewsViewModel = MarketNewsViewModel()
    private let disposeBag = DisposeBag()
    private var tableViewDataSource: [MarketNews] = []
    private let tableViewSpinner = UIActivityIndicatorView(style: .whiteLarge)
    private let refreshControl = UIRefreshControl()
    
    //MARK: Outlets
    @IBOutlet private weak var tableViewNews: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.setupViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.delegate = self
        self.handleReviewOnApp()
    }
    
    private func setupView() {
        self.tableViewNews.register(NewsTableViewCell.nib, forCellReuseIdentifier: NewsTableViewCell.identifier)
        self.tableViewNews.delegate = self
        self.tableViewNews.dataSource = self
    
        self.view.addSubview(self.tableViewSpinner)
        self.tableViewSpinner.translatesAutoresizingMaskIntoConstraints = false
        self.tableViewSpinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.tableViewSpinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        self.tableViewSpinner.isHidden = false
        self.tableViewSpinner.startAnimating()
        self.refreshControl.tintColor = UIColor.init(named: "White")
        self.tableViewNews.refreshControl = refreshControl
        self.extendedLayoutIncludesOpaqueBars = true
        self.navigationItem.title = "News"
        self.navigationController?.navigationBar.barTintColor = UIColor.init(named: "MainColor")
        self.tableViewNews.separatorColor = UIColor.init(named: "Gray")
        self.tableViewNews.tableHeaderView = UIView(frame: .zero)
        self.tableViewNews.isHidden = true
    }

    private func setupViewModel() {
            
        let input = MarketNewsViewModel.Input(
            loaderTrigger: self.refreshControl.rx.controlEvent(.valueChanged)
            .asDriver()
            .map { _ in !self.refreshControl.isRefreshing }
                .filter { $0 == false })
        
        let output = self.viewModel.transform(input: input)

        output.collectionViewDataSource
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { (tableViewDataSource) in
                self.tableViewDataSource = tableViewDataSource
                self.tableViewNews.reloadData()
                
                //todo remove this
                self.tableViewNews.refreshControl?.endRefreshing()
            }, onError: { (error) in
                self.handleErrorOnRetry(error: error, message: ErrorMessage.errorMessageNews) {
                    self.setupViewModel()
            }
        }).disposed(by: self.disposeBag)
  
        output.isLoading
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { (isLoading) in
                self.tableViewNews.isHidden = isLoading
                self.tableViewSpinner.isHidden = !isLoading
                isLoading ? self.tableViewSpinner.startAnimating() : self.tableViewSpinner.stopAnimating()
            }).disposed(by: self.disposeBag)
    }
}

extension MarketNewsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableViewDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: NewsTableViewCell.identifier, for: indexPath) as? NewsTableViewCell {
            cell.title = self.tableViewDataSource[indexPath.row].title
            
            let author = self.tableViewDataSource[indexPath.row].author ?? "Unknown Author"
            let publishedDate = self.tableViewDataSource[indexPath.row].publishedAt?.formatToDate() ?? ""
            
            cell.date = publishedDate.concat(string: " \u{2022} ").concat(string: author == "" ? "Unknown Author" : author)
            
            cell.loadImageOnCell(urlImage: self.tableViewDataSource[indexPath.row].urlToImage)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            cell.setSelectedBackgroundColor(selectedColor: UIColor.init(named: "SecondColor") ?? .white)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let imageUrl = self.tableViewDataSource[indexPath.row].url else { return }
        
        if let url = URL(string: imageUrl) {
            let config = SFSafariViewController.Configuration()

            config.entersReaderIfAvailable = true
            let vc = SFSafariViewController(url: url, configuration: config)
            vc.preferredBarTintColor = UIColor.black
            vc.preferredControlTintColor = UIColor.systemBlue
            tableView.deselectRow(at: indexPath, animated: false)
            
            self.present(vc, animated: true)
        }
    }
}

extension MarketNewsViewController {
    func handleReviewOnApp() {
        if let val = UserDefaults.standard.string(forKey: Constants.reviewKey.rawValue) {
            if (Int(val) ?? 0) == 1 || (Int(val) ?? 0) == 10  || (Int(val) ?? 0) == 100 {
                SKStoreReviewController.requestReview()
                UserDefaults.standard.set("\((Int(val) ?? 0) + 1)", forKey: Constants.reviewKey.rawValue)
            } else if (Int(val) ?? 0) < 100 {
                UserDefaults.standard.set("\((Int(val) ?? 0) + 1)", forKey: Constants.reviewKey.rawValue)
            }
        } else {
            UserDefaults.standard.set("1", forKey: Constants.reviewKey.rawValue)
        }
    }
}

extension MarketNewsViewController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if tabBarController.selectedIndex == currentPageSelect.News.rawValue {
            if self.tableViewDataSource.count > 1 {
                self.tableViewNews.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
            }
        }
    }
}
