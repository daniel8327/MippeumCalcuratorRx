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
    
    let viewModel: MenuViewModelType
    var disposeBag: DisposeBag = DisposeBag()
    
    init(viewModel: MenuViewModelType = MenuViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        viewModel = MenuViewModel()
        super.init(coder: aDecoder)
    }
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.refreshControl = UIRefreshControl()
        setBinding()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let identifier = segue.identifier ?? ""
        
        if identifier == ReceiptViewController.identifier,
            let menus = sender as? [MenuModel],
            let targetVC = segue.destination as? ReceiptViewController {
                targetVC.viewModel = ReceiptViewModel(menus)
        }
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
        Observable.merge([firstLoad.map { _ in () }, reload])
            .bind(to: viewModel.doFetchingRealm)
            .disposed(by: disposeBag)

        // 처음 보일때 하고 clear 버튼 눌렀을 때
        let viewDidAppear = rx.viewWillAppear.map { _ in () }
        let whenClearTap = clearButton.rx.tap.map { _ in () }
        
        Observable.merge([viewDidAppear, whenClearTap])
            .bind(to: viewModel.doClearing)
            .disposed(by: disposeBag)

        // tableView bind
        viewModel.menuObservable
            .debug("tableview")
            .bind(to: tableView.rx.items(cellIdentifier: MenuCell.identifier, cellType: MenuCell.self)) { _, item, cell in
                
                cell.title.setTitle(item.item, for: .normal)
                cell.price.text = item.price.currencyKR()
                cell.count.text = item.count.toDecimalFormat()
                
                cell.onChanged  = { [weak self] count in
                    guard let self = self else { return }
                    self.viewModel.doAddCounting.onNext((menuModel: item, sum: count))
                }
        }.disposed(by: disposeBag)
        
        // 최종 구매액 totalPriceLabel
        viewModel.totalPriceObservable
            .bind(to: totalPriceLabel.rx.text)
            .disposed(by: disposeBag)
        
        // 선택된 아이템 총개수
        viewModel.totalSelectedCountObservable
            .bind(to: itemCountLabel.rx.text)
            .disposed(by: disposeBag)
        
        // 주문 orderButton 눌렀을때
        orderButton.rx.tap
            .debug("주문 orderButton 눌렀을때")
            .bind(to: viewModel.doOrdering)
            .disposed(by: disposeBag)
        
        // 주문 orderButton 이동 X (realm 저장후 초기화)
        
        // 주문내역 orderHistory 눌렀을때
        orderHistory.rx.tap
            .bind(to: viewModel.goOrderHisory)
            .disposed(by: disposeBag)
        
        // 주문내역 orderHistory 이동
        viewModel.showOrderHistoryObservable
            .subscribe(onNext: { [weak self] _ in
                self?.performSegue(withIdentifier: OrderQueueViewController.identifier, sender: nil)
            })
            .disposed(by: disposeBag)

        // 영수증보기 orderReceipt 눌렀을때
        orderReceipt.rx.tap
            .bind(to: viewModel.goReceipt)
            .disposed(by: disposeBag)
        
        // 영수증보기 orderReceipt 이동
        viewModel.showReceiptObservable
            .subscribe(onNext: { [weak self] data in
                self?.performSegue(withIdentifier: ReceiptViewController.identifier, sender: data)
            })
            .disposed(by: disposeBag)
        
        // 에러 처리
        viewModel.errorObservable
            .map { $0.domain }
            .subscribe(onNext: { [weak self] message in
                self?.showAlert("Order Fail", message)
            })
            .disposed(by: disposeBag)
        
        // 액티비티 인디케이터
        viewModel.activatingObservable
            .map { !$0 }
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] finished in
                if finished {
                    self?.tableView.refreshControl?.endRefreshing()
                }
            })
            .bind(to: indicator.rx.isHidden)
            .disposed(by: disposeBag)
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
