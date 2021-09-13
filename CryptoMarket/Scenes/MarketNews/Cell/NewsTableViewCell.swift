//
//  NewsTableViewCell.swift
//  CryptoMarket
//
//  Created by Thomas Martins on 16/01/2020.
//  Copyright © 2020 Thomas Martins. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import AlamofireImage
import RxAlamofire

class NewsTableViewCell: UITableViewCell {

    //MARK: Outlets
    @IBOutlet private weak var titleNews: UILabel!
    @IBOutlet private weak var dateLabelNews: UILabel!
    @IBOutlet private weak var imageNews: UIImageView!
    @IBOutlet private weak var placeholderView: UIView!
    
    //MARK: Members
    private let viewModel: MarketNewsCellViewModel = MarketNewsCellViewModel()
    private let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.imageNews.image = UIImage()
        self.placeholderView.isHidden = false
    }
    
    private func setupView() {
        self.placeholderView.isHidden = false
        self.placeholderView.layer.cornerRadius = 10
        self.placeholderView.backgroundColor = UIColor.init(named: "Gray")?.withAlphaComponent(0.3) ?? UIColor.black
        self.imageNews.layer.cornerRadius = 10
    }
    
    public var title: String? {
        get {
            return self.titleNews.text
        }
        set {
            self.titleNews.text = newValue
        }
    }
    
    public var date: String? {
        get {
            return self.dateLabelNews.text
        }
        set {
            self.dateLabelNews.text = newValue
        }
    }
    
    private func downloadImage(urlImage: String) {
        let input = MarketNewsCellViewModel.Input(imageName: Driver.just(urlImage))
        let output = self.viewModel.transform(input: input)
              
        self.viewModel.currentDownloadUrl = urlImage
        
        output.imageDownloaded.asObservable()
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { imageView in
                guard let image = imageView else {
                    return self.imageNews.image = UIImage(named: "bitcoin-placeholder")
                }
                self.viewModel.saveImageOnCache(image: image, key: urlImage)
                if self.viewModel.currentDownloadUrl == urlImage {
                    self.imageNews.image = image
                }
            }, onError: { error in
                self.imageNews.image = UIImage(named: "bitcoin-placeholder")
            }).disposed(by: self.disposeBag)
              
        output.isImageLoading.asObservable()
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (isLoading) in
                self.imageNews.isHidden = isLoading
                self.placeholderView.isHidden = !isLoading
            }).disposed(by: self.disposeBag)
    }
    
    public func loadImageOnCell(urlImage: String?) {
        
        guard let urlImage = urlImage, !urlImage.isEmpty else { return }
  
        if let imageCache = self.viewModel.getImageOnCache(key: urlImage) {
            self.imageNews.image = imageCache
            self.placeholderView.isHidden = true
            return
        }
        self.downloadImage(urlImage: urlImage)
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
