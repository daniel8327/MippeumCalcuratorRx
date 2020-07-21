//
//  DBData.swift
//  MippeumCalcuratorRx
//
//  Created by 장태현 on 2020/07/21.
//  Copyright © 2020 장태현. All rights reserved.
//

import Foundation
import RealmSwift

class DBOrder : Object {
    
    @objc dynamic var order_date_key: String
    @objc dynamic var order_date: Date
    @objc dynamic var order_price: Int64
    @objc dynamic var isDone: Bool
    
    let order_list = LinkingObjects(fromType: DBOrderList.self, property: "dbOrder")
    
    // Primary Key 는 String, Int만 가능
    override static func primaryKey() -> String? {
        return "order_date_key"
    }
    
    override static func indexedProperties() -> [String] {
        return ["isDone"]
    }
    
    required init() {
        order_date_key = ""
        order_date = Date()
        order_price = 0
        isDone = false
        super.init()
    }
    
    convenience init(order_date_key: String, order_date: Date, order_price: Int64, isDone: Bool) {
        self.init()
        self.order_date_key = order_date_key
        self.order_date = order_date
        self.order_price = order_price
        self.isDone = isDone
    }
}
