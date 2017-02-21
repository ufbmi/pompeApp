//
//  deviceManager.swift
//  diaFit
//
//  Created by Mendoza,Tonatiuh on 5/20/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//
import Foundation
import UIKit
import HealthKit
import OAuthSwift

class DeviceManager: NSObject {
    
    let healthManager:HealthManager = HealthManager()
    let userDefaults = UserDefaults.standard
    var fitBitJsonProfile: AnyObject!
    var fitBitAge = "N/A"
    var fitBitGender = "N/A"
    var fitBitWeight = "N/A"
    var fitBitUnits = "N/A"
    var fitBitHeight = "N/A"

    let oauthswift = OAuth2Swift(
        consumerKey:    "2284P3",
        consumerSecret: "8555f9c56302416e08ee6c34e6a4b972",
        authorizeUrl:   "https://www.fitbit.com/oauth2/authorize",
        accessTokenUrl: "https://api.fitbit.com/oauth2/token",
        responseType:   "token")
    
    func authorizeFitbit(_ completion: @escaping (_ result: Bool) -> Void ){
        oauthswift.accessTokenBasicAuthentification = true
        self.userDefaults.setValue(1, forKey: "device");
        let accessCode = self.userDefaults.string(forKey: "fitbitAccess")
        if accessCode == nil  {
            oauthswift.accessTokenBasicAuthentification = true
            let state: String = generateState(withLength: 20) as String
            oauthswift.authorize(withCallbackURL : URL(string: "com.mHealth.diaFit://oauth-callback")!, scope: "profile weight activity heartrate", state: state, success: {
                credential, response, parameters in
                if (parameters["access_token"] != nil){
                    
                    let token = "Bearer " + (parameters["access_token"]! as! String)
                    self.userDefaults.setValue(token, forKey:"fitbitAccess")
                    print(self.userDefaults.value(forKey: "fitbitAccess")!)
                    completion (true)
                } else {
                    completion (false)
                }
                }, failure: { error in
                    print(error.localizedDescription)
     
            })
        }
    }
    
        
    func getFitBitSteps(_ date:String, completionHandler: @escaping (_ result: Int) -> Void ){
        let accessCode = self.userDefaults.string(forKey: "fitbitAccess")
        var steps = 0
        if(accessCode != nil){
            let access_token: [String: String] = ["Authorization":accessCode!]
            let url = "https://api.fitbit.com/1/user/-/activities/steps/date/" + date + "/1d.json"
            oauthswift.startAuthorizedRequest(url,
                                              method: OAuthSwiftHTTPRequest.Method.GET,
                                              parameters: [:],
                                              headers: access_token,
                                              success: { (data) in
                                                if let jsonDict: AnyObject? = try? JSONSerialization.jsonObject(with: data.data, options: []) as AnyObject!{
                                                    if let dictLevel1 = jsonDict as? [String: Any] {
                                                        if let arrayLevel2 = dictLevel1["activities-steps"] as? NSArray {
                                                            let stepsDict: [String: Any] = arrayLevel2[0] as! [String : Any]
                                                            let stepsString = stepsDict["value"] as? String
                                                            steps = Int(stepsString!)!
                                                            completionHandler(steps)
                                                        }
                                                    }
                                                }
                }, failure: { error in
                    print ("ERROR at DeviceManager getFitbitSteps:")
                    print(error)
            })
        }
        else {
            self.authorizeFitbit(){(authorized: Bool) in
                if authorized {
                    self.getFitBitSteps(date){(steps: Int) in
                        completionHandler(steps)
                    }
                }
                else {
                    print("Error: Authorzing to use FITBIT")
                }
            }
        }
    }
    
