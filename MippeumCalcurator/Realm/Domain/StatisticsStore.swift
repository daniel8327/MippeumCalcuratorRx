//
//  StatisticsStore.swift
//  MippeumCalcuratorRx
//
//  Created by 장태현 on 2020/07/27.
//  Copyright © 2020 장태현. All rights reserved.
//

import Foundation

import RxSwift
import RealmSwift

protocol StatisticsFetchable {
    func fetchStatistics() -> Observable<(Int, [String:Int64])>
}

class StatisticsStore: StatisticsFetchable {
    func fetchStatistics() -> Observable<(Int, [String:Int64])> {
        
        return Observable.create { emitter -> Disposable in
            self.fetch { result  in
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
    
    /// 오늘의 매출 및 판매 항목을 조회한다.
    /// - Parameter onComplete: (Result<(Int, [String:Int64]), Error>)
    func fetch(onComplete: @escaping (Result<(Int, [String:Int64]), Error>) -> Void) {
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            let frDate = Date().startTime()
            let toDate = Date().endTime()
            
            let realm = RealmCenter.INSTANCE.getRealm()
            
            let dbOrders = realm.objects(DBOrder.self)
                .filter("orderedDate >= %@", frDate)
                .filter("orderedDate <= %@", toDate)
                .sorted(byKeyPath: "orderedDate", ascending: false)
            
            let products = realm.objects(DBProducts.self)
            
            var dict = [String:Int64]()
            
            products.forEach { (product) in
                dict.updateValue(0, forKey: product.productId)
            }
            
            var totalSum = 0
            
            _ = dbOrders
                .enumerated()
                .map { _, item in

                    totalSum += Int(item.totalPrice)
                    
                    item.orderedList.forEach({
                        dict.updateValue(((dict[$0.productId] ?? 0) + $0.productQty), forKey: $0.productId)
                    })
                }
                        
            onComplete(.success((totalSum, dict)))
        }
    }
}
