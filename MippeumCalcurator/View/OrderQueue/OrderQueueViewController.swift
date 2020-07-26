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
    let viewModel: OrderQueueViewModelType
    var disposeBag = DisposeBag()

    // MARK: - Life Cycle

    init(viewModel: OrderQueueViewModelType = OrderQueueViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        viewModel = OrderQueueViewModel()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.refreshControl = UIRefreshControl()
        setBinding()
    }
    
    // MARK: - UI Logic
    
    func setBinding() {
        
        let firstLoad = rx.viewWillAppear.take(1)
        .debug("viewWillAppear").map { _ in false}
        let dispappear = rx.viewWillDisappear.take(1)
        .debug("viewWillDisappear").map { _ in false }
        
        // 처음 보이고 사라질때 네비게이션 제어
        Observable.merge(
            [firstLoad, dispappear])
            .debug("OrderQueue merge([firstLoad, dispappear])")
            .subscribe(onNext: { [weak navigationController] bool in
                navigationController?.isNavigationBarHidden = bool
            })
            .disposed(by: disposeBag)
        
        // 당겨서 새로고침
        let reload = tableView.refreshControl?.rx.controlEvent(.valueChanged).map { _ in } ?? Observable.just(())
        
        Observable
            .merge([firstLoad.map { _ in }, reload])
            .debug("OrderQueue merge([firstLoad.map { _ in }, reload])")
            .bind(to: viewModel.doFetching)
            .disposed(by: disposeBag)
        
        // 액티비티 인디케이터
        viewModel.activatingObservable
            .map { !$0 }
            .debug("OrderQueue activatingObservable")
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] finished in
                if finished {
                    self?.tableView.refreshControl?.endRefreshing()
                }
            })
            .subscribe(onNext: { print($0)})
            .disposed(by: disposeBag)
        
        // tableView 셋팅
        viewModel
            .listItemsObservable
            .debug("OrderQueue tableView")
            .bind(to: tableView.rx.items(cellIdentifier: OrderQueueCell.identifier, cellType: OrderQueueCell.self)) { (_, item, cell) in
                
                let dateFormatter = DateFormatter()

                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:sssZ"
                dateFormatter.timeZone = NSTimeZone(name: "KR") as TimeZone?

                let date:Date = dateFormatter.date(from: item.orderedDate)!
                
                dateFormatter.dateFormat = "HH:mm:ss"
                let dateStr = dateFormatter.string(from: date)
                
                cell.orderDateLabel.text = dateStr
                cell.orderListLabel.text = item.orderedList
                
        }.disposed(by: disposeBag)
        
//        // 왼쪽으로 밀어서 삭제
//        tableView.rx.itemDeleted
//            .subscribe(onNext: {[weak self] indexPath in
//                
//                guard let self = self else {
//                    return
//                }
//                
//                var newList = self.viewModel.listItemsObservable..value
//                
//                let realm = RealmCenter.INSTANCE.getRealm()
//                
//                let data = realm.objects(DBOrder.self).filter("orderedDateKey == %@", newList[indexPath.row].orderedDate)
//                
//                realm.beginWrite()
//                
//                data
//                    .enumerated()
//                    .map { _, item in
//                    item.isDone = true // 제작 완료 처리
//                }
//                realm.add(data, update: .modified)
//                
//                do {
//                    try realm.commitWrite()
//
//                    newList.remove(at: indexPath.row)
//                    self.listItems.accept(newList)
//                    
//                } catch let error {
//                    print("tableView Row Delete failed .. \(error.localizedDescription)")
//                }
//        })
//        .disposed(by: disposeBag)
        
        // 오늘의 총 매출
        viewModel.totalPriceObservable
            .debug("OrderQueue totalPriceObservable")
            .bind(to: totalSumLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Business Logic
//
//    var listItems: BehaviorRelay<[OrderQueueModel]> = BehaviorRelay(value: [])
//    var totalPrice: BehaviorRelay<Int> = BehaviorRelay(value: 0)
//
//    /// 오늘의 매출 누계와 대기 주문 내역 조회
//    func fetch() {
//
//        let frDate = Date().startTime()
//        let toDate = Date().endTime()
//
//        let realm = RealmCenter.INSTANCE.getRealm()
//
//        let dbOrders = realm.objects(DBOrder.self)
//            .filter("orderedDate >= %@", frDate)
//            .filter("orderedDate <= %@", toDate)
////            .filter("isDone == false") 총 매출을 계산해야하므로 제작완료도 포함해야한다.
//            .sorted(byKeyPath: "orderedDate", ascending: false)
//
//        var orderQueues: [OrderQueueModel] = []
//        var totalSum = 0
//
//        dbOrders
//            .enumerated()
//            .map { _, item in
//
//                totalSum += Int(item.totalPrice)
//
//                if !item.isDone {
//                    orderQueues.append(OrderQueueModel(
//                        orderedDate: item.orderedDateKey
//                        ,orderedList: "\(item.orderedList.map { "\($0.productId)(\($0.productQty))"}.joined(separator: ", "))"))
//                }
//
//                //print("주문시간: \(element.order_date_key) 주문 내용 : \(element.order_list.map { "\($0.product_id)(\($0.product_qty))"}.joined(separator: ", "))")
//        }
//
//        listItems.accept(orderQueues)
//        totalPrice.accept(totalSum)
//
//        self.tableView.refreshControl?.endRefreshing()
//    }
    
    // MARK: - Interface Builder
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalSumLabel: UILabel!
}