    func getUserProfile(_ completionHandler: @escaping (_ result: Bool) -> Void ){
        let accessCode = self.userDefaults.string(forKey: "fitbitAccess")
        if(accessCode != nil){
            let access_token: [String: String] = ["Authorization":accessCode!]
            let url = "https://api.fitbit.com/1/user/-/profile.json"
            oauthswift.startAuthorizedRequest(url,
                                          method: OAuthSwiftHTTPRequest.Method.GET,
                                          parameters: [:],
                                          headers: access_token,
                                          success: { (data) in
                                            let jsonDict: AnyObject! = try? JSONSerialization.jsonObject(with: data.data, options: [])  as AnyObject!
                                            if let dictLevel1 = jsonDict as? [String: Any] {
                                                if let dictLevel2 = dictLevel1["user"] as? [String: Any] {
                                                    let age = dictLevel2["age"] as? NSNumber
                                                    self.fitBitAge = (age?.stringValue)!
                                                    self.fitBitGender = dictLevel2["gender"] as! String
                                                    let weight = dictLevel2["weight"] as? NSNumber
                                                    self.fitBitWeight = (weight?.stringValue)!
                                                    self.fitBitUnits = dictLevel2["weightUnit"] as! String
                                                    let height = dictLevel2["height"] as? NSNumber
                                                    self.fitBitHeight = (height?.stringValue)!
                                                    
                                                }
                                            }
                               // self.fitBitJsonProfile = jsonDict
                                completionHandler(true)
            }, failure: { error in
                print("Error at getUserProfile:")
                print(error)
                completionHandler(false)
        })
        }
        else {
            self.authorizeFitbit(){(authorized: Bool) in
                if authorized {
                    
                }
                else {
                    print("Error: Authorzing to use FITBIT")
                }
            }
        }
    }
    
    func getFitBitAge()->String{
        return fitBitAge
    }
    
    func getFitBitGender()->String{
        return fitBitGender
    }
    
    func getFitBitHeight()->String{
        if(fitBitUnits != "N/A"){
            if(fitBitUnits == "en_US"){
                let heightDouble = Double(fitBitHeight)
                let foot = round(heightDouble! * 0.393701 / 12)
                let inches = round((heightDouble! * 0.393701).truncatingRemainder(dividingBy: 1))
                return String(Int(foot)) + "'" +  String(Int(inches))
            }
            else {
                return fitBitHeight
            }
        }
        else {
            return fitBitHeight
        }
    }
    
    func getFitBitWeight()->String{
        if(fitBitUnits != "N/A"){
            if(fitBitUnits == "en_US"){
                let weightDouble = Double(fitBitWeight)
                return String(weightDouble! * 2.2)
                
            }
            else {
                return fitBitWeight
            }
        }
        else {
            return fitBitWeight
        }
    }
    
    func healthKitGetAge() -> String{
        var result = "N/A"
        do {
            let currentDate = Date()
            let dateOfBirth = try healthManager.healthKitStore.dateOfBirth()
            let difference = (Calendar.current as NSCalendar).components(.year, from: dateOfBirth, to: currentDate, options: NSCalendar.Options(rawValue: 0))
            result = String(describing: difference.year)
        } catch {
            if(error._code != 0 ) {
                print ("Error at healthKitGetAge() ",error)
            }
        }
        return result
    }
    
    func healthKitGetGender() -> String{
        var result = "N/A"
        do {
            
            let gender = try healthManager.healthKitStore.biologicalSex().biologicalSex.rawValue
            if(gender == 1){
                result = "Female"
            }
            else if( gender == 2){
                result = "Male"
            }
            
        } catch {
            result =  "N/A"
        }
        return result
    }
    
    func authorizeHealthKit(_ completionHandler: @escaping (_ result: Bool) -> Void ){
        DispatchQueue.main.async {
            self.healthManager.authorizeHealthKit { (authorized,  error) -> Void in
                if authorized {
                    completionHandler(true)
                } else {
                    if error != nil {
                        NSLog("authorizeHealthkit Error: Not able to get authorization.")
                        completionHandler(true)
                    }
                }
                
            }
        }
    }
    
    func getFitbitSteps(_ completion: @escaping (_ result: AnyObject) -> Void){
        let accessCode = self.userDefaults.string(forKey: "fitbitAccess")
        if(accessCode != nil){
            let access_token: [String: String] = ["Authorization":accessCode!]
            oauthswift.startAuthorizedRequest("https://api.fitbit.com/1/user/-/activities/steps/date/today/30d.json",
                                              method: OAuthSwiftHTTPRequest.Method.GET,
                                              parameters: [:],
                                              headers: access_token,
                                              success: { (data) in
                                                let jsonDict: AnyObject! = try? JSONSerialization.jsonObject(with: data.data, options: []) as AnyObject!
                                                completion(jsonDict)
            }, failure: { error in
                print(error.localizedDescription)
            })
        }
        else {
            self.authorizeFitbit(){(authorized: Bool) in
                if authorized {
                    self.getFitbitSteps({ (steps) in
                        completion(steps)
                    })
                }
                else {
                    print("Error: Authorzing to use FITBIT")
                }
            }
        }
    }
    
