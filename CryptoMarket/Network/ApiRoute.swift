//
//  ApiRoute.swift
//  CryptoMarket
//
//  Created by Thomas on 12/09/2019.
//  Copyright © 2019 Thomas Martins. All rights reserved.
//

import Foundation

//api.coincap.io/v2/assets/bitcoin/history?interval=m15
public enum ApiRoute {
        
    public static let ROUTE_SERVER_MARKET = "https://api.coincap.io/v2/"
    public static let ROUTE_MARKET = "assets"
    //public static let ROUTE_IMAGE = "https://cryptologos.cc/logos/thumbs/"
    public static let ROUTE_IMAGE = "https://cryptoicon-api.vercel.app/api/icon/"
    public static let ROUTE_HISTORY = "assets/"
    
    public static let ROUTE_SERVER_NEWS = "https://newsapi.org/v2/everything?q="
    public static let ROUTE_NEWS_CRYPTOCURRENCY = "Cryptocurrency&from=".concat(string: "".formatToDate()).concat(string: "&us&sortBy=popularity&apiKey=")
    
    public static let ROUTE_SERVER_FEER = "https://api.alternative.me/"
    public static let ROUTE_FEER_GREED = "fng/"
}

//m1, m5, m15, m30, h1, h2, h6, h12, d1
internal enum ApiInterval: Int {
    case m1 = 0
    case m5
    case m15
    case m30
    case h1
    case h2
    case h6
    case h12
    case d1
}

internal enum ApiEmotionsInterval: Int {
    case week = 7
    case month = 30
    case year = 365
    case all = 0
}
