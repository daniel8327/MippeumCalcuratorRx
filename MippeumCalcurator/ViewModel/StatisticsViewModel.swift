//
//  StastisticsViewModel.swift
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
    var doFetchingRealm: AnyObserver<Void> { get }
    
    var totalPriceObservable: Observable<String> { get }
    var chartItemObservable: Observable<[String: Int64]> { get }
}

class StatisticsViewModel: StatisticsViewModelType {
    var disposeBag = DisposeBag()
    
    // INPUT
    var doFetchingRealm: AnyObserver<Void>
    
    // OUTPUT
    var totalPriceObservable: Observable<String>
    var chartItemObservable: Observable<[String : Int64]>
    
    init(_ statistics: StatisticsFetchable = StatisticsStore()) {
        
        // Subject
        let chartItems: BehaviorRelay<(Int, [String:Int64])> = BehaviorRelay(value: (0, [:]))
        let fetchingRealm = PublishSubject<Void>()
        
        // INPUT 연결
        // realm 조회 옵져버 연결
        doFetchingRealm = fetchingRealm.asObserver()

        // realm 조회 처리
        fetchingRealm
            .flatMap { statistics.fetchStatistics() }
            .map { $0 }
            .subscribe(onNext: chartItems.accept)
            .disposed(by: disposeBag)
        
        // 총 매출 처리
        totalPriceObservable = chartItems
            .map { $0.0.currencyKR() }
        
        // 챠트 데이터 처리
        chartItemObservable = chartItems
            .map { $0.1 }
    }
}