    func healthKitGetHeight(_ completionHandler: @escaping (_ result: String) -> Void) {
        var height: HKQuantitySample?
        let heightSample = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)
        // Call HealthKitManager's getSample() method to get the user's height.
        self.healthManager.getHeight(heightSample!, completionHandler: { (userHeight, error) -> Void in
            if( error != nil ) {
                NSLog("Error at HKGetHeight: \(error)")
            }
            var heightString = "N/A"
            height = userHeight as? HKQuantitySample
            // The height is formatted to the user's locale.
            let meters = height?.quantity.doubleValue(for: HKUnit.meter())
            if(meters != nil){
                let formatHeight = LengthFormatter()
                formatHeight.isForPersonHeightUse = true
                heightString = formatHeight.string(fromMeters: meters!)
            }
            completionHandler(heightString)
            
        })
    }
    
    func hKGlucoseIsEmpty(_ completionHandler:@escaping (Bool) -> Void){
        authorizeHealthKit { (result) in
            let glucoseSample = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodGlucose)
            self.healthManager.getGlucose(365, sampleType: glucoseSample!, completionHandler: { (glucoseValues, error) -> Void in
                if( error != nil ) {
                    NSLog("Error at healthKitGetGlucose: \(error?.localizedDescription)")
                }
                else {
                    let result = glucoseValues.isEmpty
                    completionHandler(result)
                }
            })
        }
    }
    
        func healthKitGetGlucose(_ days: Int, completionHandler: @escaping (_ result: [Int:(Int,Double)]) -> Void) {
            let glucoseSample = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodGlucose)
            // Call HealthKitManager's getSample() method to get the user's glucose.
            self.healthManager.getGlucose(days, sampleType: glucoseSample!, completionHandler: { (glucoseValues, error) -> Void in
                if( error != nil ) {
                    NSLog("Error at healthKitGetGlucose: \(error?.localizedDescription)")
                } else {
                    
                }
                let calendar = Calendar.current
                let glucoseArray = glucoseValues as? [HKQuantitySample]
                var resultArray = [Int:(Int,Double)]()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "M/dd/yyyy"
                for grabbedDate in glucoseArray! {
                    for i in 0..<days {
                        let dateToDisplay = dateFormatter.string(from: (calendar as NSCalendar).date(byAdding: .day, value: (-i), to: Date(), options: [])!)
                        let formattedEmptyDate = dateFormatter.date(from: dateToDisplay)
                        let components = (calendar as NSCalendar).components(.day , from: formattedEmptyDate!)
                        let dateNumber = Int(components.day!)
                        if dateToDisplay == dateFormatter.string(from: grabbedDate.endDate) {
                            let mgPerdL = HKUnit.init(from:  "mg/dL")
                            let value = grabbedDate.quantity.doubleValue(for: mgPerdL)
                            resultArray[-i] = (dateNumber, value)
                            break;
                        }
                    }
                }
                for i in 0 ..< days {
                    let dateToDisplay = dateFormatter.string(from: (calendar as NSCalendar).date(byAdding: .day, value: (-i), to: Date(), options: [])!)
                    let formattedEmptyDate = dateFormatter.date(from: dateToDisplay)
                    let components = (calendar as NSCalendar).components(.day , from: formattedEmptyDate!)
                    let dateNumber = Int(components.day!)
                    if  resultArray[-i] == nil {
                        resultArray[-i] = (dateNumber, 0.0)
                    }
                }
                completionHandler(resultArray)
                
            })
    }
    

func healthKitGetWeight(_ completionHandler: @escaping (_ result: String) -> Void) {
    var weight: HKQuantitySample?
    var weightString = "N/A"
    // Create the HKSample for Weight.
    let weightSample = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)
    // Call HealthKitManager's getSample() method to get the user's height.
    self.healthManager.getBodyMass(weightSample!, completionHandler: { (userWeight, error) -> Void in
        if( error != nil ) {
            NSLog("Error at HKWeight: \(error?.localizedDescription)")
            return
        }
        var weightInt: Int?
        weight = userWeight as? HKQuantitySample
        if let pounds = weight?.quantity.doubleValue(for: HKUnit.pound()) {
            weightInt = Int(pounds)
        }
        if(weightInt != nil){
            weightString = String(weightInt!)
        }
        completionHandler(weightString)
        
    })
}

}
