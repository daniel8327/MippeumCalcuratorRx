//
//  MenuViewModel.swift
//  MippeumCalcuratorRx
//
//  Created by 장태현 on 2020/07/23.
//  Copyright © 2020 장태현. All rights reserved.
//

import Foundation

struct ViewMenuItem {
    var item: String
    var price: Int
    var count: Int
    
    init(menuItem: MenuItem) {
        item = menuItem.item
        price = menuItem.price
        count = 0
    }
    
    init(item: String, price: Int, count: Int) {
        self.item = item
        self.price = price
        self.count = count
    }
}
