//
//  Network.swift
//  CryptoMarket
//
//  Created by Thomas Martins on 11/09/2019.
//  Copyright © 2019 Thomas Martins. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire
import RxAlamofire
import ObjectMapper
import Keys

internal final class Network {

    public static let sharedInstance = Network()

    private let networkNews: NetworkNews
    private let networkMarket: NetworkMarket
    private let networkHistory: NetworkHistory
    
    private init() {
        self.networkNews = NetworkNews()
        self.networkMarket = NetworkMarket()
        self.networkHistory = NetworkHistory()
    }
    
    public func performGetOnMarket(stringUrl url: String) -> Observable<[Market]> {
        return self.networkMarket.getMarket(stringUrl: url)
    }
    
    public func performGetOnMarket(stringUrl url: String, with name: String) -> Observable<Market> {
        return self.networkMarket.getMarket(stringUrl: url, with: name)
    }
    
    public func performGetOnNews(stringUrl url: String) -> Observable<[MarketNews]>{
        return self.networkNews.getNews(stringUrl: url)
    }
    
    public func performGetRequestImage(imageUrl url: String) -> Observable<UIImage?> {
            let newUrl = url.removeWhitespace().lowercased()
            return RxAlamofire
            .requestData(.get, newUrl)
            .map({ (response,data) -> UIImage? in
                return UIImage(data: data)
            })
    }
    
    public func performGetOnHistory(stringUrl url: String, assetName name: String, legendData: MarketHistoryRequest) -> Observable<[MarketInformation]> {
        return self.networkHistory.getHistory(stringUrl: url, assetName: name, legendData: legendData)
    }
    
    public func performGetMarketEmotions(stringUrl url: String) -> Observable<[MarketEmotion]> {
        return self.networkMarket.getMarketEmotions(stringUrl: url)
    }
    
    public func performGetMarketEmotions(stringUrl url: String, with interval: ApiEmotionsInterval) -> Observable<[MarketEmotion]> {
        return self.networkMarket.getMarketEmotions(stringUrl: url, interval: interval)
    }
}
