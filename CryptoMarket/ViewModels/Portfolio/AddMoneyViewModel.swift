//
//  AddMoneyViewModel.swift
//  CryptoMarket
//
//  Created by Thomas on 04/05/2021.
//  Copyright © 2021 Thomas Martins. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

public enum MoneySelectedValue: String {
    case USD
    case EURO
}

public struct MoneyModel {
    let name: MoneySelectedValue
    let amount: Double
    let isSelected: Bool
    
    init(name: MoneySelectedValue, amount: Double, isSelected: Bool) {
        self.name = name
        self.amount = amount
        self.isSelected = isSelected
    }
}

internal class AddMoneyViewModel: ViewModelType {
    
    private let mainVM: AddPortfolioViewModel
    private let done: PublishSubject<(MoneyModel, Int)> = PublishSubject<(MoneyModel, Int)>()
    private let disposeBag: DisposeBag = DisposeBag()
    
    struct Input {
        let onMoneyEvent: Observable<(MoneyModel, Int)>
    }
    
    struct Output {
        let onEventDone: Observable<(MoneyModel, Int)>
        let dataSource: Observable<[MoneyModel]>
    }
    
    init(vm: AddPortfolioViewModel) {
        self.mainVM = vm
    }
    
    internal func onCellTapDone(with event: (MoneyModel, Int)) {
        self.done.onNext(event)
    }
    
    internal func generateMoney() -> [MoneyModel] {
        var money: [MoneyModel] = []
        
        money.append(MoneyModel(name: MoneySelectedValue.USD, amount: 1.000, isSelected: true))
        //money.append(MoneyModel(name: MoneySelectedValue.EURO, amount: 1000.0, isSelected: true))
        
        return money
    }
    
    func transform(input: Input) -> Output {
        let dataValue = self.generateMoney()
        
        input.onMoneyEvent
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { event in
                self.mainVM.onMoneyCellEvent(with: event.0 , with: event.1)
            }).disposed(by: self.disposeBag)
        
        return Output(onEventDone: self.done.asObservable(),
                      dataSource: Driver.just(dataValue).asObservable())
    }
}
