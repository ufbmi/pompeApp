//
//  FoodLogCell.swift
//  diaFit
//
//  Created by Liang,Franky Z on 5/31/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit

class FoodLogCell: UITableViewCell {
    /*
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    */
    @IBOutlet weak var foodNameLabel: UILabel!
    @IBOutlet weak var numberServingLabel: UILabel!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}
