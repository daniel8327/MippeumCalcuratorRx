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
    
    
    // String To Decimal "9000" -> 9,000
    func toDecimalFormat() -> String {
        
        let lo_numFormat = NumberFormatter()
        lo_numFormat.numberStyle = .decimal
        
        return lo_numFormat.string(from: NSNumber(value:self)) ?? "0"
    }
}
