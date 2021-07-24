//
//  ViewController.swift
//  CryptoMarket
//
//  Created by Thomas Martins on 05/09/2019.
//  Copyright © 2019 Thomas Martins. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxGesture

//todo -> delegate
class MarketController: UIViewController, UISearchControllerDelegate {
        
    //MARK: Members
    private let viewModel: MarketViewModel = MarketViewModel()
    private let disposeBag = DisposeBag()
    private var tableViewDataSource: [Market] = []
    private let spinner = UIActivityIndicatorView(style: .whiteLarge)
    private let refreshControl = UIRefreshControl()
    private let quickSearchTextChanged: PublishSubject<String> = PublishSubject<String>()
    
    //MARK: Outlets
    @IBOutlet private weak var tableViewMarket: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.setUpViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.view.endEditing(true)
    }
    
    private func setupView() {
        self.navigationItem.title = "Market"
        self.setupTableView()
        self.setupSpinner()
        self.setupSearchController()
    }
    
    private func setupTableView() {
        self.tableViewMarket.isHidden = true
        self.tableViewMarket.register(MarketTableViewCell.nib, forCellReuseIdentifier: MarketTableViewCell.identifier)
        self.tableViewMarket.delegate = self
        self.tableViewMarket.dataSource = self
        self.tableViewMarket.keyboardDismissMode = .onDrag
        self.refreshControl.tintColor = UIColor.init(named: "White")
        self.tableViewMarket.refreshControl = self.refreshControl
    }
    
    private func setupSpinner() {
        self.spinner.center = self.view.center
        self.spinner.isHidden = false
        self.view.addSubview(self.spinner)
        self.spinner.startAnimating()
    }
    
    private func setupSearchController() {
        let searchController = UISearchController()
        searchController.searchBar.tintColor = .white
        searchController.searchBar.barTintColor = .white
        searchController.searchBar.keyboardAppearance = .dark
        
        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15), NSAttributedString.Key.foregroundColor: UIColor.white]
        
        let textField = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        textField.defaultTextAttributes = attributes
        textField.clearButtonMode = .never
        textField.tintColor = UIColor.init(named: "SecondColor")
        
        self.navigationItem.searchController = searchController
    }
    
    private func setUpViewModel() {
        let input = MarketViewModel.Input(loaderTrigger:
            self.refreshControl.rx.controlEvent(.valueChanged)
            .asDriver()
            .map { _ in !self.refreshControl.isRefreshing }
            .filter{ $0 == false },
            quickSearchText: (self.navigationItem.searchController?.searchBar.rx.text.asDriver())!)
        
        let output = self.viewModel.transform(input: input)
        
        output.isLoading
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { (isLoading) in
                self.spinner.isHidden = !isLoading
                self.spinner.stopAnimating()
                self.tableViewMarket.isHidden = isLoading
            }).disposed(by: self.disposeBag)
      
        output.tableViewDataSource
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { (tableViewDataSource) in
                self.tableViewDataSource = tableViewDataSource
                self.refreshControl.endRefreshing()
                self.tableViewMarket.reloadData()
            }, onError: { (error) in
                self.handleErrorOnRetry(error: error, message: ErrorMessage.errorMessageMarket) {
                    self.setUpViewModel()
                }
            }).disposed(by: self.disposeBag)
    }
}

extension MarketController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableViewDataSource.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: MarketTableViewCell.identifier, for: indexPath) as? MarketTableViewCell {
            
            cell.title = tableViewDataSource[indexPath.row].name
            cell.symbol = tableViewDataSource[indexPath.row].symbol
            cell.index = tableViewDataSource[indexPath.row].rank
            cell.price = tableViewDataSource[indexPath.row].priceUsd?.currencyFormatting(formatterDigit: 2)
            //cell.loadImageOnCell(name: tableViewDataSource[indexPath.row].id ?? "")
            cell.loadImageOnCell(name: tableViewDataSource[indexPath.row].symbol?.lowercased() ?? "")
            cell.setPercentageOnMarket(percentage: tableViewDataSource[indexPath.row].changePercent24Hr ?? "")
            cell.setSelectedBackgroundColor(selectedColor: UIColor.init(named: "SecondColor") ?? .white)
            
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let vc = UIStoryboard(name: "Market", bundle: nil).instantiateViewController(withIdentifier: "MarketInformationStoryboard") as? MarketInformationViewController {
            let currentCell = tableView.cellForRow(at: indexPath) as! MarketTableViewCell

            vc.setup(marketSelected: tableViewDataSource[indexPath.row], with: .market, navigationMarketIcon: currentCell.logoImage ?? UIImage())
            
            self.navigationController?.pushViewController(vc, animated: true)
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
}

extension MarketController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if tabBarController.selectedIndex == currentPageSelect.Market.rawValue {
            self.tableViewMarket.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
}
