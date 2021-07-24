//
//  AddCryptoViewController.swift
//  CryptoMarket
//
//  Created by Thomas on 03/05/2021.
//  Copyright © 2021 Thomas Martins. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AddCryptoViewController: UIViewController {

    private var viewModelMarket: MarketViewModel = MarketViewModel()
    private var viewModel: AddCryptoViewModel? = nil
    private let disposeBag: DisposeBag = DisposeBag()
    private var tableViewDataSource: [Market] = []
    private let spinner = UIActivityIndicatorView(style: .whiteLarge)
    private let quickSearchTextChanged: PublishSubject<String> = PublishSubject<String>()
    private let onCryptoAdd: PublishSubject<(Market, Int)> = PublishSubject<(Market, Int)>()
    private let refreshControl = UIRefreshControl()
    private var currentItemSelect: Int = 0
    
    @IBOutlet private weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupView()
        self.setupViewModel()
    }
    
    internal func setup(with vm: AddPortfolioViewModel, with selected: Int) {
        self.viewModel = AddCryptoViewModel(vm: vm)
        self.currentItemSelect = selected
    }

    private func setupView() {
        self.navigationItem.title = "Which cryto?"
        self.setupTableView()
        self.setupSpinner()
        self.setupSearchController()
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
    
    private func setupTableView() {
        self.tableView.isHidden = true
        self.tableView.register(AddCryptoTableViewCell.nib, forCellReuseIdentifier: AddCryptoTableViewCell.identifier)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.refreshControl.tintColor = UIColor.init(named: "White")
        //self.tableView.refreshControl = self.refreshControl
        self.tableView.keyboardDismissMode = .onDrag
    }
    
    private func setupSpinner() {
        self.spinner.center = self.view.center
        self.spinner.isHidden = false
        self.view.addSubview(self.spinner)
        self.spinner.startAnimating()
    }
    
    private func setupViewModel() {
        let input = MarketViewModel.Input(loaderTrigger: self.refreshControl.rx.controlEvent(.valueChanged).asDriver().map { _ in !self.refreshControl.isRefreshing }.filter { $0 ==  false}, quickSearchText: (self.navigationItem.searchController?.searchBar.rx.text.asDriver())!)
        
        let output = self.viewModelMarket.transform(input: input)
        
        let inputCrypto = AddCryptoViewModel.Input(onCryptoEvent: self.onCryptoAdd.asObservable())
        let outputCrypto = self.viewModel?.transform(input: inputCrypto)
        
        output.isLoading
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { (isLoading) in
                self.spinner.isHidden = !isLoading
                self.spinner.stopAnimating()
                self.tableView.isHidden = isLoading
            }).disposed(by: self.disposeBag)
        
        output.tableViewDataSource
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { (tableViewDataSource) in
                self.tableViewDataSource = tableViewDataSource
                self.refreshControl.endRefreshing()
                self.tableView.reloadData()
            }, onError: { (error) in
                self.handleErrorOnRetry(error: error, message: ErrorMessage.errorMessageMarket) {
                    self.setupViewModel()
                }
            }).disposed(by: self.disposeBag)
        
        outputCrypto?.onEventDone
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { event in
                self.dismiss(animated: true) {
                    self.onCryptoAdd.onNext(event)
                }
            }).disposed(by: self.disposeBag)
    }
}

extension AddCryptoViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableViewDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: AddCryptoTableViewCell.identifier, for: indexPath) as? AddCryptoTableViewCell {
            cell.name = self.tableViewDataSource[indexPath.row].name ?? ""
            cell.shortName = self.tableViewDataSource[indexPath.row].symbol ?? ""
            //cell.loadImage(with: self.tableViewDataSource[indexPath.row].id ?? "")
            cell.loadImage(with: self.tableViewDataSource[indexPath.row].symbol?.lowercased() ?? "")
            if let vm = self.viewModel {
                cell.setup(with: vm, market: self.tableViewDataSource[indexPath.row], row: indexPath.row)
            }
            cell.setup(with: indexPath.row == self.currentItemSelect ? false : true)
            return cell
        }
        return UITableViewCell()
    }
}
