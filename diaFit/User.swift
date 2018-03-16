//
//  User.swift
//  diaFit
//
//  Created by Mendoza,Tonatiuh on 8/25/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import Foundation
import UIKit

class User: NSObject, NSCoding {
    var age: String
    var height: String
    var weight: String
    var gender: Int //0 == male , 1 == female
    var metric: Bool
    var pal: Double
    var completeData:Bool = true
    
    struct PropertyKey {
        static let ageKey = "age"
        static let heightKey = "height"
        static let weightKey = "weight"
        static let genderKey = "gender"
        static let metricKey = "metric"
        static let pal = "physicalActivityLevel"
        static let completeDataKey = "completedata"
    }
    
    init?(age: String, height:String, weight:String, gender:Int, pal:Double, metric:Bool){
        self.metric = metric
        if(age == "" || age == "N/A"){
            self.age = "0.0"
            completeData = false
        }
        else {
            self.age = age
        }
        
        //Height can be a double already or can be what it comes from the viewController
        let isdouble = Double(height) != nil
        if isdouble  {
            self.height = height
        }
        else if(height == "N/A"){
            self.height = "0.0"
            completeData = false
        }
        else {
            let heightChars = height.characters.split(separator: "'").map(String.init)
            self.height = String(Double(heightChars[0])! * 30.48 + Double(heightChars[1])! * 2.54)
        }
        if (weight == "N/A" || weight == "0.0"){
            self.weight = "0.0"
            completeData = false;
        }
        else {
            self.weight = String(Double(weight)!)
        }
        if(pal == 0.0 || pal == 1.0) {
            // So we don't allow unselected pals here (which will be 1.0 or 0.0)
            self.pal = 1.0
            completeData = false;
        }
        else {
            self.pal = pal
        }
        if(gender == -1){
            self.gender = gender
            completeData = false;
        }
        else {
            self.gender = gender
        }
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
        print("GENDER AT ENCODER")
        aCoder.encode(age, forKey: PropertyKey.ageKey)
        aCoder.encode(height, forKey: PropertyKey.heightKey)
        aCoder.encode(weight, forKey: PropertyKey.weightKey)
        aCoder.encodeCInt(Int32(gender), forKey: PropertyKey.genderKey)
        aCoder.encode(pal, forKey: PropertyKey.pal)
        aCoder.encode(metric, forKey:  PropertyKey.metricKey)
    }
    
    required convenience init?(coder aDecoder:NSCoder){
        print(aDecoder)
        let age = aDecoder.decodeObject(forKey: PropertyKey.ageKey) as! String
        let height = aDecoder.decodeObject(forKey: PropertyKey.heightKey) as! String
        let weight = aDecoder.decodeObject(forKey: PropertyKey.weightKey) as! String
        let gender = aDecoder.decodeCInt(forKey: PropertyKey.genderKey)
        let pal = aDecoder.decodeDouble(forKey: PropertyKey.pal)
        let metric = aDecoder.decodeBool(forKey: PropertyKey.metricKey)
        self.init(age: age, height: height, weight: weight, gender:Int(gender), pal: pal, metric:metric)
    }
    
    func getCalories()->Double{
        var wVar = 0.0
        if(metric){
            wVar = 10.0 * Double(self.weight)! as Double
        }
        else {
            wVar = 10.0 * (Double(weight)! * 0.453592) as Double
        }
        var calories = 0.0;
        
        let hVar = 6.25 * Double(self.height)!
        //Male
        if(gender == 0){
            let aVar = 5.0 * Double(self.age)! as Double
            calories =  wVar + hVar - aVar + 5.0
        }
        else {
            let aVar = 5.0 * Double(self.age)! as Double
            calories =  wVar + hVar - aVar - 161.0
        }
        // We calculate the calories by multiplying the pal coefficient
        return calories * pal
    }
    
}
