//
//  CoreDataManager.swift
//  CryptoMarket
//
//  Created by Thomas Martins on 08/01/2020.
//  Copyright © 2020 Thomas Martins. All rights reserved.
//

import Foundation
import CoreData
import RxSwift
import RxCocoa
import ObjectMapper

internal enum CoreDataError: Error {
    case createPortfolioError
    case fetchPortfolioError
}

internal final class CoreDataManager {
    
    public static let sharedInstance = CoreDataManager()
    
    private let coreDataContainer: NSPersistentContainer
    private let favOnChange: PublishSubject<Favorite> = PublishSubject<Favorite>()
    private let portfolioOnChange: PublishSubject<PortfolioCore> = PublishSubject<PortfolioCore>()
    
    private var context: NSManagedObjectContext {
        return self.coreDataContainer.viewContext
    }
    
    private init() {
        self.coreDataContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    }
    
    private func fetchNewData() -> Observable<[Market]> {
        return Network.sharedInstance.performGetOnMarket(stringUrl:
            ApiRoute.ROUTE_SERVER_MARKET.concat(string: ApiRoute.ROUTE_MARKET))
    }
    
    private func fetchData() -> Observable<[Favorite]> {
        do {
            let favorites = try self.context.fetch(Favorite.fetchRequest() as NSFetchRequest<Favorite>)
            
            return Observable<[Favorite]>.create { (observer) -> Disposable in
                observer.onNext(favorites)
                return Disposables.create()
            }
        }
        catch {
            //todo handle
            return Observable<[Favorite]>.create { (observer) -> Disposable in
                return Disposables.create()
            }
        }
    }
    
    public func create(with portfolio: Portfolio) -> Observable<Portfolio> {
        return Observable.create { observer in
            do {
                let result = try CoreDataManager.sharedInstance.doesPortfolioExist(with: portfolio.marketName)
                
                if (!result) {
                    
                    let rhs = PortfolioCore(context: self.context)
                    
                    rhs.amount = portfolio.amount
                    rhs.date = portfolio.date
                    rhs.fee = portfolio.fee
                    rhs.price = portfolio.price
                    rhs.total = portfolio.total
                    rhs.id = portfolio.id
                    rhs.marketName = portfolio.marketName
                    rhs.marketRank = portfolio.marketRank
                    rhs.marketSymbol = portfolio.marketSymbol
                    
                    do {
                        self.context.insert(rhs)
                        try self.context.save()
                        self.portfolioOnChange.onNext(rhs)
                        observer.onNext(portfolio)
                        observer.onCompleted()
                    } catch {
                        observer.onError(CoreDataError.createPortfolioError)
                    }
                }
            } catch {
                observer.onError(CoreDataError.createPortfolioError)
            }
            
            return Disposables.create()
        }
    }
    
    public func create(with market: Market) {
        do {
            let result = try CoreDataManager.sharedInstance.doesMarketExist(with: market.id ?? "")
            
            if (!result) {
                let fav = Favorite(context: self.context)
                fav.id = market.id
                fav.name = market.name
                fav.changePercent24Hr = market.changePercent24Hr
                fav.marketCapUsd = market.marketCapUsd
                fav.maxSupply = market.maxSupply
                fav.priceUsd = market.priceUsd
                fav.rank = market.rank
                fav.supply = market.supply
                fav.vwap24Hr = market.vwap24Hr
                fav.volumeUsd24Hr = market.volumeUsd24Hr
                fav.symbol = market.symbol
                do {
                    self.context.insert(fav)
                    try self.context.save()
                    self.favOnChange.onNext(fav)
                    
                } catch {
                    //todo handle
                }
            }
        }
        catch {
            //todo handle
        }
    }
    
    private func doesPortfolioExist(with portfolioName: String) throws -> Bool {
        let fetchRequest = PortfolioCore.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
        fetchRequest.predicate = NSPredicate(format: "id == %@", portfolioName)
        let result = try self.context.fetch(fetchRequest)
        
        return result.count > 0 ? true : false
    }
    
    private func doesMarketExist(with marketName: String) throws -> Bool {
        
        let fetchRequest = Favorite.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
        fetchRequest.predicate = NSPredicate(format: "id == %@", marketName)
        let result = try self.context.fetch(fetchRequest)
        
        return result.count > 0 ? true : false
    }
    
    public func getCurrentElement() -> Observable<Favorite> {
        return self.favOnChange.asObservable()
    }
    
    public func getCurrentElement() -> Observable<PortfolioCore> {
        return self.portfolioOnChange.asObservable()
    }
    
    private func updateFavorite(fav: [Favorite], newValue: [Market]) -> [Favorite] {
        
        return fav.map { (item) -> Favorite in
            let market = newValue.first { $0.id == item.id }
            
            item.priceUsd = market?.priceUsd
            item.changePercent24Hr = market?.changePercent24Hr
            item.name = market?.name
            
            return item
        }
    }
    
    public func fetch() -> Observable<[PortfolioCore]> {
        return Observable<[PortfolioCore]>.create { (observer) -> Disposable in
            do {
                let result = try self.context.fetch(PortfolioCore.fetchRequest() as NSFetchRequest<PortfolioCore>)
                observer.onNext(result)
                observer.onCompleted()
            } catch {
                observer.onError(CoreDataError.fetchPortfolioError)
            }
            return Disposables.create()
        }
    }
    
    public func fetch() -> Observable<[Favorite]> {
        return Observable.combineLatest(self.fetchNewData(), self.fetchData()).map { (market, favorite) -> [Favorite] in
            return self.updateFavorite(fav: favorite, newValue: market.filter { data in return favorite.contains { $0.id == data.id }})
        }
    }
    
    public func delete(portfolio: PortfolioCore) throws {
        self.context.delete(portfolio)
        try self.context.save()
    }
    
    public func delete(fav: Favorite) throws {
        self.context.delete(fav)
        try self.context.save()
    }
    
    public func deletePortfolio(with id: String) throws {
        let fetchRequest = PortfolioCore.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try self.context.execute(deleteRequest)
        try self.context.save()
    }
    
    public func delete(with id: String) throws {
        let fetchRequest = Favorite.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try self.context.execute(deleteRequest)
        try self.context.save()
    }
}
