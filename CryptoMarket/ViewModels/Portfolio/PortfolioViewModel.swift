//
//  PortfolioViewModel.swift
//  CryptoMarket
//
//  Created by Thomas on 28/04/2021.
//  Copyright © 2021 Thomas Martins. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

internal final class PortfolioViewModel: ViewModelType {
    private let isLoading: BehaviorSubject<Bool> = BehaviorSubject<Bool>(value: true)
    private let portfolioValue: BehaviorSubject<Double> = BehaviorSubject<Double>(value: 0.0)
    private let disposeBag = DisposeBag()
    
    struct Input {
        let onDelete: Observable<PortfolioCore>
        let onRefresh: Observable<Bool>
    }
    
    struct Output {
        let portfolioDataSources: Observable<[PortfolioCore]>
        let isLoading: Observable<Bool>
        let portfolioOnChange: Observable<PortfolioCore>
        let portfolioCurrentValue: Observable<Double>
    }
    
    init() { }
    
    private func fetchPortfolio() -> Observable<[PortfolioCore]> {
        return CoreDataManager.sharedInstance.fetch()
    }
    
    private func onChangePortfolio() -> Observable<PortfolioCore> {
        return CoreDataManager.sharedInstance.getCurrentElement()
    }
    
    private func deletePortfolio(portfolioElement elem: PortfolioCore) {
        do {
            try CoreDataManager.sharedInstance.delete(portfolio: elem)
        } catch {
            print("could not delete \(elem)")
        }
    }
    
    private func fetchCurrentMarket(market name: String) -> Observable<Market> {
        let route = ApiRoute.ROUTE_SERVER_MARKET.concat(string: ApiRoute.ROUTE_MARKET)
        return Network.sharedInstance.performGetOnMarket(stringUrl: route, with: name).do(onNext: { _ in
            self.isLoading.onNext(false)
        })
    }
    
    internal func onCryptoAddEvent(with event: Market) {
        print("This has been added!!! \(event)")
    }
    
    private func singleUpdatePortfolio(price: Market, amount: PortfolioCore) -> Double {
        let a = Double(amount.amount ?? "") ?? 0.0
        let v = Double(price.priceUsd ?? "") ?? 0.0
        return v * a
    }
    
    func transform(input: Input) -> Output {
        
        input.onDelete
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .flatMap({ (core) -> Observable<(Market, PortfolioCore)> in
                let obsCore: Observable<PortfolioCore> = Observable.just(core)
                let fetch: Observable<Market> = self.fetchCurrentMarket(market: core.marketName ?? "").asObservable()
                
                return Observable.zip(fetch, obsCore) { ( $0, $1 ) }.asObservable()
            }).map({ (rhs, lhs) -> PortfolioCore in
                let currentPortfolioValue: Double = (try? self.portfolioValue.value()) ?? 0.0
                let updateValue = currentPortfolioValue - self.singleUpdatePortfolio(price: rhs, amount: lhs)
                self.portfolioValue.onNext(updateValue < 0.0 ? 0.0 : updateValue)
                return lhs
            }).subscribe {
                self.deletePortfolio(portfolioElement: $0)
            }.disposed(by: self.disposeBag)
        
        let onRefresh = input.onRefresh
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .throttle(2.5, scheduler: MainScheduler.asyncInstance)
            .flatMapLatest { (_) -> Observable<[PortfolioCore]> in
                return self.fetchPortfolio()
            }.flatMap { (core) -> Observable<([Market], [PortfolioCore])> in
                let fetch: Observable<[Market]> = Observable.combineLatest(core.map{(core) -> Observable<Market> in
                    return self.fetchCurrentMarket(market: core.marketName ?? "")
                })
                let obsCore: Observable<[PortfolioCore]> = Observable.just(core)
                return Observable.zip(fetch.ifEmpty(default: []), obsCore) { ($0, $1)}.asObservable()
            }.map { (lhs, rhs) -> [PortfolioCore] in
                var portfolioValue = 0.0
                for (e1, e2) in zip(rhs, lhs) {
                    portfolioValue += self.singleUpdatePortfolio(price: e2, amount: e1)
                }
                self.portfolioValue.onNext(portfolioValue)
                return rhs
            }
        
        let portfolio = self.fetchPortfolio()
            .flatMap { (core) -> Observable<([Market], [PortfolioCore])> in
                let fetch: Observable<[Market]> = Observable.combineLatest(core.map { (core) -> Observable<Market> in
                        return self.fetchCurrentMarket(market: core.marketName ?? "")
                }).asObservable()
                let obsCore: Observable<[PortfolioCore]> = Observable.just(core)
                return Observable.zip(fetch.ifEmpty(default: []), obsCore) { ($0, $1)}.asObservable()
            }.map { (rhs, lhs) -> [PortfolioCore] in
                var portfolioValue = 0.0
                for (e1, e2) in zip(rhs, lhs) {
                    portfolioValue += self.singleUpdatePortfolio(price: e1, amount: e2)
                }
                self.portfolioValue.onNext(portfolioValue)
                return lhs
            }
        
        let portfolioResultFetch: Observable<[PortfolioCore]> = Observable.merge(onRefresh, portfolio).do(onNext: { _ in self.isLoading.onNext(false) })
        
        let onNewElemCreated: Observable<PortfolioCore> = self.onChangePortfolio()
            .flatMap ({ (core) -> Observable<PortfolioCore> in
                return Driver.just(core).asObservable()
            })
            .flatMap ({ (core) -> Observable<(Market, PortfolioCore)> in
                let a: Observable<PortfolioCore> = Observable.just(core)
                let b: Observable<Market> = self.fetchCurrentMarket(market: core.marketName ?? "")
                return Observable.zip(b, a) { ($0, $1) }.asObservable()
            })
            .map { (rhs, lhs) -> PortfolioCore in
                let portfolioCurrent: Double = (try? self.portfolioValue.value()) ?? 0.0
                self.portfolioValue.onNext(self.singleUpdatePortfolio(price: rhs, amount: lhs) + portfolioCurrent)
                return lhs
            }
        
        
        
        return Output(portfolioDataSources: portfolioResultFetch.asObservable(),
                      isLoading: self.isLoading.asObservable(),
                      portfolioOnChange: onNewElemCreated.asObservable(),
                      portfolioCurrentValue: self.portfolioValue.asObservable())
    }
}
