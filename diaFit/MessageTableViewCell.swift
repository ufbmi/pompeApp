//
//  MessageTableViewCell.swift
//  diaFit
//
//  Created by Mendoza,Tonatiuh on 7/26/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit

class MessageTableViewCell: UITableViewCell {
    
    @IBOutlet var date: UILabel!
    @IBOutlet var message: UILabel!
    
    @IBOutlet weak var cardView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        cardView.alpha = 1
        cardView.layer.masksToBounds = false
        cardView.layer.cornerRadius = 1
        cardView.layer.shadowOffset = CGSize(width: 2,height: 2)
        cardView.layer.shadowRadius = 1
        cardView.layer.shadowOpacity = 0.2
        let path = UIBezierPath()
        cardView.layer.shadowPath = path.cgPath
        
        self.backgroundColor = UIColor.cyan
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}
