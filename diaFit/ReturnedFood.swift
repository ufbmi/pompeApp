//
//  ReturnedFood.swift
//  diaFit
//
//  Created by Liang,Franky Z on 5/24/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import Foundation

class ReturnedFood {
    var foodName: String
    var foodNDBNO: String
    var pickedServing: String
    var inputServing: String
    var energyKCal: String
    var protein: String
    var lipids: String
    var carbohydrates: String
    
    var date: String
    
    init(foodName: String, foodNDBNO: String, pickedServing: String, inputServing: String,energyKCal: String, protein: String, lipids: String, carbohydrates: String, date: String) {
        self.foodName = foodName
        self.foodNDBNO = foodNDBNO
        self.pickedServing = pickedServing
        self.inputServing = inputServing
        self.energyKCal = energyKCal
        self.protein = protein
        self.lipids = lipids
        self.carbohydrates = carbohydrates
        self.date = date
    }
}
