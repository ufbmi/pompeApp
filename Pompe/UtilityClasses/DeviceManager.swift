//
//  deviceManager.swift
//  diaFit
//
//  Created by Mendoza,Tonatiuh on 5/20/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//
import Foundation
import UIKit
import OAuthSwift

class DeviceManager: NSObject {
    
    let userDefaults = UserDefaults.standard
    var fitBitJsonProfile: AnyObject!
    var fitBitAge = "N/A"
    var fitBitGender = "N/A"
    var fitBitWeight = "N/A"        //
    var fitBitUnits = "N/A"         //
    var fitBitHeight = "N/A"

    let oauthswift = OAuth2Swift(
        consumerKey:    "227LKK",
        consumerSecret: "8642b55e0d227029d28f51468d1cddb5",
        authorizeUrl:   "https://www.fitbit.com/oauth2/authorize",
        accessTokenUrl: "https://api.fitbit.com/oauth2/token",
        responseType:   "token")
    
    func authorizeFitbit(_ completion: @escaping (_ result: Bool) -> Void ){
        oauthswift.accessTokenBasicAuthentification = true
            oauthswift.accessTokenBasicAuthentification = true
            let state: String = generateState(withLength: 20) as String
            oauthswift.authorize(withCallbackURL : URL(string: "com.mHealth.diaFit://oauth-callback")!, scope: "profile weight activity heartrate", state: state, success: {
                credential, response, parameters in
                if (parameters["access_token"] != nil){
                    let token = "Bearer " + (parameters["access_token"]! as! String)
                    self.userDefaults.setValue(token, forKey:"fitbitAccess")
                    completion (true)
                } else {
                    completion (false)
                }
                }, failure: { error in
                    print(error.localizedDescription)
     
            })
    }
   
    
    // get Step for a particular day
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
                                                    if let dictLevel1 = jsonDict as? [String: Any] {//level1 is json
                                                        if let arrayLevel2 = dictLevel1["activities-steps"] as? NSArray {       //a group of {}
                                                            let stepsDict: [String: Any] = arrayLevel2[0] as! [String : Any]        //[0] is a group of {}
                                                            let stepsString = stepsDict["value"] as? String
                                                            steps = Int(stepsString!)!//value is the steps
                                                            completionHandler(steps)
                                                        }
                                                    }
                                                }
            }, failure: { error in
                print ("ERROR at DeviceManager getFitbitSteps:")
                print(error)
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

    ///*********** for 30 days' entry!
    func getFitbitSteps(_ completion: @escaping (_ result: AnyObject) -> Void){
        let accessCode = self.userDefaults.string(forKey: "fitbitAccess")
        
        if(accessCode != nil){
            let access_token: [String: String] = ["Authorization":accessCode!]
            oauthswift.startAuthorizedRequest("https://api.fitbit.com/1/user/-/activities/steps/date/today/30d.json",//only 7 30 works
                                              method: OAuthSwiftHTTPRequest.Method.GET,
                                              parameters: [:],
                                              headers: access_token,
                                              success: { (data) in
                                                let jsonDict: AnyObject! = try? JSONSerialization.jsonObject(with: data.data, options: []) as AnyObject!
                                                print(jsonDict)
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
    //**working on currently
    func getFitbitWeight(_ completion: @escaping (_ result: AnyObject) -> Void){
        let accessCode = self.userDefaults.string(forKey: "fitbitAccess")
        let formatter  = DateFormatter()
        let calendar = Calendar.current
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.string(from: (calendar as NSCalendar).date(byAdding: [.day],value: 0,to: Date(),options: [])!)
        print("today is "+date)
        if(accessCode != nil){
            
            let access_token: [String: String] = ["Authorization":accessCode!]
            oauthswift.startAuthorizedRequest("https://api.fitbit.com/1/user/-/body/log/weight/date/"+date+"/30d.json",                                                method: OAuthSwiftHTTPRequest.Method.GET,
                                              parameters: [:],
                                              headers: access_token,
                                              success: { (data) in
                                                let jsonDict: AnyObject! = try? JSONSerialization.jsonObject(with: data.data, options: []) as AnyObject!
                                                print(jsonDict)
                                                completion(jsonDict)
            }, failure: { error in
                print(error.localizedDescription)
            })
        }
        else {
            self.authorizeFitbit(){(authorized: Bool) in
                if authorized {
                    self.getFitbitWeight({ (weight) in
                        completion(weight)
                    })
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
            let url = "https://api.fitbit.com/1/user/-/profile.json"    //
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
}
