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

    // MARK: - Life Cycle

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
    
    // MARK: - UI Logic
    
    static let identifier = "OrderQueueCell"    
    
    // MARK: - Business Logic
    
    var disposeBag = DisposeBag()
    
    // MARK: - InterfaceBuilder Links
    
    @IBOutlet weak var orderDateLabel: UILabel!
    @IBOutlet weak var orderListLabel: UILabel!
    
}
