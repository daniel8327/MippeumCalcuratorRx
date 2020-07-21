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

//        rx.viewWillAppear
//        .debug("viewWillAppear")
//            .take(1)
//            .subscribe(onNext: {[weak navigationController] _ in
//                navigationController?.isNavigationBarHidden = false
//            })
//            .disposed(by: disposeBag)

//        rx.viewWillDisappear
//        .debug("viewWillDisappear")
//            .take(1)
//            .subscribe(onNext: {[weak self] _ in
//                self?.navigationController?.isNavigationBarHidden = true
//            })
//            .disposed(by: disposeBag)
        
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
        
        
        listItems
        .debug("tableView")
            .bind(to: tableView.rx.items(cellIdentifier: "OrderQueueCell", cellType: OrderQueueCell.self)) { (index, item, cell) in
                
                let dateFormatter = DateFormatter()

                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:sssZ"
                dateFormatter.timeZone = NSTimeZone(name: "KR") as TimeZone?

                let date:Date = dateFormatter.date(from: item.date_key)!
                
                
                print(date)
                
                dateFormatter.dateFormat = "HH:mm:ss"
                let date_Str = dateFormatter.string(from: date)
                print(date_Str)
                
                
                cell.orderDateLabel.text = date_Str
                cell.orderListLabel.text = item.order_list
                
        }.disposed(by: disposeBag)
        
        tableView.rx.itemDeleted
            .subscribe(onNext: {[weak self] indexPath in
            print(indexPath)
            
                guard let self = self else {
                    return
                }
                
                var newList = self.listItems.value
                
                let realm = RealmCenter.INSTANCE.getRealm()
                let data = realm.objects(DBOrder.self).filter("order_date_key == %@", newList[indexPath.row].date_key)
                
                realm.beginWrite()
                
                data.enumerated().forEach { (_, element) in
                    element.isDone = true
                }
                
                realm.add(data, update: .modified)
                try? realm.commitWrite()
                
                newList.remove(at: indexPath.row)
                self.listItems.accept(newList)
                    
                
                
            //objects.remove(at: indexPath.row)
                
                //self?.tableView.deleteRows(at: [indexPath], with: .fade)
        })
        .disposed(by: disposeBag)
        
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
        
        let fr_date = Date().startTime()
        let to_date = Date().endTime()
        
        //print(fr_date)
        //print(to_date)
        
        let realm = RealmCenter.INSTANCE.getRealm()
        let dbOrders = realm.objects(DBOrder.self)
            .filter("order_date >= %@", fr_date)
            .filter("order_date <= %@", to_date)
//            .filter("isDone == false")
            .sorted(byKeyPath: "order_date", ascending: false)
        
        
        var orderQueues: [OrderQueueModel] = []
        var totalSum = 0
        
        dbOrders.enumerated().forEach { (_, element) in
            
            totalSum += Int(element.order_price)
            
            if !element.isDone {
                orderQueues.append(OrderQueueModel(
                    date_key: element.order_date_key
                    ,order_list: "\(element.order_list.map { "\($0.product_id)(\($0.product_qty))"}.joined(separator: ", "))"))
            }
            
            //print("주문시간: \(element.order_date_key) 주문 내용 : \(element.order_list.map { "\($0.product_id)(\($0.product_qty))"}.joined(separator: ", "))")
        }
        //print(orderQueues)
        
        listItems.accept(orderQueues)
        totalSum$.accept(totalSum)
    }
    
    // MARK: - Interface Builder
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalSumLabel: UILabel!
    
    
}

