//
//  Nutrition.swift
//  diaFit
//
//  Created by Liang,Franky Z on 4/12/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit


class Nutrition {
    var measures: [Serving]
    var foodName: String
    var energyKCal: Double
    var protein: Double
    var lipids: Double
    var carbohydrates: Double
    
    init(measures: [Serving], foodName: String, energyKCal: Double, protein: Double, lipids: Double, carbohydrates:Double ) {
        self.measures = measures
        self.foodName = foodName
        self.energyKCal = energyKCal
        self.protein = protein
        self.lipids = lipids
        self.carbohydrates = carbohydrates
        
    }

}


//add unit to here
