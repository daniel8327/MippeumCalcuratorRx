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
    @objc dynamic var productId: String
    @objc dynamic var productQty: Int64
    
    required init() {
        self.productId = ""
        self.productQty = 0
        super.init()
    }
    
    convenience init(dbOrder: DBOrder, product_id: String ,product_qty: Int64) {
        self.init()
        self.dbOrder = dbOrder
        self.productId = product_id
        self.productQty = product_qty
    }
}
