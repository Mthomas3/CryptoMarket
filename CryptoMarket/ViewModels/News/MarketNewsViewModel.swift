//
//  MarketNewsViewModel.swift
//  CryptoMarket
//
//  Created by Thomas on 16/09/2019.
//  Copyright © 2019 Thomas Martins. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

public final class MarketNewsViewModel: ViewModelType {
    
    private let disposeBag = DisposeBag()
    private let isLoading = PublishSubject<Bool>()
    
    struct Input {
        let loaderTrigger: Driver<Bool>
    }
    
    struct Output {
        let collectionViewDataSource: Observable<[MarketNews]>
        let isLoading: PublishSubject<Bool>
    }
    
    private func fetchMarketNewsData() -> Observable<[MarketNews]> {
        return Network.sharedInstance.performGetOnNews(stringUrl: ApiRoute.ROUTE_SERVER_NEWS.concat(string: ApiRoute.ROUTE_NEWS_CRYPTOCURRENCY))
    }
    
    func transform(input: Input) -> Output {
        
        let refreshOnLoader = input.loaderTrigger.asObservable()
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .throttle(2.5, scheduler: MainScheduler.asyncInstance)
            .flatMap { (_) -> Observable<[MarketNews]> in
                return self.fetchMarketNewsData()
            }
        
        let loadingOnNavigation = self.fetchMarketNewsData().do(onNext: { (market) in
            self.isLoading.onNext(true)
        })
        
        let collectionViewDataSource = Observable.merge(refreshOnLoader, loadingOnNavigation).do(onNext: { (market) in
            self.isLoading.onNext(false)
            }).map { news in return news.filter { data in return !(data.urlToImage?.isEmpty ?? false) }
            }.map { return $0.filter { return !($0.urlToImage == nil) } }
            .map { $0.sorted { $0 == $1 }}
            .map {
                $0.sorted {
                    return ($0.publishedAt?.formatAsDate() ?? Date()) < ($1.publishedAt?.formatAsDate() ?? Date())
                }
            }
        
        return Output(collectionViewDataSource: collectionViewDataSource, isLoading: self.isLoading)
    }
}
