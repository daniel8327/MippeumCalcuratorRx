//
//  MenuViewModel.swift
//  MippeumCalcuratorRx
//
//  Created by 장태현 on 2020/07/27.
//  Copyright © 2020 장태현. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

protocol MenuViewModelType {
    var doFetchingRealm: AnyObserver<Void> { get }
    var doClearing: AnyObserver<Void> { get }
    var doOrdering: AnyObserver<Void> { get }
    var goOrderHisory: AnyObserver<Void> { get }
    var goReceipt: AnyObserver<Void> { get }
    var doAddCounting: AnyObserver<(menuModel: MenuModel, sum: Int)> { get }

    var activatingObservable: Observable<Bool> { get }
    var errorObservable: Observable<NSError> { get }
    var menuObservable: Observable<[MenuModel]> { get }
    var totalSelectedCountObservable: Observable<String> { get }
    var totalPriceObservable: Observable<String> { get }
    var showOrderHistoryObservable: Observable<Void> { get }
    var showReceiptObservable: Observable<[MenuModel]> { get }
}

class MenuViewModel: MenuViewModelType {
    let disposeBag = DisposeBag()
    
    // INPUT
    var doFetchingRealm: AnyObserver<Void>
    var doClearing: AnyObserver<Void>
    var doOrdering: AnyObserver<Void>
    var goOrderHisory: AnyObserver<Void>
    var goReceipt: AnyObserver<Void>
    var doAddCounting: AnyObserver<(menuModel: MenuModel, sum: Int)>

    // OUTPUT
    var activatingObservable: Observable<Bool>
    var errorObservable: Observable<NSError>
    var menuObservable: Observable<[MenuModel]>
    var totalSelectedCountObservable: Observable<String>
    var totalPriceObservable: Observable<String>
    
    var showOrderHistoryObservable: Observable<Void>
    var showReceiptObservable: Observable<[MenuModel]>

    // Subject
    let menuItems: BehaviorSubject<[MenuModel]> = BehaviorSubject(value: [])
    
