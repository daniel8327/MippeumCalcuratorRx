//
//  StatisticsViewController.swift
//  MippeumCalcuratorRx
//
//  Created by 장태현 on 2020/07/22.
//  Copyright © 2020 장태현. All rights reserved.
//

import UIKit

import Charts
import RealmSwift
import RxSwift
import RxCocoa

class StatisticsViewController: UIViewController {
    
    static let identifier = "StatisticsViewController"

    let viewModel: StatisticsViewModelType
    var disposeBag = DisposeBag()
    
    // MARK: - Life Cycle
    
    init(viewModel: StatisticsViewModelType = StatisticsViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.viewModel = StatisticsViewModel()
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        // 처음 펫치요구
        firstLoad
            .map { _ in }
            .bind(to: viewModel.doFetchingRealm)
            .disposed(by: disposeBag)
        
        // 오늘의 총 매출
        viewModel.totalPriceObservable
            .bind(to: totalSumLabel.rx.text)
            .disposed(by: disposeBag)
        
        // 오늘의 매출 및 판매 항목을 조회한다.
        // 챠트 설정
        self.setChart()
    }
    
    /// 오늘의 매출 및 판매 항목을 조회한다.
    /// 챠트 설정
    func setChart() {
        
        // 챠트 데이터
        var dataEntry = [PieChartDataEntry]()
        
        viewModel.chartItemObservable
            .map { $0.enumerated().map { _, item in
                if item.value > 0 {
                    dataEntry.append(PieChartDataEntry(value: Double(item.value), label: item.key))
                }
            }}
            .subscribe(onNext: { [weak self] _ in
                self?.setDataEntry(dataEntry: dataEntry)
            })
            .disposed(by: disposeBag)
    }
    
    /// 챠트에 들어갈 데이터엔트리를 설정한다.
    /// - Parameter dataEntry: [PieChartDataEntry]
    func setDataEntry(dataEntry: [PieChartDataEntry]) {
        
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
