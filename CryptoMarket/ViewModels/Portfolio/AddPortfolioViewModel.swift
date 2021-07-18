//
//  AddPortfolioViewModel.swift
//  CryptoMarket
//
//  Created by Thomas on 29/04/2021.
//  Copyright © 2021 Thomas Martins. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import Firebase
import FirebaseFirestore

internal class AddPortfolioViewModel: ViewModelType {
    
    private let disposeBag: DisposeBag = DisposeBag()
    private let onCryptoItemSelected: BehaviorSubject<(Market, Int)> = BehaviorSubject<(Market, Int)>(value: (Market(with: "Bitcoin", and: "BTC"), 0))
    private let onMoneyItemSelected: BehaviorSubject<(MoneyModel, Int)> = BehaviorSubject<(MoneyModel, Int)>(value: (MoneyModel(name: .USD, amount: 1.000, isSelected: true), 0))
    private let onCryptoCellTapEvent: PublishSubject<Int> = PublishSubject<Int>()
    private let onMoneyCellTapEvent: PublishSubject<Int> = PublishSubject<Int>()
    private let isFormValid: PublishSubject<Bool> = PublishSubject<Bool>()
    private let downloadViewModel: MarketCellViewModel = MarketCellViewModel()
    
    private let onCellValue: BehaviorSubject<[Int: Double]> = BehaviorSubject<[Int: Double]>(value: [:])
    private(set) var onInputCellUpdate: PublishSubject<(Int, Double, Int)> = PublishSubject<(Int, Double, Int)>()
    
    struct Input {
        let doneEvent: Observable<Void>
    }
    
    struct Output {
        let onCryptoItemSelected: Observable<(Market, Int)>
        let onMoneyItemSelected: Observable<(MoneyModel, Int)>
        
        let onCryptoSelectEvent: Observable<Int>
        let onMoneySelectEvent: Observable<Int>
        let tableviewDataSources: Observable<[Int: [PortfolioCellProtocol]]>

        let isFormValid: Observable<Bool>
        
        let onCreatePortfolio: Observable<(Portfolio, UIImage?)>
    }
    
    private func createInputOnCellPortfolio() -> [Int: [PortfolioCellProtocol]] {
        
        var tableViewInput: [PortfolioCellProtocol] = []
        var tableViewDate: [PortfolioCellProtocol] = []
        
        var dataTableView: [Int: [PortfolioCellProtocol]] = [:]
        
        tableViewInput.append(InputCell(title: "Amount", button: nil, isCrypto: true))
        tableViewInput.append(InputCell(title: "Price", button: nil, isCrypto: false))
        tableViewInput.append(InputCell(title: "Total", button: nil, isCrypto: false))
        tableViewInput.append(InputCell(title: "Fee", button: nil, isCrypto: false))
        
        tableViewDate.append(DateCell(title: "Date"))
        
        dataTableView[0] = tableViewInput
        dataTableView[1] = tableViewDate
        
        return dataTableView
    }
    
    private func updateTotalAmount(edited row: Int, and new: Double) {
        if var value = (try? self.onCellValue.value()) {
            switch row {
            case 0:
                if let price = value[1] {
                    let result = new * price
                    value[2] = result
                    self.onCellValue.onNext(value)
                    self.onInputCellUpdate.onNext((2, result, row))
                }
            case 1:
                if let amount = value[0] {
                    let result = new * amount
                    value[2] = result
                    self.onCellValue.onNext(value)
                    self.onInputCellUpdate.onNext((2, result, row))
                }
            case 2:
                if let amount = value[0] {
                    let result = new / amount
                    value[1] = result
                    self.onCellValue.onNext(value)
                    self.onInputCellUpdate.onNext((1, result, row))
                }
            default:
                break
            }
        }
    }
    
    internal func onValueSet(with value: (Int, Double)) {
        let cellsValues = try? self.onCellValue.value()
        if var item = cellsValues {
            item[value.0] = value.1
            self.onCellValue.onNext(item)
            self.updateTotalAmount(edited: value.0, and: value.1)
        }
    }
    
