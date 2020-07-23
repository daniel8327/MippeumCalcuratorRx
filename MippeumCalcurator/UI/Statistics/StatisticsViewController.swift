//
//  StatisticsViewController.swift
//  MippeumCalcuratorRx
//
//  Created by 장태현 on 2020/07/22.
//  Copyright © 2020 장태현. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RealmSwift
import Charts

class StatisticsViewController: UIViewController {

    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBinding()
        fetch()
        setChart()
    }
    
    // MARK: - UI Logic
    
    func setBinding() {

        // 두개 합치기
        Observable.merge(
            [rx.viewWillAppear.map { _ in false }
                ,rx.viewWillDisappear.map { _ in true }])
            .debug("merge")
            .map { $0 }
            .subscribe(onNext: { [weak navigationController] bool in
                navigationController?.isNavigationBarHidden = bool
            })
            .disposed(by: disposeBag)
        
        // 오늘의 총 매출
        totalPrice
            .map { $0.currencyKR() }
            .bind(to: totalSumLabel.rx.text)
            .disposed(by: disposeBag)
        
        chartItems
            .debug("fetched")
            .subscribe(onNext: { dict in
            print(dict)
        }).disposed(by: disposeBag)
        
    }
    
    // MARK: - Business Logic
    
    var chartItems: BehaviorRelay<[String : Int64]> = BehaviorRelay(value: [:])
    var totalPrice: BehaviorRelay<Int> = BehaviorRelay(value: 0)
    
    var disposeBag: DisposeBag = DisposeBag()
    
    /// 오늘의 매출 및 판매 항목을 조회한다.
    func fetch() {
        
        let frDate = Date().startTime()
        let toDate = Date().endTime()
        
        let realm = RealmCenter.INSTANCE.getRealm()
        
        let dbOrders = realm.objects(DBOrder.self)
            .filter("orderedDate >= %@", frDate)
            .filter("orderedDate <= %@", toDate)
            .sorted(byKeyPath: "orderedDate", ascending: false)
        
        let products = realm.objects(DBProducts.self)
        
        var dict = [String:Int64]()
        
        products.forEach { (product) in
            dict.updateValue(0, forKey: product.productId)
        }
        
        var totalSum = 0
        
        dbOrders.enumerated().forEach { (_, item) in
            
            totalSum += Int(item.totalPrice)
            
            item.orderedList.forEach({
                dict.updateValue(((dict[$0.productId] ?? 0) + $0.productQty), forKey: $0.productId)
            })
        }
        
        chartItems.accept(dict)
        totalPrice.accept(totalSum)
    }
    
    /// 챠트 설정
    func setChart() {
        
        // 챠트 데이터
        var dataEntry = [PieChartDataEntry]()
        
        chartItems
            .map { $0.enumerated().forEach { (_, item) in
                if item.value > 0 {
                    dataEntry.append(PieChartDataEntry(value: Double(item.value), label: item.key))
                }
            }}
            .subscribe()
            .disposed(by: disposeBag)
            
        chartView.clear()
        
        let legend = chartView.legend
        legend.horizontalAlignment = .right
        legend.verticalAlignment = .bottom
        legend.orientation = .vertical
        legend.xEntrySpace = 5
        legend.yEntrySpace = 5
        legend.yOffset = 0
        
        chartView.entryLabelColor = .darkGray
        chartView.entryLabelFont = .systemFont(ofSize: 15, weight: .light)
        
        let set = PieChartDataSet(entries: dataEntry, label: "")
        
        set.drawIconsEnabled = false
        set.sliceSpace = 2
        
        //lo_data.colors = [UIColor.green, UIColor.red, UIColor.blue, UIColor.brown, UIColor.purple]
        set.colors = ChartColorTemplates.vordiplom()
            + ChartColorTemplates.joyful()
            + ChartColorTemplates.colorful()
            + ChartColorTemplates.liberty()
            + ChartColorTemplates.pastel()
            + [UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)]
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .percent
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.multiplier = 1
        numberFormatter.percentSymbol = "%"
        
        let chartDataSetting = PieChartData(dataSet: set)
        
        chartDataSetting.setValueFormatter(DefaultValueFormatter(formatter: numberFormatter))
        chartDataSetting.setValueFont(.systemFont(ofSize: 15, weight: .light))
        chartDataSetting.setValueTextColor(.darkGray)
        
        chartView.data = chartDataSetting
        
        chartView.animate(xAxisDuration: 1.4, easingOption: .easeOutBack)
    }
        
    // MARK: - Interface Builder
    @IBOutlet weak var frDateButton: UIButton!
    @IBOutlet weak var toDateButton: UIButton!
    @IBOutlet weak var totalSumLabel: UILabel!
    @IBOutlet weak var chartView: PieChartView!
}
