//
//  OrderQueueViewModel.swift
//  MippeumCalcuratorRx
//
//  Created by 장태현 on 2020/07/24.
//  Copyright © 2020 장태현. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

protocol OrderQueueViewModelType {
    
    var doFetching: AnyObserver<Void> { get }
    
    var activatingObservable: Observable<Bool> { get }
    var totalPriceObservable: Observable<String> { get }
    var listItemsObservable: Observable<[OrderQueueModel]> { get }
    
    func deleteRow(indexPath: IndexPath)
    
}

class OrderQueueViewModel: OrderQueueViewModelType {
    
    let disposeBag = DisposeBag()
    
    // INPUT
    var doFetching: AnyObserver<Void>
    
    // OUTPUT
    let activatingObservable: Observable<Bool>
    var totalPriceObservable: Observable<String>
    var listItemsObservable: Observable<[OrderQueueModel]>
    
    let menuSubject = BehaviorRelay<(Int, [OrderQueueModel])>(value: (0, []))
    
    init(_ orderQueue: OrderQueueFetchable = OrderQueueStore()) {
        
        // Subject
        let fetching = PublishSubject<Void>()
        
        let activatingSubject = BehaviorSubject<Bool>(value: false)
        
        doFetching = fetching.asObserver()
        
        fetching
            .do(onNext: { _ in activatingSubject.onNext(true)})
            .flatMap { orderQueue.fetchOrderQueue() }
            .map { $0 }
            .do(onNext: { _ in activatingSubject.onNext(false)})
            .subscribe(onNext: menuSubject.accept)
            .disposed(by: disposeBag)
        
        totalPriceObservable = menuSubject
            .map { $0.0.currencyKR() }
        
        listItemsObservable = menuSubject
            .map { $0.1 }
        
        activatingObservable = activatingSubject
            .distinctUntilChanged()
    }
    
    /// 매출데이터 fetch
    /// - Parameter indexPath: IndexPath
    func deleteRow(indexPath: IndexPath) {
        
        var newList = menuSubject.value.1
        
        let realm = RealmCenter.INSTANCE.getRealm()
        
        let data = realm.objects(DBOrder.self).filter("orderedDateKey == %@", newList[indexPath.row].orderedDate)

        realm.beginWrite()
        
        _ = data
            .enumerated()
            .map { _, item in
                item.isDone = true // 제작 완료 처리
            }
        realm.add(data, update: .all)

        do {
            try realm.commitWrite()

            newList.remove(at: indexPath.row)
            doFetching.onNext(()) // 재조회 요청
            
        } catch let error {
            print("tableView Row Delete failed .. \(error.localizedDescription)")
        }
    }
}
