//
//  Util.swift
//  MippeumCalcurator3
//
//  Created by 장태현 on 2020/07/20.
//  Copyright © 2020 장태현. All rights reserved.
//

import Foundation
import UIKit

extension Int {
    
    /// 국내 통화
    /// - Returns: String
    func currencyKR() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
    
    // Int To String With Decimal Type ex) 9000 -> "9,000"
    func toDecimalFormat() -> String {
        let numFormat = NumberFormatter()
        numFormat.numberStyle = .decimal
        return numFormat.string(from: NSNumber(value:self)) ?? "0"
    }
}

extension Int64 {
    
    func currencyKR() -> String {
        return Int(self).currencyKR()
    }
}

extension Date {
    
    /// 이번달의 시작 일자
    /// - Returns: Date
    func startOfMonth() -> Date {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone.current
        cal.locale   = Locale.current
        let comp: DateComponents = cal.dateComponents([.year, .month], from: cal.startOfDay(for: self))
        return cal.date(from: comp)!
    }
    
    /// 이번달의 마지막 날짜
    /// - Returns: Date
    func endOfMonth() -> Date {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone.current
        cal.locale   = Locale.current
        var comp: DateComponents = cal.dateComponents([.month, .day], from: cal.startOfDay(for: self))
        comp.month = 1
        comp.day = -1
        return cal.date(byAdding: comp, to: self.startOfMonth())!
    }
    
    /// 오늘의 00시 00분 00초
    ///
    /// - Returns: <#return value description#>
    func startTime() -> Date {
        return Calendar.current.startOfDay(for:self)
    }
    
    /// 오늘의 23시 59분 59초
    ///
    /// - Returns: <#return value description#>
    func endTime() -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startTime())!
    }
}

extension UIViewController {
    
    func showAlert(_ title: String, _ message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertVC, animated: true, completion: nil)
    }
}
