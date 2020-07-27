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
        
        let firstLoad = rx.viewWillAppear
            .take(1)
            .map { _ in false}
        
        let dispappear = rx.viewWillDisappear
            .take(1)
            .map { _ in false }
        
        // 처음 보이고 사라질때 네비게이션 제어
        Observable.merge(
            [firstLoad, dispappear])
            .subscribe(onNext: { [weak navigationController] bool in
                navigationController?.isNavigationBarHidden = bool
            })
            .disposed(by: disposeBag)
        
        // 당겨서 새로고침
        let reload = tableView.refreshControl?.rx.controlEvent(.valueChanged).map { _ in } ?? Observable.just(())
        
        // 처음보이거나 재조회시 펫치요구
        Observable
            .merge([firstLoad.map { _ in }, reload])
            .bind(to: viewModel.doFetching)
            .disposed(by: disposeBag)
        
        // 액티비티 인디케이터
        viewModel.activatingObservable
            .map { !$0 }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] finished in
                if finished {
                    self?.tableView.refreshControl?.endRefreshing()
                }
            })
            .disposed(by: disposeBag)
        
        // tableView 셋팅
        viewModel
            .listItemsObservable
            .bind(to: tableView.rx.items(cellIdentifier: OrderQueueCell.identifier, cellType: OrderQueueCell.self)) { (_, item, cell) in
                cell.itemObserver.onNext(item)
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
            .bind(to: totalSumLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Interface Builder
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalSumLabel: UILabel!
}
