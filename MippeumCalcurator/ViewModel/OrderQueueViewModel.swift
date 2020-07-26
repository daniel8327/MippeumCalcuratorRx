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
}

class OrderQueueViewModel: OrderQueueViewModelType {
    
    let disposeBag = DisposeBag()
    
    // INPUT
    var doFetching: AnyObserver<Void>
    
    // OUTPUT
    let activatingObservable: Observable<Bool>
    var totalPriceObservable: Observable<String>
    var listItemsObservable: Observable<[OrderQueueModel]>
    
    init(_ orderQueue: OrderQueueFetchable = OrderQueueStore()) {
        
        // Subject
        let fetching = PublishSubject<Void>()
        
        let menuSubject = BehaviorRelay<(Int, [OrderQueueModel])>(value: (0, []))
        let activatingSubject = BehaviorSubject<Bool>(value: false)
        
        doFetching = fetching.asObserver()
        
        fetching
            .debug("OrderQueueViewModel fetching")
            .do(onNext: { _ in activatingSubject.onNext(true)})
            .flatMap { orderQueue.fetchOrderQueue() }
            .map { $0 }
            .do(onNext: { _ in activatingSubject.onNext(false)})
            .subscribe(onNext: menuSubject.accept)
            .disposed(by: disposeBag)
        
        totalPriceObservable = menuSubject
            .debug("OrderQueueViewModel menuSubject -> totalPriceObservable")
            .map { $0.0.currencyKR() }
        
        listItemsObservable = menuSubject
            .debug("OrderQueueViewModel menuSubject -> listItemsObservable")
            .map { $0.1 }
        
        activatingObservable = activatingSubject
            .debug("OrderQueueViewModel activatingSubject -> activatingObservable")
            .distinctUntilChanged()
    }
}
