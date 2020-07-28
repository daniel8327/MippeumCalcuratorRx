//
//  Cell.swift
//  MippeumCalcurator3
//
//  Created by 장태현 on 2020/07/20.
//  Copyright © 2020 장태현. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

class MenuCell: UITableViewCell {
    
    static let identifier = "MenuCell"
    
    private let cellDisposeBag = DisposeBag()
    
    var disposeBag = DisposeBag()
    let itemObserver: AnyObserver<MenuModel>
    
    var onChanged: ((Int) -> Void)?

    // MARK: - Life Cycle

    required init?(coder aDecoder: NSCoder) {
        
        let item = PublishSubject<MenuModel>()
        
        itemObserver = item.asObserver()
        
        super.init(coder: aDecoder)
        
        item.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] data in
                self?.title.setTitle(data.item, for: .normal)
                self?.count.text = data.count.toDecimalFormat()
                self?.price.text = data.price.currencyKR()
            })
        .disposed(by: cellDisposeBag)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        //print("awakeFromNib")
        setBinding()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        //print("prepareForReuse")
        disposeBag = DisposeBag()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        /*print("""
            setSelected: \(selected)
            animated: \(animated)
            """)*/
    }
    
    // MARK: - UI Logic
    
    func setBinding() {
        Observable
            .merge([title.rx.tap.map { _ in 1 },
                    subtractButton.rx.tap.map { _ in -1 },
                    add5Button.rx.tap.map { _ in 5 },
                    add10Button.rx.tap.map { _ in 10 }])
            .debug("awakeFromNib merge")
            .subscribe(onNext: { [weak self] tag in
                self?.onChanged?(tag)
            }).disposed(by: cellDisposeBag)
    }
    
    // MARK: - InterfaceBuilder Links
    
    @IBOutlet weak var title: UIButton!
    @IBOutlet weak var count: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var subtractButton: UIButton!
    @IBOutlet weak var add5Button: UIButton!
    @IBOutlet weak var add10Button: UIButton!
}
