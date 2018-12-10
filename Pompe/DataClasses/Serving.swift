//
//  Serving.swift
//  diaFit
//
//  Created by Liang,Franky Z on 4/15/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit


class Serving {
    var label: String
    var eqv: Double
    var qty: Double
    var value: String
    init(label: String, eqv: Double, qty: Double, value: String) {
        self.label = label
        self.eqv = eqv
        self.qty = qty
        self.value = value
    }
}