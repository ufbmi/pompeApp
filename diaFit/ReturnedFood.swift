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
    var inputServing: String //or int?
    var energyKJ: String
    var energyKCal: String
    var protein: String
    var lipids: String
    var carbohydrates: String
    var dietaryFiber: String
    var totalSugars: String
    var calcium: String
    var iron: String
    var potassium: String
    var sodium: String
    var vitAIU: String
    var vitARAE: String
    var vitC: String
    var vitB6: String
    var cholesterol: String
    var transFat: String
    var saturatedFat: String
    var date: String
    
    init(foodName: String, foodNDBNO: String, pickedServing: String, inputServing: String, energyKJ: String, energyKCal: String, protein: String, lipids: String, carbohydrates: String, dietaryFiber: String, totalSugars: String, calcium: String, iron: String, potassium: String, sodium: String, vitAIU: String, vitARAE: String, vitC: String, vitB6: String, cholesterol: String, transFat: String, saturatedFat: String, date: String) {
        self.foodName = foodName
        self.foodNDBNO = foodNDBNO
        self.pickedServing = pickedServing
        self.inputServing = inputServing
        self.energyKCal = energyKCal
        self.energyKJ = energyKJ
        self.protein = protein
        self.lipids = lipids
        self.carbohydrates = carbohydrates
        self.dietaryFiber = dietaryFiber
        self.totalSugars = totalSugars
        self.calcium = calcium
        self.iron = iron
        self.potassium = potassium
        self.sodium = sodium
        self.vitAIU = vitAIU
        self.vitARAE = vitARAE
        self.vitC = vitC
        self.vitB6 = vitB6
        self.cholesterol = cholesterol
        self.transFat = transFat
        self.saturatedFat = saturatedFat
        self.date = date
    }
}