    init(menu: MenuRealmFetchable = MenuRealmStore()) {
        
        // Subject
        let activatingSubject    = BehaviorSubject<Bool>(value: false)
        let addCounting          = PublishSubject<(menuModel: MenuModel, sum: Int)>()
        let saveProductsForRealm = PublishSubject<[MenuModel]>()
        
        let errorSubject         = PublishSubject<Error>()
        let fetchingRealm        = PublishSubject<Void>()
        let fetchingAPI          = PublishSubject<Void>()
        let clearing             = PublishSubject<Void>()
        let ordering             = PublishSubject<Void>()
        let orderHistory         = PublishSubject<Void>()
        let receipt              = PublishSubject<Void>()
        let saveOrder            = PublishSubject<Void>()
        
        // INPUT 연결
        // realm 조회 옵져버 연결
        doFetchingRealm = fetchingRealm.asObserver()
        // 초기화 옵져버 연결
        doClearing = clearing.asObserver()
        // 주문 옵져버 연결
        doOrdering = ordering.asObserver()
        // 주문내역 옵져버 연결
        goOrderHisory = orderHistory.asObserver()
        // 영수증 옵져버 연결
        goReceipt = receipt.asObserver()
        // 갯수 선택 옵져버 연결
        doAddCounting = addCounting.asObserver()
        
        // OUTPUT 연결
        // 메뉴 Observable 연결
        menuObservable = menuItems.map { $0 }
        
        // realm 조회 처리
        fetchingRealm
            .debug("fetching==   Realm")
            .do(onNext: { _ in activatingSubject.onNext(true) })
            .flatMap { menu.fetchProducts() }
            .do(onNext: { _ in activatingSubject.onNext(false) })
            .do(onError: { _ in fetchingAPI.onNext(()) }) // error 시 api 호출
            .subscribe(onNext: menuItems.onNext)
            .disposed(by: disposeBag)
        
        // api 통신 처리
        fetchingAPI
            .debug("fetching==   API")
            .do(onNext: { _ in activatingSubject.onNext(true) })
            .flatMap { MenuAPIStore().fetch() }
            .map { $0.map { MenuModel(menuItem: $0) } }
            .do(onNext: { _ in activatingSubject.onNext(false) })
            .do(onNext: { data in saveProductsForRealm.onNext(data) })
            .do(onError: { err in errorSubject.onNext(err) }) // error 시 alert 호출
            .subscribe(onNext: menuItems.onNext)
            .disposed(by: disposeBag)
        
        // 갯수 선택 처리
        addCounting
            .map { $0.menuModel.countUpdate(max(($0.menuModel.count + $0.sum), 0)) }
            .withLatestFrom(menuItems) { (updated, originals) -> [MenuModel] in
                originals.map {
                    guard $0.item == updated.item else { return $0 }
                    return updated
                }
            }
            .subscribe(onNext: menuItems.onNext)
            .disposed(by: disposeBag)
        
        // 화면 유효성 처리
        activatingObservable = activatingSubject.distinctUntilChanged()
        
        // 에러 처리
        errorObservable = errorSubject
            .observeOn(MainScheduler.instance)
            .do(onNext: { _ in activatingSubject.onNext(false) })
            .map { $0 as NSError }
        
        // 총 주문 갯수 처리
        totalSelectedCountObservable = menuItems
            .map { $0.map { $0.count}.reduce(0, +) }
            .map { "\($0)" }
        
        // 총 주문 금액 처리
        totalPriceObservable = menuItems
            .map { $0.map { $0.count * $0.price }.reduce(0, +) }
            .map { $0.currencyKR() }
        
        // DBProduct CoreData 저장 처리
        saveProductsForRealm
            .subscribe(onNext: { data in
                let realm = RealmCenter.INSTANCE.getRealm()
                
                _ = data
                    .enumerated()
                    .map { index, item in
                        realm.beginWrite()
                        realm.add(DBProducts(productId: item.item, productPrice: Int64(item.price), ordering: Int64(index)), update: .all)
                        try? realm.commitWrite()
                }
            })
            .disposed(by: disposeBag)
            
        // 초기화 처리
        clearing.withLatestFrom(menuItems)
            .map { $0.map { $0.countUpdate(0) }}
            .subscribe(onNext: menuItems.onNext)
            .disposed(by: disposeBag)
        
        // 주문 처리
        ordering.withLatestFrom(menuItems)
            .debug("ordering 주문 처리")
            .map { $0.map { $0.count }.reduce(0, +) } // 갯수 체크
            .do(onNext: { allCount in
                if allCount > 0 {
                    saveOrder.onNext(()) // CoreData 저장 처리
                    clearing.onNext(())  // UI 초기화
                } else {
                    errorSubject.onNext(NSError.init(domain: "No Orders", code: 1400, userInfo: nil)) // error 시 alert 호출
                }
            })
            .subscribe(onNext: { _ in })
            .disposed(by: disposeBag)
        
        // 주문내역 처리
        showOrderHistoryObservable = orderHistory
            .debug("orderHistory")
            .withLatestFrom(menuItems)
            .map { $0.filter { $0.count > 0 } }
            .do(onNext: { items in
                if items.count > 0 {
                    saveOrder.onNext(()) // CoreData 저장 처리
                }
            })
            .map { _ in ()}
        
        // 영수증 처리
        showReceiptObservable = receipt
            .debug("receipt")
            .withLatestFrom(menuItems)
            .map { $0.filter { $0.count > 0 } }
            .do(onNext: { items in
                if items.count > 0 {
                    saveOrder.onNext(()) // CoreData 저장 처리
                } else {
                    errorSubject.onNext(NSError.init(domain: "No Orders", code: 1400, userInfo: nil)) // error 시 alert 호출
                }
            })
            .filter { $0.count > 0 }
        
        // DBOrder & DBOrderList CoreData 저장 처리
        _ = saveOrder
            .subscribe(onNext: { try? self.saveRealm() })
            .disposed(by: disposeBag)
    }
            
    /// CoreData 저장
    /// - Throws: Exception
    func saveRealm() throws {
        
        /// menuItem -> realm data
        /// - Parameter list: [MenuModel]]
        /// - Returns: (DBOrder, [DBOrderList])
        func menuItemToRealmData(menuItems: [MenuModel]) -> (DBOrder, [DBOrderList]) {
            
            var dbOrderLists = [DBOrderList]()
            let date = Date()
            let orderedDateKey = date.description
            
            // total sum 구하기
            let totalSum = menuItems.map {
                $0.price * $0.count
            }.reduce(0, +)
            
            let dbOrder = DBOrder(orderedDateKey: orderedDateKey, orderedDate: date, totalPrice: Int64(totalSum), isDone: false)
            
            _ = menuItems.map {
                dbOrderLists.append(DBOrderList(dbOrder: dbOrder, productId: $0.item, productQty: Int64($0.count)))
            }
            
            return (dbOrder, dbOrderLists)
        }
        
        let realm = RealmCenter.INSTANCE.getRealm()
        
        realm.beginWrite()
        
        do {
            let (dbOrder, dbOrderList) = menuItemToRealmData(menuItems: try menuItems.value().filter { $0.count > 0 })
            
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
