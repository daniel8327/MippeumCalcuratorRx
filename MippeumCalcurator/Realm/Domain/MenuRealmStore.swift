//
//  MenuStore.swift
//  MippeumCalcuratorRx
//
//  Created by 장태현 on 2020/07/27.
//  Copyright © 2020 장태현. All rights reserved.
//

import Foundation

import RealmSwift
import RxSwift

protocol MenuRealmFetchable {
    func fetchProducts() -> Observable<[MenuModel]>
    
    func saveRealm(menuModels: [MenuModel]) throws
}

class MenuRealmStore: MenuRealmFetchable {
    func fetchProducts() -> Observable<[MenuModel]> {
        
        return Observable.create { emitter -> Disposable in
            self.fetch { result in
                switch result {
                case let .success(data):
                    emitter.onNext(data)
                    emitter.onCompleted()
                case let .failure(error):
                    emitter.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    /// DBProducts 조회
    /// - Parameter complete: (Result<[MenuModel], Error>)
    func fetch(complete: @escaping (Result<[MenuModel], Error>) -> Void) {
        
        DispatchQueue.global(qos: .userInteractive).async {

            let realm = RealmCenter.INSTANCE.getRealm()
            
            // CoreData 존재시
            if nil != realm.objects(DBProducts.self).first {
                
                var menus: [MenuModel] = []
                
                let products = realm.objects(DBProducts.self).sorted(byKeyPath: "ordering")
                
                products.forEach { item in
                    menus.append(MenuModel(item: item.productId, price: Int(item.productPrice), count: 0))
                }
                
                complete(.success(menus))
            } else {
                complete(.failure(NSError.init(domain: "Products not found", code: 1400, userInfo: nil)))
            }
        }
    }
    
    /// CoreData 저장
    /// - Throws: Exception
    func saveRealm(menuModels: [MenuModel]) throws {
        
        /// menuItem -> realm data
        /// - Parameter list: [MenuModel]
        /// - Returns: (DBOrder, [DBOrderList])
        func menuItemToRealmData(menuModels: [MenuModel]) -> (DBOrder, [DBOrderList]) {
            
            var dbOrderLists = [DBOrderList]()
            let date = Date()
            let orderedDateKey = date.description
            
            // total sum 구하기
            let totalSum = menuModels.map {
                $0.price * $0.count
            }.reduce(0, +)
            
            let dbOrder = DBOrder(orderedDateKey: orderedDateKey, orderedDate: date, totalPrice: Int64(totalSum), isDone: false)
            
            _ = menuModels.map {
                dbOrderLists.append(DBOrderList(dbOrder: dbOrder, productId: $0.item, productQty: Int64($0.count)))
            }
            
            return (dbOrder, dbOrderLists)
        }
        
        let realm = RealmCenter.INSTANCE.getRealm()
        
        realm.beginWrite()
        
        do {
            let (dbOrder, dbOrderList) = menuItemToRealmData(menuModels: menuModels)
            
            realm.add(dbOrder)
            realm.add(dbOrderList)
            try realm.commitWrite()
        } catch let error {
            
            if realm.isInWriteTransaction {
                realm.cancelWrite()
            }
            throw error
        }
    }
}
