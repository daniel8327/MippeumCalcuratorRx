//
//  ReceiptViewModel.swift
//  MippeumCalcuratorRx
//
//  Created by 장태현 on 2020/07/24.
//  Copyright © 2020 장태현. All rights reserved.
//

import Foundation

import RxSwift

protocol ReceiptViewModelType {
    var orderListEachCount: Observable<String> { get }
    var orderListEachSum: Observable<String> { get }
    var totalPrice: Observable<String> { get }
}

class ReceiptViewModel: ReceiptViewModelType {
    let orderListEachCount: Observable<String>
    let orderListEachSum: Observable<String>
    let totalPrice: Observable<String>
    
    init(_ orderedMenuItems: [ViewMenuItem] = []) {
        let menus = Observable.just(orderedMenuItems)
        let totalSum = menus.map { $0.map { $0.price * $0.count }.reduce(0, +) }
        
        orderListEachCount = menus
            .map { $0.map { "\($0.item) (\($0.count.toDecimalFormat()))"}.joined(separator: "\n") }
        
        orderListEachSum = menus
            .map { $0.map { "\(($0.price * $0.count).toDecimalFormat())"}.joined(separator: "\n") }
        
        totalPrice = totalSum
            .map { $0.currencyKR() }
    }
}
