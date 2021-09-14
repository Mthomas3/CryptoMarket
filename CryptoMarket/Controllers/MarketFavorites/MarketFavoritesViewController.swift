//
//  MarketFavoritesViewController.swift
//  CryptoMarket
//
//  Created by Thomas Martins on 21/09/2019.
//  Copyright © 2019 Thomas Martins. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Comets

class MarketFavoritesViewController: UIViewController {
    
    //MARK: Members
    private var tableViewDataSource: [Favorite] = []
    private let disposeBag = DisposeBag()
    private let viewModel: FavoriteViewModel = FavoriteViewModel()
    private let onDelete: PublishSubject<Favorite> = PublishSubject<Favorite>()
    private let tableViewSpinner = UIActivityIndicatorView(style: .whiteLarge)

    //MARK: Outlets
    @IBOutlet private weak var tableViewFavorite: UITableView!
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var backgroundEmptyView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.setupTableView()
        self.setupViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.delegate = self
    }

    private func setupView() {
        self.navigationItem.title = "Favorites"
        self.extendedLayoutIncludesOpaqueBars = true
        self.navigationController?.navigationBar.barTintColor = UIColor.init(named: "MainColor")
        self.view.addSubview(self.tableViewSpinner)
        self.tableViewSpinner.translatesAutoresizingMaskIntoConstraints = false
        self.tableViewSpinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.tableViewSpinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        self.tableViewSpinner.isHidden = false
        self.tableViewSpinner.startAnimating()
        
        self.backgroundEmptyView.backgroundColor = UIColor.init(named: "SoftWhite")?.withAlphaComponent(0.075)
        self.backgroundEmptyView.layer.cornerRadius = 18
    }
    
    private func setupTableView() {
        self.tableViewFavorite.register(MarketTableViewCell.nib, forCellReuseIdentifier:   MarketTableViewCell.identifier)
        self.tableViewFavorite.delegate = self
        self.tableViewFavorite.dataSource = self
    }
    
    private func displayComets(cometAplha: CGFloat) {
        let width = self.backgroundView.bounds.width
        let height = self.backgroundView.bounds.height
        let cometAplha: CGFloat = cometAplha
        
        let comets = [Comet(startPoint: CGPoint(x: 100, y: 0),
                            endPoint: CGPoint(x: 0, y: 100),
                            lineColor: UIColor.white.withAlphaComponent(cometAplha),
                            cometColor: UIColor.white),
                      Comet(startPoint: CGPoint(x: 0.4 * width, y: 0),
                            endPoint: CGPoint(x: width, y: 0.8 * width),
                            lineColor: UIColor.white.withAlphaComponent(cometAplha),
                            cometColor: UIColor.white),
                      Comet(startPoint: CGPoint(x: 0.8 * width, y: 0),
                            endPoint: CGPoint(x: width, y: 0.2 * width),
                            lineColor: UIColor.white.withAlphaComponent(cometAplha),
                            cometColor: UIColor.white),
                      Comet(startPoint: CGPoint(x: width, y: 0.2 * height),
                            endPoint: CGPoint(x: 0, y: 0.25 * height),
                            lineColor: UIColor.white.withAlphaComponent(cometAplha),
                            cometColor: UIColor.white),
                      Comet(startPoint: CGPoint(x: 0, y: height - 0.8 * width),
                            endPoint: CGPoint(x: 0.6 * width, y: height),
                            lineColor: UIColor.white.withAlphaComponent(cometAplha),
                            cometColor: UIColor.white),
                      Comet(startPoint: CGPoint(x: width - 100, y: height),
                            endPoint: CGPoint(x: width, y: height - 100),
                            lineColor: UIColor.white.withAlphaComponent(cometAplha),
                            cometColor: UIColor.white),
                      Comet(startPoint: CGPoint(x: 0, y: 0.8 * height),
                            endPoint: CGPoint(x: width, y: 0.75 * height),
                            lineColor: UIColor.white.withAlphaComponent(cometAplha),
                            cometColor: UIColor.white)]
        
        for comet in comets {
            self.backgroundView.layer.addSublayer(comet.drawLine())
            self.backgroundView.layer.addSublayer(comet.animate())
        }
    }
    
    private func displayHelpBackground(isHidden: Bool) {
    
        self.tableViewFavorite.isHidden = isHidden
        self.backgroundView.isHidden = !isHidden
        UIView.animate(withDuration: 0.5, animations: {
            if isHidden {
                self.tableViewFavorite.alpha = 0
                self.backgroundView.alpha = 1.0
            } else {
                self.backgroundView.alpha = 0
                self.tableViewFavorite.alpha = 1.0
            }
        }) { (_) in
            if isHidden {
                self.displayComets(cometAplha: 0.03)
            }
        }
    }
    
    private func setupViewModel() {
        let input = FavoriteViewModel.Input(onDelete: self.onDelete.asObservable())
        let output = self.viewModel.transform(input: input)
        
        output.favoriteMarket.asObservable()
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (favorite) in
                self.tableViewDataSource = favorite
                self.tableViewFavorite.reloadData()
                self.displayHelpBackground(isHidden: favorite.count > 0 ? false : true)
            }, onError: { (error) in
                self.handleErrorOnRetry(error: error, message: ErrorMessage.errorMessageFavorite) {
                    self.setupViewModel()
                }
            }, onCompleted: nil, onDisposed: nil).disposed(by: self.disposeBag)
        
        output.favoriteOnChange.asObservable()
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (element) in
                self.tableView(addNewElement: element)
                self.displayHelpBackground(isHidden: false)
            }, onError: { (error) in
                self.handleErrorOnRetry(error: error, message: ErrorMessage.errorMessageFavorite) {
                    self.setupViewModel()
                }
            }, onCompleted: nil, onDisposed: nil).disposed(by: self.disposeBag)
        
        output.isLoading.asObservable()
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (isLoading) in
                self.tableViewFavorite.isHidden = isLoading
                self.tableViewSpinner.isHidden = !isLoading
                isLoading ? self.tableViewSpinner.startAnimating() : self.tableViewSpinner.stopAnimating()
            }, onError: { (error) in
                self.handleErrorOnRetry(error: error, message: ErrorMessage.errorMessageFavorite) {
                    self.setupViewModel()
                }
            }, onCompleted: nil, onDisposed: nil).disposed(by: self.disposeBag)
                
    }
}

