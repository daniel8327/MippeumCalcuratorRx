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

class ViewController: UIViewController {
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBinding()
        fetch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let id = segue.identifier ?? ""
        if id == "OrderViewController", let targetVC = segue.destination as? OrderViewController {
            targetVC.orderedMenuItems.accept(menuItems.value.filter { $0.count > 0 })
        }
    }
    
    // MARK: - UI Logic
    
    func setBinding() {
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
            .bind(to: tableView.rx.items(cellIdentifier: "Cell", cellType: Cell.self)) {
                index, item, cell in
                
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
        
        // 총 구매한 아이템 갯수 itemCountLabel
        menuItems
            .debug("itemCountLabel")
            .map { $0.map { $0.count }.reduce(0, +) }
            .map { "\($0)" }
            .bind(to: itemCountLabel.rx.text)
            .disposed(by: disposeBag)
        
        // 최종 구매액 totalPriceLabel
        menuItems
            .debug("totalPriceLabel")
            .map { $0.map { $0.menu.price * $0.count }.reduce(0, +) }
            .map { $0.currencyKR() }
            .bind(to: totalPriceLabel.rx.text)
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
            .map { _ in "OrderViewController" }
            .subscribe(onNext: { [weak self] identifier in
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
    var disposeBag: DisposeBag = DisposeBag()
    
    func fetch() {
        indicator.isHidden = false
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
            .do(onError: { [weak self] error in
                self?.showAlert("Fetch Fail", error.localizedDescription)
                }, onDispose: { [weak self] in
                    self?.indicator.isHidden = true
                    self?.tableView.refreshControl?.endRefreshing()
            })
            .bind(to: menuItems)
            .disposed(by: disposeBag)
    }
    
    // MARK: - InterfaceBuilder Links
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var itemCountLabel: UILabel!
    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var orderButton: UIButton!
}
