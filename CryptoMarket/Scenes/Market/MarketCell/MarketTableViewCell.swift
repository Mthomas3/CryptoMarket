//
//  MarketTableViewCell.swift
//  CryptoMarket
//
//  Created by Thomas on 10/09/2019.
//  Copyright © 2019 Thomas Martins. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class MarketTableViewCell: UITableViewCell {

    // MARK: Outlets
    @IBOutlet private weak var indexLabel: UILabel!
    @IBOutlet private weak var imageLogo: UIImageView!
    @IBOutlet private weak var symbolLabel: UILabel!
    @IBOutlet private weak var labelName: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var logoLoader: UIActivityIndicatorView!
    @IBOutlet private weak var changePercent: UILabel!
    @IBOutlet private weak var arrayImage: UIImageView!
    @IBOutlet private weak var testImage: UIImageView!
    
    //MARK: Private Members
    private let viewModel: MarketCellViewModel = MarketCellViewModel()
    private let disposeBag = DisposeBag()
    private let spinner = UIActivityIndicatorView(style: .white)

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.imageLogo.image = nil
        self.arrayImage.image = nil
    }
    
    public var title: String? {
        set {
          self.titleLabel.text = newValue
        }
        get {
            return self.titleLabel.text
        }
    }

    public var symbol: String? {
        set {
            self.labelName.text = newValue
        }
        get {
            return self.labelName.text
        }
    }
    
    public var index: String? {
        set {
            self.indexLabel.text = newValue
        }
        get {
            return self.indexLabel.text
        }
    }
    
    public var logoImage: UIImage? {
        set {
            self.imageLogo?.image = newValue
        }
        get {
            return self.imageLogo?.image
        }
    }
    
    public var price: String? {
        set {
            self.priceLabel.text = newValue
        }
        get {
            return self.priceLabel.text
        }
    }
    
    public func setPercentageOnMarket(percentage: String) {
        self.changePercent.text = "\(abs(Double(percentage) ?? 0))".percentageFormatting()
        let currentValue = Double(percentage) ?? 0
        
        self.changePercent.textColor = currentValue > 0 ? UIColor.init(named: "SortUp") : UIColor.init(named: "SortDown")
        self.arrayImage.image = currentValue > 0 ? UIImage(named: "sort-up-solid") : UIImage(named: "sort-down-solid")
    }
    
    public func loadImageOnCell(name: String) {
                
        ///MARK: old way to get picture from a github repo 
        /*let input = MarketCellViewModel.Input(imageName:
            Driver.just(ApiRoute.ROUTE_IMAGE.concat(string: name).concat(string: ".png")))*/
        
        let input = MarketCellViewModel.Input(imageName:
            Driver.just(ApiRoute.ROUTE_IMAGE.concat(string: name)))
        
        let output = self.viewModel.transform(input: input)
        
        output.imageDownloaded.asObservable()
        .subscribeOn(MainScheduler.asyncInstance)
        .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (image) in
                guard let image = image else  { return }
                self.logoImage = image
                self.imageLogo.setRounded()
            }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: self.disposeBag)
        
        output.isImageLoading.asObservable()
        .subscribeOn(MainScheduler.asyncInstance)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { (isLoading) in
            self.imageLogo.isHidden = isLoading
            isLoading ? self.logoLoader.startAnimating() : self.logoLoader.stopAnimating()
            self.logoLoader.isHidden = !isLoading
        }).disposed(by: self.disposeBag)
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    static var identifier: String {
        return String(describing: self)
    }
    
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
