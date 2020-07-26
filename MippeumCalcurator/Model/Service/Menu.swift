//
//  Model.swift
//  MippeumCalcurator3
//
//  Created by 장태현 on 2020/07/20.
//  Copyright © 2020 장태현. All rights reserved.
//

import Foundation

class Menu: Decodable {
    var item: String
    var price: Int
    
    init(item: String, price:Int) {
        self.item = item
        self.price = price
    }
}
