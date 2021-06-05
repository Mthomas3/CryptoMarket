//
//  PortfolioViewController.swift
//  CryptoMarket
//
//  Created by Thomas on 28/04/2021.
//  Copyright © 2021 Thomas Martins. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PortfolioViewController: UIViewController {

    @IBOutlet private weak var tableViewPortfolio: UITableView!
    @IBOutlet private weak var emptyView: UIView!
    
    private let viewModel: PortfolioViewModel = PortfolioViewModel()
    private let onDelete: PublishSubject<PortfolioCore> = PublishSubject<PortfolioCore>()
    private let disposeBag = DisposeBag()
    private var tableViewDataSource: [PortfolioCore] = []
    private let tableViewSpinner = UIActivityIndicatorView(style: .whiteLarge)
    private let refreshControl = UIRefreshControl()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.setupTableView()
        self.setupViewModel()
    }
    
    private func setupView() {
        self.navigationItem.title = "0.00$"
        self.extendedLayoutIncludesOpaqueBars = true
        self.navigationController?.navigationBar.barTintColor = UIColor.init(named: "MainColor")
        self.view.addSubview(self.tableViewSpinner)
        self.tableViewSpinner.translatesAutoresizingMaskIntoConstraints = false
        self.tableViewSpinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.tableViewSpinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        self.tableViewSpinner.isHidden = false
        self.tableViewSpinner.startAnimating()
        let addButton = UIBarButtonItem(image: UIImage(named: "plus"), style: .plain, target: self, action: #selector(self.addPortfolio))
        addButton.tintColor = UIColor.init(named: "WhiteImage")
        self.navigationItem.rightBarButtonItem  = addButton
        self.emptyView.layer.cornerRadius = 18
        self.emptyView.backgroundColor = UIColor.init(named: "SoftWhite")?.withAlphaComponent(0.075)
        self.emptyView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.addPortfolio)))
        self.emptyView.isHidden = true
    }

    private func setupTableView() {
        self.tableViewPortfolio.register(PortfolioTableViewCell.nib, forCellReuseIdentifier: PortfolioTableViewCell.identifier)
        self.tableViewPortfolio.delegate = self
        self.tableViewPortfolio.dataSource = self
        self.refreshControl.tintColor = UIColor.init(named: "White")
        self.tableViewPortfolio.refreshControl = self.refreshControl
    }
    
    @objc private func addPortfolio() {
        
        if let vc = UIStoryboard(name: "PortfolioStoryboard", bundle: .main).instantiateViewController(withIdentifier: "AddPortfolioViewStoryboard") as? AddPortfolioViewController {
            vc.setup()
            self.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        }
    }
    
    private func updateBackgroundView() {
        UIView.animate(withDuration: 0.5) {
            if self.tableViewDataSource.count == 0 {
                self.tableViewPortfolio.isHidden = true
                self.emptyView.isHidden = false
                self.tableViewPortfolio.alpha = 0.0
                self.emptyView.alpha = 1.0
            } else {
                self.tableViewPortfolio.isHidden = false
                self.emptyView.isHidden = true
                self.tableViewPortfolio.alpha = 1.0
                self.emptyView.alpha = 0.0
            }
        }
    }
    
    private func setupViewModel() {
        let input = PortfolioViewModel.Input(onDelete: self.onDelete.asObservable(),
                                             onRefresh: self.refreshControl.rx.controlEvent(.valueChanged).asDriver()
                                                .map { _ in !self.refreshControl.isRefreshing }
                                                .filter{ $0 == false }.asObservable())
        let output = self.viewModel.transform(input: input)
        
        output.portfolioDataSources.asObservable()
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { dataSource in
                self.tableViewDataSource = dataSource
                self.refreshControl.endRefreshing()
                self.tableViewPortfolio.reloadData()
                self.updateBackgroundView()
            }, onError: { error in
                print("AN ERROR OCCURED = \(error)")
            }).disposed(by: self.disposeBag)
            
        output.portfolioOnChange.asObservable()
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe (onNext: { (element) in
                self.tableView(new: element)
            }).disposed(by: self.disposeBag)
        
        output.isLoading.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (isLoading) in
                self.tableViewPortfolio.isHidden = isLoading
                self.tableViewSpinner.isHidden = !isLoading
                isLoading ? self.tableViewSpinner.startAnimating() : self.tableViewSpinner.stopAnimating()
                
            }).disposed(by: self.disposeBag)
        
        output.portfolioCurrentValue.asObservable()
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { portfolioValue in
                self.navigationItem.title = "\(portfolioValue)".currencyFormatting(formatterDigit: 2)
            }).disposed(by: self.disposeBag)
    }
}

extension PortfolioViewController: UITableViewDelegate, UITableViewDataSource {
    
    private func tableView(new element: PortfolioCore) {
        self.tableViewDataSource.append(element)
        let selectedIndexPath = IndexPath(row: self.tableViewDataSource.count - 1, section: 0)
        self.tableViewPortfolio.beginUpdates()
        self.tableViewPortfolio.insertRows(at: [selectedIndexPath], with: .automatic)
        self.tableViewPortfolio.endUpdates()
        self.updateBackgroundView()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let deleteElem = tableViewDataSource[indexPath.row]
            self.onDelete.onNext(deleteElem)
            self.tableView(removeElement: deleteElem, indexPath: indexPath)
        }
    }
    
    private func tableView(removeElement element: PortfolioCore, indexPath: IndexPath) {
        self.tableViewDataSource.remove(at: indexPath.row)
        self.tableViewPortfolio.beginUpdates()
        self.tableViewPortfolio.deleteRows(at: [indexPath], with: .automatic)
        self.tableViewPortfolio.endUpdates()
        self.updateBackgroundView()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: PortfolioTableViewCell.identifier, for: indexPath) as? PortfolioTableViewCell {
            
            cell.index = "\(indexPath.row + 1)"
            
            cell.title = self.tableViewDataSource[indexPath.row].marketName
            cell.setFootNameValue(symbol: self.tableViewDataSource[indexPath.row].marketSymbol ?? "", amount: self.tableViewDataSource[indexPath.row].amount ?? "")
            cell.price = self.tableViewDataSource[indexPath.row].total
            
            cell.setupViewModel(portfolio: self.tableViewDataSource[indexPath.row])
            cell.loadImageOnCell(name: self.tableViewDataSource[indexPath.row].marketName?.lowercased() ?? "")
            cell.setSelectedBackgroundColor(selectedColor: .clear)
            
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableViewDataSource.count
    }
}
