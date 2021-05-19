//
//  AddMoneyViewController.swift
//  CryptoMarket
//
//  Created by Thomas on 04/05/2021.
//  Copyright © 2021 Thomas Martins. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AddMoneyViewController: UIViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    private var viewModel: AddMoneyViewModel? = nil
    private let disposeBag = DisposeBag()
    private var tableViewDataSource: [MoneyModel] = []
    private let onMoneyAdd: PublishSubject<(MoneyModel, Int)> = PublishSubject<(MoneyModel, Int)>()
    
    private var row: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.setupViewModel()
    }

    internal func setup(with vm: AddPortfolioViewModel, with row: Int) {
        self.row = row
        self.viewModel = AddMoneyViewModel(vm: vm)
    }
    
    private func setupView() {
        self.navigationItem.title = "Which money?"
        self.setupTableView()
    }
    
    private func setupViewModel() {
        let input = AddMoneyViewModel.Input(onMoneyEvent: self.onMoneyAdd.asObservable())
        let output = self.viewModel?.transform(input: input)
        
        output?.onEventDone
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { event in
                self.dismiss(animated: true) {
                    self.onMoneyAdd.onNext(event)
                }
            }).disposed(by: self.disposeBag)
        
        output?.dataSource
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { dataSource in
                self.tableViewDataSource = dataSource
                self.tableView.reloadData()
            }).disposed(by: self.disposeBag)
    }
    
    private func setupTableView() {
        self.tableView.register(MoneyTableViewCell.nib, forCellReuseIdentifier: MoneyTableViewCell.identifier)
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
}

extension AddMoneyViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableViewDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: MoneyTableViewCell.identifier, for: indexPath) as? MoneyTableViewCell {
            cell.title = self.tableViewDataSource[indexPath.row].name.rawValue
            cell.amount = "\(self.tableViewDataSource[indexPath.row].amount)".numberFormatting(formatterDigit: 3, isDecimal: true)
            cell.isImageCheck(with: self.tableViewDataSource[indexPath.row].isSelected)
            
            if let vm = self.viewModel {
                cell.setup(with: vm, and: self.tableViewDataSource[indexPath.row], and: indexPath.row)
            }
            cell.setup(with: indexPath.row == self.row ? false : true)
            return cell
        }
        return UITableViewCell()
    }

}
