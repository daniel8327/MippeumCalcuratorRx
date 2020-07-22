//
//  ViewController.swift
//  MippeumCalcurator3
//
//  Created by 장태현 on 2020/07/19.
//  Copyright © 2020 장태현. All rights reserved.
//

import RxCocoa
import RxSwift
import RxViewController
import UIKit

class MenuViewController: UIViewController {
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBinding()
        fetch()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let id = segue.identifier ?? ""
        if id == "ReceiptViewController", let targetVC = segue.destination as? ReceiptViewController {
            targetVC.orderedMenuItems.accept(menuItems.value.filter { $0.count > 0 })
        } else if  id == "OrderQueueViewController", let targetVC = segue.description as? OrderQueueViewController {
            //targetVC.
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
        Observable.merge([rx.viewWillAppear.map{ _ in }, clearButton.rx.tap.map{ _ in }])
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
            .bind(to: tableView.rx.items(cellIdentifier: "MenuCell", cellType: MenuCell.self)) { index, item, cell in
                
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
        
//        // 총 구매한 아이템 갯수 itemCountLabel 방법 2
//        menuItems
//            .debug("itemCountLabel")
//            .map { $0.map { $0.count }.reduce(0, +) }
//            .map { "\($0)" }
//            .bind(to: itemCountLabel.rx.text)
//            .disposed(by: disposeBag)
        
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
            .map { _ in "OrderQueueViewController" }
            .subscribe(onNext: { [weak self] identifier in

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
    
    func fetch() {
        
        indicator.isHidden = false
        
        let realm = RealmCenter.INSTANCE.getRealm()
        
        if let _ = realm.objects(DBProducts.self).first {
            
            var changedMenu: [(menu: MenuItem, count: Int)] = []
            
            let products = realm.objects(DBProducts.self).sorted(byKeyPath: "ordering")
            
            _ = products.enumerated().map {
                changedMenu.append((menu: MenuItem(item: $0.element.productId, price: Int($0.element.productPrice)), count: 0))
            }
            
            menuItems.accept(changedMenu)
            
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
                _ = data.enumerated().map {
                    
                    realm.beginWrite()
                    realm.add(DBProducts(product_id: $0.element.menu.item, product_price: Int64($0.element.menu.price), ordering: Int64($0.offset)), update: .all)
                    try? realm.commitWrite()
                }
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
    
    func saveRealm() throws {
        func menuItemToDBOrder(list: [(menu: MenuItem, count: Int)]) -> (DBOrder, [DBOrderList]) {
            
            var array = [DBOrderList]()
            let date = Date()
            let order_date_key = date.description
            
            // total sum 구하기
            let totalSum = list.map {
                $0.menu.price * $0.count
            }.reduce(0, +)
            
            let dbOrder = DBOrder(order_date_key: order_date_key, order_date: date, order_price: Int64(totalSum), isDone: false)
            
            _ = list.map {
                array.append(DBOrderList(dbOrder: dbOrder, product_id: $0.menu.item, product_qty: Int64($0.count)))
            }
            
            return (dbOrder, array)
        }
        
        let realm = RealmCenter.INSTANCE.getRealm()
        realm.beginWrite()
        
        do {
            let (dbOrder, dbOrderList) = menuItemToDBOrder(list: menuItems.value.filter { $0.count > 0 })
            
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