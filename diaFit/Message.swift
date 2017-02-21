//
//  Message.swift
//  diaFit
//
//  Created by Mendoza,Tonatiuh on 7/26/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit

class Message {
        // MARK: Properties
        
        var date: String
        var message:String
        var fullDate:String

    
        // MARK: Initialization
        
    init?(date: String, message: String, fullDate: String) {
            // Initialize stored properties.
            self.date = date
            self.message = message
            self.fullDate = fullDate

            
            // Initialization should fail if there is no name or if the rating is negative.
        if date.isEmpty || message.isEmpty || fullDate.isEmpty {
            return nil
        }
    }
}
