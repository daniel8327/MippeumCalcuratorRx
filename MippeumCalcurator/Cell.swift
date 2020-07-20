//
//  Cell.swift
//  MippeumCalcurator3
//
//  Created by 장태현 on 2020/07/20.
//  Copyright © 2020 장태현. All rights reserved.
//

import UIKit

class Cell: UITableViewCell {

    static let identifier = "Cell"
    
    var onChanged: ((Int) -> Void)?
    
    @IBOutlet weak var title: UIButton!
    @IBOutlet weak var count: UILabel!
    @IBOutlet weak var price: UILabel!
    
    @IBAction func onAddCount(_ sender: Any) {
        
        /// TODO : observable로 
        // Tag의 값을 더해준다.
        onChanged?((sender as! UIButton).tag)
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
}
