//
//  OrderQueueViewController.swift
//  MippeumCalcuratorRx
//
//  Created by 장태현 on 2020/07/21.
//  Copyright © 2020 장태현. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RealmSwift

class OrderQueueViewController: UIViewController {
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBinding()
        fetch()
    }
    
    // MARK: - UI Logic
    
    func setBinding() {

        // 두개 합치기
        Observable.merge(
            [rx.viewWillAppear.map{ _ in false }
                ,rx.viewWillDisappear.map{ _ in true }])
            .debug("merge")
            .map { $0 }
            .subscribe(onNext: { [weak navigationController] bool in
                navigationController?.isNavigationBarHidden = bool
            })
            .disposed(by: disposeBag)
        
        // 당겨서 새로고침
        let refreshControl = UIRefreshControl()
        refreshControl.rx.controlEvent(.valueChanged)
            .subscribe(onNext: fetch)
            .disposed(by: disposeBag)
        tableView.refreshControl = refreshControl
        
        // tableView 셋팅
        listItems
        .debug("tableView")
            .bind(to: tableView.rx.items(cellIdentifier: "OrderQueueCell", cellType: OrderQueueCell.self)) { (index, item, cell) in
                
                let dateFormatter = DateFormatter()

                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:sssZ"
                dateFormatter.timeZone = NSTimeZone(name: "KR") as TimeZone?

                let date:Date = dateFormatter.date(from: item.orderedDate)!
                
                dateFormatter.dateFormat = "HH:mm:ss"
                let dateStr = dateFormatter.string(from: date)
                
                cell.orderDateLabel.text = dateStr
                cell.orderListLabel.text = item.orderedList
                
        }.disposed(by: disposeBag)
        
        tableView.rx.itemDeleted
            .subscribe(onNext: {[weak self] indexPath in
            print(indexPath)
            
                guard let self = self else {
                    return
                }
                
                var newList = self.listItems.value
                
                let realm = RealmCenter.INSTANCE.getRealm()
                let data = realm.objects(DBOrder.self).filter("orderedDateKey == %@", newList[indexPath.row].orderedDate)
                
                realm.beginWrite()
                
                data.enumerated().forEach { (_, element) in
                    element.isDone = true
                }
                
                realm.add(data, update: .modified)
                
                do {
                    try realm.commitWrite()

                    newList.remove(at: indexPath.row)
                    self.listItems.accept(newList)
                    
                } catch let error {
                    print("tableView Row Delete failed .. \(error.localizedDescription)")
                }
        })
        .disposed(by: disposeBag)
        
        // 오늘의 총 매출
        totalSum$
            .map { $0.currencyKR() }
            .bind(to: totalSumLabel.rx.text)
            .disposed(by: disposeBag)
        
    }
    
    // MARK: - Business Logic
    
    var listItems: BehaviorRelay<[OrderQueueModel]> = BehaviorRelay(value: [])
    var totalSum$: BehaviorRelay<Int> = BehaviorRelay(value: 0)
    
    var disposeBag: DisposeBag = DisposeBag()
    
    func fetch() {
        
        let frDate = Date().startTime()
        let toDate = Date().endTime()
        
        let realm = RealmCenter.INSTANCE.getRealm()
        
        let dbOrders = realm.objects(DBOrder.self)
            .filter("orderedDate >= %@", frDate)
            .filter("orderedDate <= %@", toDate)
//            .filter("isDone == false") 총 매출을 계산해야하므로 제작완료도 포함해야한다.
            .sorted(byKeyPath: "orderedDate", ascending: false)
        
        
        var orderQueues: [OrderQueueModel] = []
        var totalSum = 0
        
        dbOrders.enumerated().forEach { (_, element) in
            
            totalSum += Int(element.totalPrice)
            
            if !element.isDone {
                orderQueues.append(OrderQueueModel(
                    orderedDate: element.orderedDateKey
                    ,orderedList: "\(element.orderedList.map { "\($0.productId)(\($0.productQty))"}.joined(separator: ", "))"))
            }
            
            //print("주문시간: \(element.order_date_key) 주문 내용 : \(element.order_list.map { "\($0.product_id)(\($0.product_qty))"}.joined(separator: ", "))")
        }
        //print(orderQueues)
        
        listItems.accept(orderQueues)
        totalSum$.accept(totalSum)

        self.tableView.refreshControl?.endRefreshing()
    }
    
    // MARK: - Interface Builder
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalSumLabel: UILabel!
    
    
}
