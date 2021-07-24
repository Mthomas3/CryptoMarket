//
//  AddCryptoTableViewCell.swift
//  CryptoMarket
//
//  Created by Thomas on 03/05/2021.
//  Copyright © 2021 Thomas Martins. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AddCryptoTableViewCell: UITableViewCell {

    @IBOutlet private weak var imageDisplay: UIImageView!
    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var shortTitle: UILabel!
    @IBOutlet private weak var loaderImage: UIActivityIndicatorView!
    
    private let viewModel: MarketCellViewModel = MarketCellViewModel()
    private let disposeBag = DisposeBag()
    private let spinner = UIActivityIndicatorView(style: .whiteLarge)
    private var viewModelCrypto: AddCryptoCellViewModel? = nil
    private var selectItem: Market? = nil
    private var rowSelected: Int? = 0
    
    @IBOutlet private weak var isCheckImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    internal func setup() {
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.imageDisplay.image = nil
    }
    
    internal var name: String? {
        get { return self.title.text }
        set { self.title.text = newValue }
    }
    
    internal var shortName: String? {
        get { return self.shortTitle.text }
        set { self.shortTitle.text = newValue }
    }
    
    public var logoImage: UIImage? {
        set {
            self.imageDisplay?.image = newValue
        }
        get {
            return self.imageDisplay?.image
        }
    }
    
    internal func setup(with vm: AddCryptoViewModel, market: Market, row: Int) {
        self.viewModelCrypto = AddCryptoCellViewModel(vm: vm)
        self.selectItem = market
        self.rowSelected = row
        self.setupViewModel()
    }
    
    internal func loadImage(with name: String) {
//        let input = MarketCellViewModel.Input(imageName:
//            Driver.just(ApiRoute.ROUTE_IMAGE.concat(string: name).concat(string: ".png")))
        let input = MarketCellViewModel.Input(imageName:
            Driver.just(ApiRoute.ROUTE_IMAGE.concat(string: name)))

        
        let output = self.viewModel.transform(input: input)
        
        output.imageDownloaded.asObservable()
        .subscribeOn(MainScheduler.asyncInstance)
        .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (image) in
                guard let image = image else  { return }
                self.logoImage = image
                self.imageDisplay.setRounded()
            }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: self.disposeBag)
        
        output.isImageLoading.asObservable()
        .subscribeOn(MainScheduler.asyncInstance)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { (isLoading) in
            self.imageDisplay.isHidden = isLoading
            isLoading ? self.loaderImage.startAnimating() : self.loaderImage.stopAnimating()
            self.loaderImage.isHidden = !isLoading
        }).disposed(by: self.disposeBag)
        
    }
    
    private func setupViewModel() {
        let inputView = AddCryptoCellViewModel.Input(onTap: self.rx.tapGesture()
                                                        .filter{ $0.state == .ended }
                                                        .asObservable().map { (_) -> (Market, Int) in
                                                            return (self.selectItem!, self.rowSelected ?? 0)
        })
        _ = self.viewModelCrypto?.transform(input: inputView)
    }
    
    internal func setup(with check: Bool) {
        self.isCheckImage.isHidden = check
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    internal static var identifier: String {
        return String(describing: self)
    }
    
    internal static var nib: UINib {
        return UINib(nibName: self.identifier, bundle: .main)
    }
    
}
