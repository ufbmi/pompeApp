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
    var nutrientId: String
    var nutrientName: String
    var unit: String
    var value: String
    init(measures: [Serving], nutrientId: String, nutrientName: String, unit: String, value: String) {
        self.measures = measures
        self.nutrientId = nutrientId
        self.nutrientName = nutrientName
        self.unit = unit
        self.value = value
    }
}


//add unit to here
