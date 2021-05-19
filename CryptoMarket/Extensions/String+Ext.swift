//
//  String+Ext.swift
//  CryptoMarket
//
//  Created by Thomas on 12/09/2019.
//  Copyright © 2019 Thomas Martins. All rights reserved.
//

import Foundation

extension String {
    func concat(string: String) -> String{
        return "\(self)\(string)"
    }
    
    func currencyFormatting(formatterDigit: Int) -> String {
        if let value = Double(self) {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = formatterDigit
            formatter.minimumFractionDigits = formatterDigit
            formatter.numberStyle = .decimal
            if let str = formatter.string(for: value) {
                return "$".concat(string: str)
            }
        }
        return ""
    }
    
    func numberFormatting(formatterDigit: Int, isDecimal: Bool) -> String {
        if let value = Double(self) {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = formatterDigit
            formatter.minimumFractionDigits = formatterDigit
            if isDecimal { formatter.numberStyle = .decimal }
            if let str = formatter.string(for: value) {
                return "\(str)"
            }
        }
        return ""
    }
    
    func percentageFormatting() -> String {
        if let value = Double(self) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            if let str = formatter.string(for: value) {
                return str.concat(string: "%")
            }
        }
        return ""
    }
    
    func formatToDate() -> String {
        let dateForm = DateFormatter()
        dateForm.dateFormat = "yyyy-MM-dd"
        return dateForm.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
    }
    
    func formatAsDate() -> Date? {
        let dateForm = DateFormatter()
        dateForm.dateFormat = "yyyy-MM-dd"
        return dateForm.date(from: self)
    }
}
