//
//  OrderQueueFetch.swift
//  MippeumCalcuratorRx
//
//  Created by 장태현 on 2020/07/24.
//  Copyright © 2020 장태현. All rights reserved.
//

import Foundation

import RxSwift
import RealmSwift

protocol OrderQueueFetchable {
    func fetchOrderQueue() -> Observable<(Int, [OrderQueueModel])>
}

class OrderQueueStore: OrderQueueFetchable {
    func fetchOrderQueue() -> Observable<(Int, [OrderQueueModel])> {
        
        return Observable.create { emitter -> Disposable in
            
            self.fetch { data in
                switch data {
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
    
    func fetch(onComplete: @escaping (Result<(Int, [OrderQueueModel]), Error>) -> Void) {
        
        DispatchQueue.global(qos: .background).async {
            
            let frDate = Date().startTime()
            let toDate = Date().endTime()
            
            let realm = RealmCenter.INSTANCE.getRealm()
            
            let dbOrders = realm.objects(DBOrder.self)
                .filter("orderedDate >= %@", frDate)
                .filter("orderedDate <= %@", toDate)
                //.filter("isDone == false") 총 매출을 계산해야하므로 제작완료도 포함해야한다.
                .sorted(byKeyPath: "orderedDate", ascending: false)
            
            var orderQueues: [OrderQueueModel] = []
            var totalSum = 0
            
            _ = dbOrders
                .enumerated()
                .map { _, item in
                    totalSum += Int(item.totalPrice)
                    
                    if !item.isDone {
                        orderQueues.append(OrderQueueModel(
                            orderedDate: item.orderedDateKey
                            ,orderedList: "\(item.orderedList.map { "\($0.productId)(\($0.productQty))"}.joined(separator: ", "))"))
                    }
                }
            
            onComplete(.success((totalSum, orderQueues)))
        }
    }
}
