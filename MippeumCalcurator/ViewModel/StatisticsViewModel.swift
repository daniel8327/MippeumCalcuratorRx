//
//  StastisticsViewModel.swift
//  StatisticsViewController.swift
//  MippeumCalcuratorRx
//
//  Created by 장태현 on 2020/07/27.
//  Copyright © 2020 장태현. All rights reserved.
//

import Foundation

import Charts
import RxSwift
import RxCocoa

protocol StatisticsViewModelType {
    
    var doFetching: AnyObserver<Void> { get }
    
    var totalPriceObservable: Observable<String> { get }
    var chartItemObservable: Observable<[String: Int64]> { get }
}

class StatisticsViewModel: StatisticsViewModelType {
    
    var disposeBag = DisposeBag()
    
    // INPUT
    var doFetching: AnyObserver<Void>
    
    // OUTPUT
    var totalPriceObservable: Observable<String>
    var chartItemObservable: Observable<[String : Int64]>
    
    init(_ statisticsStore: StatisticsStore = StatisticsStore()) {
        
        // Subject
        let chartItems: BehaviorRelay<(Int, [String:Int64])> = BehaviorRelay(value: (0, [:]))
        
        let fetching = PublishSubject<Void>()
        
        doFetching = fetching.asObserver()
            
        fetching
            .flatMap { statisticsStore.fetchStatistics() }
            .map { $0 }
            .subscribe(onNext: chartItems.accept)
            .disposed(by: disposeBag)
        
        totalPriceObservable = chartItems
            .map { $0.0.currencyKR() }
        
        chartItemObservable = chartItems
            .map { $0.1 }
    }
}