extension MarketFavoritesViewController {
    
    private func tableView(addNewElement element: Favorite) {
        self.tableViewDataSource.append(element)
        let selectedIndexPath = IndexPath(row: self.tableViewDataSource.count - 1, section: 0)
        self.tableViewFavorite.beginUpdates()
        self.tableViewFavorite.insertRows(at: [selectedIndexPath], with: .automatic)
        self.tableViewFavorite.endUpdates()
    }
    
    private func tableView(removeElement element: Favorite, indexPath: IndexPath) {
        self.tableViewDataSource.remove(at: indexPath.row)
        self.tableViewFavorite.beginUpdates()
        self.tableViewFavorite.deleteRows(at: [indexPath], with: .automatic)
        self.tableViewFavorite.endUpdates()
    }
}

extension MarketFavoritesViewController: UITableViewDelegate, UITableViewDataSource {
    
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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let deleteElem = tableViewDataSource[indexPath.row]
            self.onDelete.onNext(deleteElem)
            self.tableView(removeElement: deleteElem, indexPath: indexPath)
            self.displayHelpBackground(isHidden: self.tableViewDataSource.count > 0 ? false : true)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let vc = UIStoryboard(name: "Market", bundle: nil).instantiateViewController(withIdentifier: "MarketInformationStoryboard") as? MarketInformationViewController {
            
            let currentCell = tableView.cellForRow(at: indexPath) as! MarketTableViewCell
            
            vc.setup(marketSelected: Market(with: tableViewDataSource[indexPath.row]), with: .favorite, navigationMarketIcon: currentCell.logoImage ?? UIImage())
            self.navigationController?.pushViewController(vc, animated: true)
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
}

extension MarketFavoritesViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if tabBarController.selectedIndex == currentPageSelect.Favorite.rawValue {
            if !self.tableViewFavorite.isHidden {
                self.tableViewFavorite.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
            }
        }
    }
}
