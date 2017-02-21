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
        registerForPushNotifications(application)
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
        
        // Sets up Mobile Push Notification
        let readAction = UIMutableUserNotificationAction()
        readAction.identifier = "READ_IDENTIFIER"
        readAction.title = "Read"
        readAction.activationMode = UIUserNotificationActivationMode.foreground
        readAction.isDestructive = false
        readAction.isAuthenticationRequired = true
        
        let deleteAction = UIMutableUserNotificationAction()
        deleteAction.identifier = "DELETE_IDENTIFIER"
        deleteAction.title = "Delete"
        deleteAction.activationMode = UIUserNotificationActivationMode.foreground
        deleteAction.isDestructive = true
        deleteAction.isAuthenticationRequired = true
        
        let ignoreAction = UIMutableUserNotificationAction()
        ignoreAction.identifier = "IGNORE_IDENTIFIER"
        ignoreAction.title = "Ignore"
        ignoreAction.activationMode = UIUserNotificationActivationMode.foreground
        ignoreAction.isDestructive = false
        ignoreAction.isAuthenticationRequired = false
        
        let messageCategory = UIMutableUserNotificationCategory()
        messageCategory.identifier = "MESSAGE_CATEGORY"
        messageCategory.setActions([readAction, deleteAction], for: UIUserNotificationActionContext.minimal)
        messageCategory.setActions([readAction, deleteAction, ignoreAction], for: UIUserNotificationActionContext.default)
        
        let notificationSettings = UIUserNotificationSettings(types: [UIUserNotificationType.badge, UIUserNotificationType.sound, UIUserNotificationType.alert], categories: (NSSet(array: [messageCategory])) as? Set<UIUserNotificationCategory>)
        
        UIApplication.shared.registerForRemoteNotifications()
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
        
        
        
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
    
    //PUSH NOTIFICATIONS
    
    func registerForPushNotifications(_ application: UIApplication) {
        let notificationSettings = UIUserNotificationSettings(
            types: [.badge, .sound, .alert], categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        if notificationSettings.types != UIUserNotificationType() {
            application.registerForRemoteNotifications()
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = "\(deviceToken)"
            .trimmingCharacters(in: CharacterSet(charactersIn:"<>"))
            .replacingOccurrences(of: " ", with: "")
        UserDefaults.standard.set(deviceTokenString, forKey: "deviceToken")
        let sns = AWSSNS.default()
        let request = AWSSNSCreatePlatformEndpointInput()
        request?.token = deviceTokenString
        request?.platformApplicationArn = SNSPlatformApplicationArn
        sns.createPlatformEndpoint(request!).continue(with: AWSExecutor.mainThread(), with: { (task: AWSTask!) -> AnyObject! in
            if task.error != nil {
                print("ERROR: \(task.error)")
            } else {
                let createEndpointResponse = task.result! as AWSSNSCreateEndpointResponse
               // print("endpointArn: \(createEndpointResponse.endpointArn)")
                self.userDefaults.set(createEndpointResponse.endpointArn, forKey: "endpointArn")
            }
            return nil
        })
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register:", error)
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        var remembered = false
        if userDefaults.value(forKey: "email") != nil{
            remembered = true
        }
        if let aps = userInfo["aps"] as? NSDictionary {
            if let alert = aps["alert"] as? NSString {
                let MsgReceived = UIAlertController(title: "New Message", message: alert as String, preferredStyle: .alert)
                let view = UIAlertAction(title: "View", style: .default, handler: { (action: UIAlertAction) -> Void in
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.window = UIWindow(frame: UIScreen.main.bounds)
                    if(remembered) {
                        let messagesStoryboard: UIStoryboard = UIStoryboard(name: "Messages", bundle: nil)
                        let initialView = messagesStoryboard.instantiateViewController(withIdentifier: "messageView")
                        appDelegate.window?.rootViewController = initialView
                        appDelegate.window?.makeKeyAndVisible()
                    }
                    else {
                        let messagesStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let initialView = messagesStoryboard.instantiateViewController(withIdentifier: "loginView")
                        appDelegate.window?.rootViewController = initialView
                        appDelegate.window?.makeKeyAndVisible()
                    }
                })
                let ignore = UIAlertAction(title: "Ignore", style: .default, handler: { (action: UIAlertAction) -> Void in
                })
                MsgReceived.addAction(view)
                MsgReceived.addAction(ignore)
                var hostVC = self.window?.rootViewController
                while let next = hostVC?.presentedViewController {
                    hostVC = next
                }
                hostVC?.present(MsgReceived, animated: true, completion: nil)
            }
        }
    }
}


