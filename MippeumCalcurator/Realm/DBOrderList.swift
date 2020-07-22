//
//  DBOrderList.swift
//  MippeumCalcuratorRx
//
//  Created by 장태현 on 2020/07/21.
//  Copyright © 2020 장태현. All rights reserved.
//

import Foundation
import RealmSwift

class DBOrderList : Object {
    
    @objc dynamic var dbOrder : DBOrder!
    @objc dynamic var product_id: String
    @objc dynamic var product_qty: Int64
    
    // Primary Key 는 String, Int만 가능
//    override static func primaryKey() -> String? {
//        return "order_date"
//    }
    
    required init() {
        self.product_id = ""
        self.product_qty = 0
        super.init()
    }
    
    convenience init(dbOrder: DBOrder, product_id: String ,product_qty: Int64) {
        self.init()
        self.dbOrder = dbOrder
        self.product_id = product_id
        self.product_qty = product_qty
    }
}
