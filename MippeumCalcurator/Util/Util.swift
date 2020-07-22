//
//  Util.swift
//  MippeumCalcurator3
//
//  Created by 장태현 on 2020/07/20.
//  Copyright © 2020 장태현. All rights reserved.
//

import Foundation

extension Int {
    func currencyKR() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
    
    // Int To String With Decimal Type ex) 9000 -> "9,000"
    func toDecimalFormat() -> String {
        let lo_numFormat = NumberFormatter()
        lo_numFormat.numberStyle = .decimal
        return lo_numFormat.string(from: NSNumber(value:self)) ?? "0"
    }
}

extension Date {
    func startOfMonth() -> Date {
        var lo_cal = Calendar(identifier: .iso8601)
        lo_cal.timeZone = TimeZone.current
        lo_cal.locale   = Locale.current
        let comp: DateComponents = lo_cal.dateComponents([.year, .month], from: lo_cal.startOfDay(for: self))
        return lo_cal.date(from: comp)!
    }
    func endOfMonth() -> Date {
        var lo_cal = Calendar(identifier: .iso8601)
        lo_cal.timeZone = TimeZone.current
        lo_cal.locale   = Locale.current
        var comp: DateComponents = lo_cal.dateComponents([.month, .day], from: lo_cal.startOfDay(for: self))
        comp.month = 1
        comp.day = -1
        return lo_cal.date(byAdding: comp, to: self.startOfMonth())!
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
