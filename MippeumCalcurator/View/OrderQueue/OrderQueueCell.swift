//
//  OrderQueueCell.swift
//  MippeumCalcuratorRx
//
//  Created by 장태현 on 2020/07/21.
//  Copyright © 2020 장태현. All rights reserved.
//

import UIKit

import RxCocoa
import RxSwift

class OrderQueueCell: UITableViewCell {
    
    static let identifier = "OrderQueueCell"
    
    var disposeBag = DisposeBag()
    let itemObserver: AnyObserver<OrderQueueModel>
    
    // MARK: - Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        
        let item = PublishSubject<OrderQueueModel>()
        
        itemObserver = item.asObserver()
        
        super.init(coder: aDecoder)
        
        item
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] data in
                
                let dateFormatter = DateFormatter()

                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:sssZ"
                dateFormatter.timeZone = NSTimeZone(name: "KR") as TimeZone?

                let date:Date = dateFormatter.date(from: data.orderedDate)!
                
                dateFormatter.dateFormat = "HH:mm:ss"
                let dateStr = dateFormatter.string(from: date)
                
                self?.orderDateLabel.text = dateStr
                self?.orderListLabel.text = data.orderedList
            })
            .disposed(by: disposeBag)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        print("awakeFromNib")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        print("prepareForReuse")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        print("""
            setSelected: \(selected)
            animated: \(animated)
            """)
        // Configure the view for the selected state
    }
    
    // MARK: - InterfaceBuilder Links
    
    @IBOutlet weak var orderDateLabel: UILabel!
    @IBOutlet weak var orderListLabel: UILabel!
    
}
