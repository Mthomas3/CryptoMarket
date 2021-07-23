//
//  NetworkMarket.swift
//  CryptoMarket
//
//  Created by Thomas Martins on 17/03/2020.
//  Copyright © 2020 Thomas Martins. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxAlamofire
import ObjectMapper

internal final class NetworkMarket {
    
    public init() { }
    
    public func getMarket(stringUrl url: String) -> Observable<[Market]> {
        let finalUrl = url.removeWhitespace().lowercased()
        return RxAlamofire
            .json(.get, finalUrl)
            .retry(2)
            .observeOn(MainScheduler.asyncInstance)
            .map({ json -> [Market] in
                return try Mapper<Market>().mapArray(JSONObject: ((json as? [String: Any])?["data"] as? [[String: Any]]) ?? [])
        })
    }
    
    public func getMarket(stringUrl url: String, with name: String) -> Observable<Market> {
        let finalUrl = url + "/" + name.removeWhitespace().lowercased()
        return RxAlamofire
            .json(.get, finalUrl)
            .retry(2)
            .observeOn(MainScheduler.asyncInstance)
            .map( { json -> Market in
                return try Mapper<Market>().map(JSONObject: (json as? [String: Any])?["data"] ?? [])
            })
    }
    
    public func getMarketEmotions(stringUrl url: String) -> Observable<[MarketEmotion]> {
        return RxAlamofire
            .json(.get, url)
            .retry(2)
            .observeOn(MainScheduler.asyncInstance)
            .map({ json -> [MarketEmotion] in
                return try Mapper<MarketEmotion>().mapArray(JSONObject: ((json as? [String: Any])?["data"] as? [[String: Any]]) ?? [])
        })
    }
    
    public func getMarketEmotions(stringUrl url: String, interval: ApiEmotionsInterval) -> Observable<[MarketEmotion]> {

        return RxAlamofire.json(.get, url.concat(string: "?limit=\(interval.rawValue)"))
            .retry(2)
            .observeOn(MainScheduler.asyncInstance)
            .map({json -> [MarketEmotion] in
                return try Mapper<MarketEmotion>().mapArray(JSONObject: ((json as? [String: Any])?["data"] as? [[String: Any]] ?? []))
            })
    }
}
