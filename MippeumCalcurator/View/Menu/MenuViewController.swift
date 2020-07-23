//
//  ViewController.swift
//  MippeumCalcurator3
//
//  Created by 장태현 on 2020/07/19.
//  Copyright © 2020 장태현. All rights reserved.
//

import UIKit

import RxCocoa
import RxSwift
import RxViewController

class MenuViewController: UIViewController {
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBinding()
        fetch()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let identifier = segue.identifier ?? ""
        if identifier == "ReceiptViewController", let targetVC = segue.destination as? ReceiptViewController {
            targetVC.orderedMenuItems.accept(menuItems.value.filter { $0.count > 0 })
        }
    }
    
    // MARK: - UI Logic
    
    func setBinding() {
        
        rx.viewWillAppear
            .debug("viewWillAppear")
            .map { _ in true}
            .take(1)
            .subscribe(onNext: { [weak navigationController] _ in
                navigationController?.isNavigationBarHidden = true
            })
            .disposed(by: disposeBag)
        
        // 당겨서 새로고침
        let refreshControl = UIRefreshControl()
        refreshControl.rx.controlEvent(.valueChanged)
            .subscribe(onNext: fetch)
            .disposed(by: disposeBag)
        tableView.refreshControl = refreshControl
        
        // viewWillAppear || clearButton 클릭시
        Observable.merge([rx.viewWillAppear.map { _ in }, clearButton.rx.tap.map { _ in }])
            .debug("merge")
            .withLatestFrom(menuItems)
            .map { $0.map { ($0.menu, 0)}}
            .bind(to: menuItems)
            .disposed(by: disposeBag)
        
        /* 취소 clearButton 클릭시
         clearButton.rx.tap
         .debug("clearButton")
         .withLatestFrom(menuItems)
         .map { $0.map { ($0.menu, 0)}}
         .bind(to: menuItems)
         .disposed(by: disposeBag)*/
        
        // tableView bind
        menuItems
            .debug("tableview")
            .bind(to: tableView.rx.items(cellIdentifier: MenuCell.identifier, cellType: MenuCell.self)) { index, item, cell in
                
                cell.title.setTitle(item.menu.item, for: .normal)
                cell.price.text = item.menu.price.currencyKR()
                cell.count.text = item.count.toDecimalFormat()
                cell.onChanged  = { [weak self] data in
                    guard let self = self else { return }
                    let count = max((item.count + data), 0)
                    
                    var changedMenu: [(menu: MenuItem, count: Int)] = self.menuItems.value
                    changedMenu[index] = (item.menu, count)
                    self.menuItems.accept(changedMenu)
                }
        }.disposed(by: disposeBag)
        
        let orderedCount = menuItems
            .map { $0.map { $0.count }.reduce(0, +) }
            .asObservable()
        
        // 총 구매한 아이템 갯수 itemCountLabel 방법 1
        orderedCount
            .map { "\($0)" }
            .bind(to: itemCountLabel.rx.text)
            .disposed(by: disposeBag)
        
        /*/ 총 구매한 아이템 갯수 itemCountLabel 방법 2
        menuItems
            .debug("itemCountLabel")
            .map { $0.map { $0.count }.reduce(0, +) }
            .map { "\($0)" }
            .bind(to: itemCountLabel.rx.text)
            .disposed(by: disposeBag)*/
        
        // 최종 구매액 totalPriceLabel
        menuItems
            .debug("totalPriceLabel")
            .map { $0.map { $0.menu.price * $0.count }.reduce(0, +) }
            .map { $0.currencyKR() }
            .bind(to: totalPriceLabel.rx.text)
            .disposed(by: disposeBag)
        
        ///TODO  orderedCount 와 탭을 Operator를 써서 ($0 > 0, true) 일때 처리
        
        // 주문내역 orderHistory
        orderHistory.rx.tap
            .debug("orderHistory")
            .withLatestFrom(menuItems)
            .map { $0.map { $0.count }.reduce(0, +)} // 갯수 체크
            .do(onNext: { [weak self] allCount in
                if allCount > 0 {
                    do {
                        try self?.saveRealm()
                    } catch let err {
                        print("error occur \(err)")
                        return
                    }
                }
            })
            .map { _ in "OrderQueueViewController" }
            .subscribe(onNext: { [weak self] identifier in
                self?.performSegue(withIdentifier: identifier, sender: nil)
            })
            .disposed(by: disposeBag)
            
        // 주문 orderButton
        orderButton.rx.tap
            .debug("orderButton")
            .withLatestFrom(menuItems)
            .map { $0.map { $0.count }.reduce(0, +)} // 갯수 체크
            .do(onNext: { [weak self] allCount in
                if allCount <= 0 { self?.showAlert("주문 실패", "주문해주세요") }
            })
            .filter { $0 > 0 }
            //.map { _ in "OrderQueueViewController" }
            .subscribe(onNext: { [weak self] _ in

                do {
                    try self?.saveRealm()
                } catch let err {
                    print("error occur \(err)")
                    return
                }
                // 주문완료시 초기화
                self?.clearButton.sendActions(for: .touchUpInside)
            })
            .disposed(by: disposeBag)

        // 영수증보기 orderReceipt
        orderReceipt.rx.tap
            .debug("orderReceipt")
            .withLatestFrom(menuItems)
            .map { $0.map { $0.count }.reduce(0, +)} // 갯수 체크
            .do(onNext: { [weak self] allCount in
                if allCount <= 0 { self?.showAlert("주문 실패", "주문해주세요") }
            })
            .filter { $0 > 0 }
            .map { _ in "ReceiptViewController" }
            .subscribe(onNext: { [weak self] identifier in

                do {
                    try self?.saveRealm()

                } catch let err {
                    print("error occur \(err)")
                    return
                }
                self?.performSegue(withIdentifier: identifier, sender: nil)
            })
            .disposed(by: disposeBag)
    }
    
    func showAlert(_ title: String, _ message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertVC, animated: true, completion: nil)
    }
    
    // MARK: - Business Logic
    
    let menuItems: BehaviorRelay<[(menu: MenuItem, count: Int)]> = BehaviorRelay(value: [])
    let orderedCount: BehaviorRelay<Int> = BehaviorRelay(value: 0)
    
    var disposeBag: DisposeBag = DisposeBag()
    
    /// 판매 목록 조회
    /// 1. CoreData
    /// 2. 없으면 서버에서 가져오기
    func fetch() {
        
        indicator.isHidden = false
        
        let realm = RealmCenter.INSTANCE.getRealm()
        
        // CoreData 존재시
        if nil != realm.objects(DBProducts.self).first {
            
            var menus: [(menu: MenuItem, count: Int)] = []
            
            let products = realm.objects(DBProducts.self).sorted(byKeyPath: "ordering")
            
            products.forEach { item in
                menus.append((menu: MenuItem(item: item.productId, price: Int(item.productPrice)), count: 0))
            }
            
            menuItems.accept(menus)
            
            self.tableView.refreshControl?.endRefreshing()
            indicator.isHidden = true
            
        } else {
            
            APIService.fetchAllMenusRx()
                .map { data in
                    struct Response: Decodable {
                        let menus: [MenuItem]
                    }
                    guard let response = try? JSONDecoder().decode(Response.self, from: data) else {
                        throw NSError(domain: "Decoding error", code: -1, userInfo: nil)
                    }
                    return response.menus.map { ($0, 0) }
                }
                .observeOn(MainScheduler.instance)
                .do(onNext: { data in
                    data.enumerated().forEach({ (index, item) in
                        
                        realm.beginWrite()
                        realm.add(DBProducts(productId: item.menu.item, productPrice: Int64(item.menu.price), ordering: Int64(index)), update: .all)
                        try? realm.commitWrite()
                    })
                    
                }, onError: { [weak self] error in
                    self?.showAlert("Fetch Fail", error.localizedDescription)
                    
                    }, onDispose: { [weak self] in
                        self?.indicator.isHidden = true
                        self?.tableView.refreshControl?.endRefreshing()
                })
                .bind(to: menuItems)
                .disposed(by: disposeBag)
        }
    }
    
    /// CoreData 저장
    /// - Throws: Exception
    func saveRealm() throws {
        
        /// menuItem -> realm data
        /// - Parameter list: <#list description#>
        /// - Returns: <#description#>
        func menuItemToRealmData(menuItems: [(menu: MenuItem, count: Int)]) -> (DBOrder, [DBOrderList]) {
            
            var dbOrderLists = [DBOrderList]()
            let date = Date()
            let orderedDateKey = date.description
            
            // total sum 구하기
            let totalSum = menuItems.map {
                $0.menu.price * $0.count
            }.reduce(0, +)
            
            let dbOrder = DBOrder(orderedDateKey: orderedDateKey, orderedDate: date, totalPrice: Int64(totalSum), isDone: false)
            
            _ = menuItems.map {
                dbOrderLists.append(DBOrderList(dbOrder: dbOrder, productId: $0.menu.item, productQty: Int64($0.count)))
            }
            
            return (dbOrder, dbOrderLists)
        }
        
        let realm = RealmCenter.INSTANCE.getRealm()
        
        realm.beginWrite()
        
        do {
            let (dbOrder, dbOrderList) = menuItemToRealmData(menuItems: menuItems.value.filter { $0.count > 0 })
            
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
    
    // MARK: - InterfaceBuilder Links
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var itemCountLabel: UILabel!
    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var orderButton: UIButton!
    @IBOutlet weak var orderHistory: UIButton!
    @IBOutlet weak var orderReceipt: UIButton!
}
