//
//  PieChart.swift
//  CryptoMarket
//
//  Created by Thomas Martins on 22/02/2020.
//  Copyright © 2020 Thomas Martins. All rights reserved.
//

import UIKit
import Charts
import RxSwift
import RxCocoa

final class PieChart: UIView {
    
    @IBOutlet private weak var pieChartView: PieChartView!
    
    private var viewModel: PieChartViewModel! = nil
    private let disposeBag: DisposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    //method called outside to setup
    public func setup() {
        
        self.viewModel = PieChartViewModel()
        self.setupView()
        self.setupViewModel()
    }
    
    private func setupView() {
        
        self.setupPieChartView()
    }
    
    private func setupViewModel() {
        let input = PieChartViewModel.Input()
        
        let output = self.viewModel.transform(input: input)
        
        output.pieViewData.asObservable()
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (data, color) in
                self.setPieChartData(data: data, dataColor: color)
            }).disposed(by: self.disposeBag)
    }
    
    private func setupPieChartView() {
        self.pieChartView.holeColor = UIColor.init(named: "MainColor") ?? UIColor.red
        self.pieChartView.holeRadiusPercent = 0.58
        self.pieChartView .transparentCircleColor = UIColor.white.withAlphaComponent(0.43)
        self.pieChartView.rotationEnabled = false
        self.pieChartView.highlightPerTapEnabled = true
        self.pieChartView.maxAngle = 180
        self.pieChartView.rotationAngle = 180
        self.pieChartView.centerTextOffset = CGPoint(x: 0, y: -20)
        self.pieChartView.extraBottomOffset = 0
        self.pieChartView.extraTopOffset = 0
        self.pieChartView.extraLeftOffset = 50
        self.pieChartView.extraRightOffset = 50
        self.pieChartView.chartDescription?.textColor = .white
        self.pieChartView.chartDescription?.font = UIFont(name:"HelveticaNeue-Light", size:12)!

        let legend = self.pieChartView.legend
        legend.horizontalAlignment = .left
        legend.verticalAlignment = .bottom
        legend.orientation = .horizontal
        legend.drawInside = false
        legend.xEntrySpace = 7
        legend.yEntrySpace = 0
        legend.yOffset = 0
        legend.textColor = .white
        legend.font = UIFont(name:"HelveticaNeue-Light", size:17)!
        
        self.pieChartView.entryLabelColor = .white
        self.pieChartView.entryLabelFont = UIFont(name:"HelveticaNeue-Light", size:17)!
        self.pieChartView.backgroundColor = UIColor.init(named: "MainColor")
        self.pieChartView.animate(xAxisDuration: 2.5, easingOption: .easeOutBack)
    }
    
    private func setPieChartData(data: [PieChartDataEntry], dataColor: UIColor) {
        let set = PieChartDataSet(entries: data, label: "On 100%")
        set.sliceSpace = 3
        set.selectionShift = 5
        set.colors = [dataColor, UIColor.init(named: "Color-1") ?? UIColor.gray]
        let data = PieChartData(dataSet: set)
        
        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .percent
        pFormatter.maximumFractionDigits = 1
        pFormatter.multiplier = 1
        pFormatter.percentSymbol = " %"
        data.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))
        data.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 11)!)
        data.setValueTextColor(.white)
        self.pieChartView.data = data
        
        self.pieChartView.setNeedsDisplay()
    }
    
    
    static var identifier: String {
        return String(describing: self)
    }
    
    static var nib: UINib {
        return UINib(nibName: self.identifier, bundle: nil)
    }
}