    internal func onCryptoCellEvent(with event: Market, with row: Int) {
        self.onCryptoItemSelected.onNext((event, row))
    }
    
    internal func onMoneyCellEvent(with event: MoneyModel, with row: Int) {
        self.onMoneyItemSelected.onNext((event, row))
    }
    
    internal func onSelectCryptoEvent(row selected: Int) {
        self.onCryptoCellTapEvent.onNext(selected)
    }
    
    internal func onSelectMoneyEvent(row selected: Int) {
        self.onMoneyCellTapEvent.onNext(selected)
    }
    
    private func downloadImage(with name: String) -> Observable<UIImage?> {
        let downloadImageResult = self.downloadViewModel
            .transform(input: MarketCellViewModel
                        .Input(imageName: Driver.just(ApiRoute
                                                        .ROUTE_IMAGE.concat(string: name)
                                                        .concat(string: ".png"))))
        return downloadImageResult.imageDownloaded
    }
    
    private func savePortfolioValueOnCloud(with portfolio: Portfolio) {
        
        if let app = UIApplication.shared.delegate as? AppDelegate, let user = app.userUid {
            let db = Firestore.firestore()
            let newDocument = db.collection("/Portfolio").document()
            newDocument.setData(["amount": portfolio.amount,
                                 "boughtPrice": portfolio.price,
                                 "coin": portfolio.marketName,
                                 "fee": portfolio.fee,
                                 "total": portfolio.total,
                                 "user": user])
        }
    }

    private func createNewPortfolio() -> Observable<(Portfolio, UIImage?)> {
        
        guard let cryptoItem = try? self.onCryptoItemSelected.value(),
              let _ = try? self.onMoneyItemSelected.value(),
              let amountValues = try? self.onCellValue.value() else {
            return Observable.create { observer in
                observer.onError(CoreDataError.createPortfolioError)
                return Disposables.create()
            }
        }

        let create = Portfolio(amount: "\(amountValues[0] ?? 0.0)",
                               price: "\(amountValues[1] ?? 0.0)",
                               total: "\(amountValues[2] ?? 0.0)",
                               fee: "\(amountValues[3] ?? 0.0)",
                               date: Date(),
                               marketName: cryptoItem.0.name ?? "",
                               marketSymbol: cryptoItem.0.symbol ?? "",
                               marketRank: cryptoItem.0.rank ?? "",
                               id: cryptoItem.0.id ?? "")
        
        self.savePortfolioValueOnCloud(with: create)
        
        return Observable.combineLatest(CoreDataManager.sharedInstance.create(with: create),
                                        self.downloadImage(with: cryptoItem.0.id ?? ""))
    }
    
    
    func transform(input: Input) -> Output {
        let tableViewSource = self.createInputOnCellPortfolio()
        
        
        let cellResultsValues = self.onCellValue.map {
            return $0.values.map { $0 > 0.0 }.filter { $0 == false }.count == 0 && $0.count > 3
        }
        
        let doneTrigger = Observable.combineLatest(input.doneEvent, self.onCellValue).map { return $0.1.count > 3 }
        
        let resultFormValidation = Observable.merge(cellResultsValues, doneTrigger)
        
        let onCreatePortfolio: Observable<(Portfolio, UIImage?)> = input.doneEvent.asObservable()
            .flatMap { self.createNewPortfolio() }

                
        return Output(onCryptoItemSelected: self.onCryptoItemSelected.asObservable(),
                      onMoneyItemSelected: self.onMoneyItemSelected.asObservable(),
                      onCryptoSelectEvent: self.onCryptoCellTapEvent.asObservable(),
                      onMoneySelectEvent: self.onMoneyCellTapEvent.asObservable(),
                      tableviewDataSources: Driver.just(tableViewSource).asObservable(),
                      isFormValid: resultFormValidation.asObservable(),
                      onCreatePortfolio: onCreatePortfolio.asObservable())
    }
}
