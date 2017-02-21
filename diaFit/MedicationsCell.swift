//
//  MedicationsCell.swift
//  diaFit
//
//  Created by Mendoza,Tonatiuh on 5/17/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit

class MedicationsCell: UITableViewCell {
    @IBOutlet weak var medName: UILabel!
    @IBOutlet weak var dose: UILabel!
    @IBOutlet weak var reminder: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
