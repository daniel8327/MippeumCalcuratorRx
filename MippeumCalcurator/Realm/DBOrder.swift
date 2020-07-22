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
    
    @objc dynamic var orderedDateKey: String
    @objc dynamic var orderedDate: Date
    @objc dynamic var totalPrice: Int64
    @objc dynamic var isDone: Bool
    
    let orderedList = LinkingObjects(fromType: DBOrderList.self, property: "dbOrder")
    
    // Primary Key 는 String, Int만 가능
    override static func primaryKey() -> String? {
        return "orderedDateKey"
    }
    
    override static func indexedProperties() -> [String] {
        return ["isDone"]
    }
    
    required init() {
        orderedDateKey = ""
        orderedDate = Date()
        totalPrice = 0
        isDone = false
        super.init()
    }
    
    convenience init(order_date_key: String, order_date: Date, order_price: Int64, isDone: Bool) {
        self.init()
        self.orderedDateKey = order_date_key
        self.orderedDate = order_date
        self.totalPrice = order_price
        self.isDone = isDone
    }
}
