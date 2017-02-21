//
//  AppDelegate.swift
//  diaFit
//
//  Created by Liang,Franky Z on 4/7/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit
import AWSCore
import OAuthSwift
import AWSSNS


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let userDefaults = UserDefaults.standard
    var window: UIWindow?
    
    let SNSPlatformApplicationArn = "arn:aws:sns:us-east-1:868559804713:app/APNS_SANDBOX/diaFitApplication"
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: AWSRegionType.usEast1,
            identityPoolId: "us-east-1:b835b4b5-88e1-4f65-bfdc-4412b06f42ac")
        
        let configuration = AWSServiceConfiguration(
            region: AWSRegionType.usEast1 ,
            credentialsProvider: credentialsProvider)
        
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        if let rememberMe = userDefaults.value(forKey: "loginFirstTime") {
            if rememberMe as! Bool == false {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.window = UIWindow(frame: UIScreen.main.bounds)
                let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil) // this assumes your storyboard is titled "Main.storyboard"
                let initialView = mainStoryboard.instantiateViewController(withIdentifier: "mainMenuNav")
                appDelegate.window?.rootViewController = initialView
                appDelegate.window?.makeKeyAndVisible()
                
            } else {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.window = UIWindow(frame: UIScreen.main.bounds)
                let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil) // this assumes your storyboard is titled "Main.storyboard"
                let initialView = mainStoryboard.instantiateViewController(withIdentifier: "loginView")
                appDelegate.window?.rootViewController = initialView
                appDelegate.window?.makeKeyAndVisible()            }
        }
        
        
        
        return true
        
        
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        if url.host == "oauth-callback" {
            OAuthSwift.handle(url:url)
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        userDefaults.synchronize()
        
    }
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
   	
    
    func dateComponentFromNSDate(_ date: Date)-> DateComponents{
        let calendarUnit: NSCalendar.Unit = [.hour, .day, .month, .year]
        let dateComponents = (Calendar.current as NSCalendar).components(calendarUnit, from: date)
        return dateComponents
    }
    
}


