//
//  DeviceViewController.swift
//  diaFit
//
//  Created by Mendoza,Tonatiuh on 5/12/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit
import DLRadioButton
import OAuthSwift
import AWSLambda


class DeviceViewController: UIViewController {
    var deviceSelection: Int = -1
    let healthManager:HealthManager = HealthManager()
    let userDefaults = UserDefaults.standard
    let deviceManager:DeviceManager = DeviceManager()
    
    @IBOutlet var subView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let screenSize: CGRect = UIScreen.main.bounds;
        let screenWidth = screenSize.width;
        let screenHeight = screenSize.height;
        subView.center = CGPoint(x: screenWidth / 2,
            y: ((screenHeight / 2) - 150   ));
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        checkConnection()
    }

    override var shouldAutorotate : Bool {
        return false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    

    @IBAction func radiotButtonsSource(_ radioButton: DLRadioButton) {
        /*
        * The enumeration used is as follow:
        * this device = 0;
        * FITBIT = 1
        * Samsung = 2
        * AppleWatch = 3
        */
        let radioText = radioButton.selected()!.titleLabel!.text! as String
        if(radioText == "FitBit"){
            deviceSelection = 1;
        }
        else if(radioText == "This Phone/Apple Watch") {
            deviceSelection = 0;
        }
        else{
            print("Devide not yet supported");
        }
    }
    
    
    
    @IBAction func syncButton(_ sender: AnyObject) {
        switch deviceSelection {
        case 0:
            self.userDefaults.setValue(0, forKey: "device");
            if userDefaults.object(forKey: "deviceFirstTime") == nil || userDefaults.object(forKey: "healthkitAccess") == nil {
                healthManager.authorizeHealthKit { (authorized,  error) -> Void in
                    if authorized {
                        print("Authorized to HealthKit")
                        if self.userDefaults.object(forKey: "deviceFirstTime") == nil {
                            let storyBoard:UIStoryboard = UIStoryboard(name:"Profile", bundle:nil)
                            let toProfile = storyBoard.instantiateViewController(withIdentifier: "profileNav")
                            self.present(toProfile, animated: true, completion: nil)
                        } else {
                            let storyBoard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
                            let menu = storyBoard.instantiateViewController(withIdentifier: "mainMenuNav")
                            self.present(menu, animated: true, completion: nil)
                        }
                        self.userDefaults.setValue(false, forKey: "deviceFirstTime")
                        self.userDefaults.setValue("Authorized", forKey: "healthkitAccess")
                    } else {
                        if error != nil {
                            print(error)
                        }
                    }
                }
            }
            else {
                DispatchQueue.main.async {
                    let storyBoard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
                    let menu = storyBoard.instantiateViewController(withIdentifier: "mainMenuNav")
                    self.present(menu, animated: true, completion: nil)

                }
            }

        case 1 :
            self.userDefaults.setValue(1, forKey: "device");
            if userDefaults.object(forKey: "deviceFirstTime") == nil || userDefaults.object(forKey: "fitbitAccess") == nil {
                deviceManager.authorizeFitbit(){(authorized: Bool) in
                    if authorized {
                        print("Authorized to FitBit ")
                        if self.userDefaults.object(forKey: "deviceFirstTime") == nil {
                            let storyBoard:UIStoryboard = UIStoryboard(name:"Profile", bundle:nil)
                            let toProfile = storyBoard.instantiateViewController(withIdentifier: "profileNav")
                            self.present(toProfile, animated: true, completion: nil)
                        } else {
                            let storyBoard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
                            let menu = storyBoard.instantiateViewController(withIdentifier: "mainMenuNav")
                            self.present(menu, animated: true, completion: nil)
                        }
                        self.userDefaults.setValue(false, forKey: "deviceFirstTime")
                    } else {
                        print("Error in FITBIT Authorize.")
                    }
                }
                
            }
            else {
                DispatchQueue.main.async {
                    let storyBoard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
                    let menu = storyBoard.instantiateViewController(withIdentifier: "mainMenuNav")
                    self.present(menu, animated: true, completion: nil)
                }
            }
        default:
            print("Device not yet supported");
        }
        userDefaults.synchronize();
    }
}
