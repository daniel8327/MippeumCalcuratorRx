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
    var doFetchingRealm: AnyObserver<Void> { get }
    
    var activatingObservable: Observable<Bool> { get }
    var totalPriceObservable: Observable<String> { get }
    var listItemsObservable: Observable<[OrderQueueModel]> { get }
    
    func deleteRow(indexPath: IndexPath)
}

class OrderQueueViewModel: OrderQueueViewModelType {
    let disposeBag = DisposeBag()
    
    // INPUT
    var doFetchingRealm: AnyObserver<Void>
    
    // OUTPUT
    let activatingObservable: Observable<Bool>
    var totalPriceObservable: Observable<String>
    var listItemsObservable: Observable<[OrderQueueModel]>

    // Subject
    let menuSubject = BehaviorRelay<(Int, [OrderQueueModel])>(value: (0, []))
    
    init(_ orderQueue: OrderQueueFetchable = OrderQueueStore()) {
        
        // Subject
        let activatingSubject = BehaviorSubject<Bool>(value: false)
        let fetchingRealm = PublishSubject<Void>()
        
        // INPUT 연결
        // realm 조회 옵져버 연결
        doFetchingRealm = fetchingRealm.asObserver()
        
        // realm 조회 처리
        fetchingRealm
            .do(onNext: { _ in activatingSubject.onNext(true)})
            .flatMap { orderQueue.fetchOrderQueue() }
            .map { $0 }
            .do(onNext: { _ in activatingSubject.onNext(false)})
            .subscribe(onNext: menuSubject.accept)
            .disposed(by: disposeBag)
        
        // 총 매출 처리
        totalPriceObservable = menuSubject
            .map { $0.0.currencyKR() }
        
        // 주문 Queue 데이터 처리
        listItemsObservable = menuSubject
            .map { $0.1 }
        
        // 화면 구성 처리
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
            doFetchingRealm.onNext(()) // 재조회 요청
            
        } catch let error {
            print("tableView Row Delete failed .. \(error.localizedDescription)")
        }
    }
}
