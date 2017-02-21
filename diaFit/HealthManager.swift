//
//  HealthManager.swift
//  diaFit
//
//  Created by Liang,Franky Z on 4/19/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import Foundation
import HealthKit

class HealthManager {
    let healthKitStore:HKHealthStore = HKHealthStore()
    func authorizeHealthKit(completionHandler: @escaping(_ success: Bool, _ error: Error?) -> Void) {
        // State the health data type(s) we want to read from HealthKit.
        let healthDataToRead = Set(arrayLiteral: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!, HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!, HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!, HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!, HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!, HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!, HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodGlucose)!, HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodGlucose)!)
        
        // State the health data type(s) we want to write to HealthKit.
        let healthDataToWrite = Set(arrayLiteral: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!, HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!, HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!, HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!)
        // If incorrect device (ex. iPad)
        if !HKHealthStore.isHealthDataAvailable() {
            print("Can't access HealthKit.")
        }
        // Request authorization to read and/or write the specific data.
        healthKitStore.requestAuthorization(toShare: healthDataToWrite, read: healthDataToRead) { (success, error) -> Void in
                completionHandler(success,error)
        }
    }
    
    // can change completion return value type to get more data
    // change dates for range of data
    func getSteps(_ sampleType: HKSampleType , completionHandler: @escaping ([HKSample], Error?) -> Void) {
        
        // Query HealthKit for the steps
        let stepsQuery = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: 0, sortDescriptors: nil) { (sampleQuery, results, error ) -> Void in
                completionHandler(results!, nil)
        }
        // Time to execute the query.
        self.healthKitStore.execute(stepsQuery)
    }
    
    func getHeight(_ sampleType: HKSampleType , completionHandler: @escaping (HKSample?, Error?) -> Void) {
        
        // Predicate for the height query
        let distantPastHeight = Date.distantPast as Date
        let currentDate = Date()
        let heightPredicate = HKQuery.predicateForSamples(withStart: distantPastHeight, end: currentDate, options: HKQueryOptions())
        // Get the single most recent height
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        // Query HealthKit for the last Height entry.
        let heightQuery = HKSampleQuery(sampleType: sampleType, predicate: heightPredicate, limit: 1, sortDescriptors: [sortDescriptor]) { (sampleQuery, results, error ) -> Void in
            if let queryError = error {
                completionHandler(nil, queryError)
                return
            }
            // Set value for most recent height
            let presentHeight = results!.first
            completionHandler(presentHeight, nil)
        }
        // Execute the query.
        self.healthKitStore.execute(heightQuery)
    }

    // return integer?
    func getBodyMass(_ sampleType: HKSampleType , completionHandler: @escaping  (HKSample?, Error?) -> Void) {
        
        // Predicate for the query
        let distantPast = Date.distantPast as Date
        let currentDate = Date()
        let bodyMassPredicate = HKQuery.predicateForSamples(withStart: distantPast, end: currentDate, options: HKQueryOptions())
        // Get the single most recent body mass
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        // Query HealthKit for most recent body mass
        let bodyMassQuery = HKSampleQuery(sampleType: sampleType, predicate: bodyMassPredicate, limit: 1, sortDescriptors: [sortDescriptor]) { (sampleQuery, results, error ) -> Void in
            
            if let queryError = error {
                completionHandler(nil, queryError)
                return
            }
            else {
            // Set value for most recent body mass
            let presentBodyMass = results!.first
                completionHandler(presentBodyMass, nil)
            }
        }
        // Execute the query.
        self.healthKitStore.execute(bodyMassQuery)
    }
    
    func getSevenDaysSteps(_ sampleType: HKSampleType , completionHandler: @escaping ([HKSample], Error?) -> Void) {
        
        // Predicate for the steps query
        let currentDate = Date()
        let calendar = Calendar.current
        let sevenDaysAgo = (calendar as NSCalendar).date(
        byAdding: [.day],
        value: -8,
        to: Date(),
        options: [])!
        let stepsPredicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: currentDate, options: HKQueryOptions())
        
        // Query HealthKit for the steps
        let stepsQuery = HKSampleQuery(sampleType: sampleType, predicate: stepsPredicate, limit: 0, sortDescriptors: nil) { (sampleQuery, results, error ) -> Void in
                completionHandler(results!, nil)
            
        }
        // Time to execute the query.
        self.healthKitStore.execute(stepsQuery)
    }
    
    func getGlucose(_ days: Int, sampleType: HKSampleType , completionHandler: @escaping ([HKSample], Error?) -> Void) {
        // Predicate for the query
        
        let currentDate = Date()
        let calendar = Calendar.current
        let totalDays = (calendar as NSCalendar).date(
            byAdding: [.day],
            value: -days,
            to: Date(),
            options: [])!
        let glucosePredicate = HKQuery.predicateForSamples(withStart: totalDays, end: currentDate, options: HKQueryOptions())
        
        // Get glucose
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        // Query HealthKit for most recent glucose
        let glucose = HKSampleQuery(sampleType: sampleType, predicate: glucosePredicate, limit: 0, sortDescriptors: [sortDescriptor]) { (sampleQuery, results, error ) -> Void in
            if(error != nil){
                print(error)
            }
            else {
                completionHandler(results!, nil)
            }
        }
        // Execute the query.
        self.healthKitStore.execute(glucose)
    }
    
}
