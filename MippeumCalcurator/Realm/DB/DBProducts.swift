//
//  DBProducts.swift
//  MippeumCalcuratorRx
//
//  Created by 장태현 on 2020/07/21.
//  Copyright © 2020 장태현. All rights reserved.
//

import Foundation
import RealmSwift

class DBProducts : Object {
    
    @objc dynamic var productId: String
    @objc dynamic var productPrice : Int64
    @objc dynamic var ordering: Int64
    
    convenience init(productId: String, productPrice: Int64, ordering: Int64) {
        self.init()
        self.productId = productId
        self.productPrice = productPrice
        self.ordering = ordering
    }
    
    required override init() {
        self.productId = ""
        self.productPrice = 0
        self.ordering = 0
        super.init()
    }
    
    // Primary Key 는 String, Int만 가능
    override static func primaryKey() -> String {
        return "productId"
    }
}

extension DBProducts {
    static func fromFirebase(productId: String, productPrice: Int64, ordering: Int64) -> DBProducts {
        return DBProducts(productId: productId, productPrice: productPrice, ordering: ordering)
    }
}
