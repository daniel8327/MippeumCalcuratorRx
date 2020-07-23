//
//  ReceiptViewController.swift
//  MippeumCalcurator
//
//  Created by 장태현 on 2020/07/20.
//  Copyright © 2020 장태현. All rights reserved.
//
/*
 
 1. TextView의 자동 높이 조절
    https://stackoverflow.com/questions/38714272/how-to-make-uitextview-height-dynamic-according-to-text-length
    ==============================================================================
    Tested on Xcode 11.2.1, Swift 5.1:

    All I had to do was:

    Set the constraints to the top, left, and right of the textView.
    Disable scrolling in Storyboard.
    Doing so allowed autolayout to kick in and dynamically size the textView based on its content.
    ==============================================================================
    orderListEachCount 의 height를 선언하지 않고 상, 하, 좌, 우 만 컨스트레인츠를 잡고 하부는 잡지 않는다.
    Scrolling Enabled 를 끄면 자동으로 높이가 잡힌다. Eureka!
 
 2. ScrollView 셋팅
    스토리 보드에
    View
        SafeArea <- 이 아래에
        ScrollView 를 얹는다.
    
    ScrollView를 상, 하, 좌, 우를 0,0,0,0 으로 잡아주고
 
    View
        SafeArea
        ScrollView
            Content Layout Guide
            Frame Layout Guide <- 이 아래에
            View 를 얹는다.
    그 View를
    a. 상, 하, 좌, 우를 Content Layout Guide 에 맞춰 0,0,0,0 셋팅한다.
    b. Frame Layout Guide 를 연결하여 equal width 선택한다.
 
 */
import UIKit
import RxSwift
import RxRelay

class ReceiptViewController: UIViewController {
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBinding()
    }
    
    // MARK: - UI Logic
     
    func setBinding() {

        /*rx.viewWillAppear
        .debug("viewWillAppear")
            .take(1)
            .subscribe(onNext: {[weak navigationController] _ in
                navigationController?.isNavigationBarHidden = false
            })
            .disposed(by: disposeBag)

        rx.viewWillDisappear
        .debug("viewWillDisappear")
            .take(1)
            .subscribe(onNext: {[weak self] _ in
                self?.navigationController?.isNavigationBarHidden = true
            })
            .disposed(by: disposeBag)*/
        
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
        
        // 주문 상세 내역 orderListEachCount
        orderedMenuItems
            .debug("orderListEachCount")
            .map { $0.map { "\($0.menu.item) (\($0.count.toDecimalFormat()))"}.joined(separator: "\n") }
            .bind(to: orderListEachCount.rx.text)
            .disposed(by: disposeBag)
        
        // 주문 상세 내역  orderListEachSum
        orderedMenuItems
            .debug("orderListEachSum")
            .map { $0.map { "\(($0.menu.price * $0.count).toDecimalFormat())"}.joined(separator: "\n") }
            .bind(to: orderListEachSum.rx.text)
            .disposed(by: disposeBag)
        
        // 총액 totalPrice
        orderedMenuItems
            .debug("totalPrice")
            .map { $0.map { $0.menu.price * $0.count }.reduce(0, +) }
            .map { $0.currencyKR() }
            .bind(to: totalPrice.rx.text)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Business Logic
    
    let orderedMenuItems: BehaviorRelay<[(menu: MenuItem, count: Int)]> = BehaviorRelay(value: [])
    
    var disposeBag = DisposeBag()
    
    // MARK: - Interface Builder
    
    @IBOutlet weak var orderListEachCount: UITextView!
    @IBOutlet weak var orderListEachSum: UITextView!
    @IBOutlet weak var totalPrice: UILabel!
}
