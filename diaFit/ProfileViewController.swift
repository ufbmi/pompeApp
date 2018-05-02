//
//  ProfileViewController.swift
//  diaFit
//
//  Created by Liang,Franky Z on 4/12/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit
import AWSLambda
import AWSCore
import HealthKit
import OAuthSwift
import ActionSheetPicker_3_0

class ProfileViewController: ChildViewController {
    
    let healthManager:HealthManager = HealthManager()
    let deviceManager:DeviceManager = DeviceManager()
    var height: HKQuantitySample?
    var age: Int?
    var weight: HKQuantitySample?
    var heightStr: String?
    var weightStr: String?
    var ageStr: String?
    var genderStr: String?
    let defaults = UserDefaults.standard
    var deviceType: Int = -1
    var weightNumbers: [Int] = []
    var ageNumbers:[Int] = []
    var metric: Bool = false
    // This PAL is for the User model to calculate calories, for which the mapped values are below: (But not for the database)
    // We want to store directly the text / discription into the db
    var PAL: Double = 1.0
    let palMap:[Double] = [1.4, 1.6, 1.8, 2.0]
    
    let userDefaults = UserDefaults.standard
    
    @IBOutlet weak var onEmploymentStatus: UIButton!
    @IBOutlet weak var onEducationStatus: UIButton!
    @IBOutlet weak var raceButton: UIButton!
    @IBOutlet weak var onMaritalStatus: UIButton!
    @IBOutlet weak var onFamilyHistory: UIButton!
    @IBOutlet weak var onGender: UIButton!
    @IBOutlet weak var onAge: UIButton!
    @IBOutlet weak var onHeight: UIButton!
    @IBOutlet weak var onWeight: UIButton!
    @IBOutlet weak var onPhysicalActivity: UIButton!
    
    var scrollView: UIScrollView!
    
    
    @IBOutlet weak var userLabel: UILabel!
    
    override func viewDidAppear(_ animated: Bool) {
        underLine()
        checkConnection()
        
    }

    override var shouldAutorotate : Bool {
        return false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        createWeight()
        createAge()
        getProfile()

        
    }
    
    func underLine() {
        let underlineAttribute = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
        let underlineAttributedString = NSAttributedString(string: "User Information", attributes: underlineAttribute)
        userLabel.attributedText = underlineAttributedString
    }
    
    @IBAction func onEmploymentStatus(_ sender: AnyObject) {
        ActionSheetMultipleStringPicker.show(withTitle: "Employment Status", rows: [
            ["Employed for wages","Self-employed","Out of work/looking", "Out of work/not looking", "A homemaker", "A student", "Military", "Retired","Unable to work"],
            
            ], initialSelection: [9], doneBlock: {
                picker, values, indexes in
                let arrayRows = indexes as! NSArray
                self.onEmploymentStatus.setTitle(arrayRows[0] as? String, for: UIControlState())
                
                
                return
            }, cancel: { ActionMultipleStringCancelBlock in return }, origin: onEmploymentStatus)
    }
    @IBAction func onMaritalStatus(_ sender: AnyObject) {
        ActionSheetMultipleStringPicker.show(withTitle: "Marital Status", rows: [
            ["Single,never married","Married or domestic partnership","Widowed", "Divorced", "separated"],
            
            ], initialSelection: [5], doneBlock: {
                picker, values, indexes in
                let arrayRows = indexes as! NSArray
                self.onMaritalStatus.setTitle(arrayRows[0] as? String, for: UIControlState())
                
                
                return
            }, cancel: { ActionMultipleStringCancelBlock in return }, origin: onMaritalStatus)
    }
    
    
    @IBAction func onFamilyHistory(_ sender: AnyObject) {
        ActionSheetMultipleStringPicker.show(withTitle: "Family History", rows: [
            ["Yes","No","I don't know"],
            
            ], initialSelection: [3], doneBlock: {
                picker, values, indexes in
                let arrayRows = indexes as! NSArray
                self.onFamilyHistory.setTitle(arrayRows[0] as? String, for: UIControlState())
                
                
                return
            }, cancel: { ActionMultipleStringCancelBlock in return }, origin: onFamilyHistory)
    }
    
    @IBAction func onEducationStatus(_ sender: AnyObject) {
        ActionSheetMultipleStringPicker.show(withTitle: "Education History", rows: [
            ["No schooling completed", "Nursery school to 8th grade", "Some high school, no diploma", "High school graduate/Equiv", "Some college credit,no degree", "Trade/technical/vocational","Associate degree", "Bachelor’s degree", "Master’s degree","Professional degree","Doctorate degree"],
            ], initialSelection: [11], doneBlock: {
                picker, values, indexes in
                let arrayRows = indexes as! NSArray
                self.onEducationStatus.setTitle(arrayRows[0] as? String, for: UIControlState())
                return
            }, cancel: { ActionMultipleStringCancelBlock in return }, origin: onEducationStatus)
        
    }
    
    @IBAction func physicalActivityLevel(_ sender: Any) {
        ActionSheetMultipleStringPicker.show(withTitle: "Daily Physical Activity", rows: [
            ["Minimal physical activity", // (1.4)
                "Moderate physical activity", // (1.6)
                "Strenuous physical activity", // (1.8)
                "Elite or professional athlete"], // (2.0)
            ], initialSelection: [0], doneBlock: {
                picker, values, indexes in
                // Get the index in which user selected and mapped the pal value for calculating the calories.
                self.PAL = self.palMap[values![0] as! Int]
                let arrayRows = indexes as! NSArray
                self.onPhysicalActivity.setTitle(arrayRows[0] as? String, for: UIControlState())
                return
        }, cancel: { ActionMultipleStringCancelBlock in return }, origin: onPhysicalActivity)
    }
    
    @IBAction func onRace(_ sender: AnyObject) {
        ActionSheetMultipleStringPicker.show(withTitle: "Pick your race", rows: [
            ["White, non-Hispanic", "Hispanic, Latino, or Latin", "Black or African American", "Native American", "Asian/Pacific Islander", "Multiracial","other"],
            ], initialSelection: [6], doneBlock: {
                picker, values, indexes in
                let arrayRows = indexes as! NSArray
                self.raceButton.setTitle(arrayRows[0] as? String, for: UIControlState())
                return
            }, cancel: { ActionMultipleStringCancelBlock in return }, origin: raceButton)
    }
    
    @IBAction func onGender(_ sender: AnyObject) {
        ActionSheetMultipleStringPicker.show(withTitle: "Gender", rows: [
            ["Male","Female"],
            ], initialSelection: [2], doneBlock: {
                picker, values, indexes in
                let arrayRows = indexes as! NSArray
                self.onGender.setTitle(arrayRows[0] as? String, for: UIControlState())
                return
            }, cancel: { ActionMultipleStringCancelBlock in return }, origin: onGender)
    }
    
    func createWeight() {
        for i in 1...300 {
            weightNumbers.append(i)
        }
    }
    
    func createAge() {
        for i in 1...100 {
            ageNumbers.append(i)
        }
        
    }
    
    @IBAction func onHeight(_ sender: AnyObject) {
        ActionSheetMultipleStringPicker.show(withTitle: "Height", rows: [
            ["4'6", "4'7", "4'8", "4'9", "4'10", "4'11", "5'0", "5'1", "5'2", "5'3", "5'4", "5'5", "5'6", "5'7", "5'8", "5'9", "5'10", "5'11", "6'0", "6'1", "6'2", "6'3", "6'4", "6'5", "6'6"],
            ], initialSelection: [25], doneBlock: {
                picker, values, indexes in
                let arrayRows = indexes as! NSArray
                self.onHeight.setTitle(arrayRows[0] as? String, for: UIControlState())
                return
            }, cancel: { ActionMultipleStringCancelBlock in return }, origin: onHeight)
        
        
        
    }   //height
    
    @IBAction func onWeight(_ sender: AnyObject) {
        let alertController = UIAlertController(title: "Weight", message: "How would you like your weight recorded?", preferredStyle: .alert)
        let lbAction = UIAlertAction(title: "Pounds", style: .default, handler: { (action: UIAlertAction) -> Void in
            ActionSheetMultipleStringPicker.show(withTitle: "Pounds", rows: [
                self.weightNumbers,
                ], initialSelection: [150], doneBlock: {
                    picker, values, indexes in
                    self.metric = false;
                    let arrayRows = indexes as! NSArray
                    let result = arrayRows[0]
                    self.onWeight.setTitle((result as AnyObject).stringValue, for: UIControlState())
                    return
                }, cancel: { ActionMultipleStringCancelBlock in return }, origin: self.onWeight)
        })
        let kgAction = UIAlertAction(title: "Kilograms", style: .default, handler: { (action: UIAlertAction) -> Void in
            ActionSheetMultipleStringPicker.show(withTitle: "Kilograms", rows: [
                self.weightNumbers,
                ], initialSelection: [70], doneBlock: {
                    picker, values, indexes in
                    self.metric = true;
                    let arrayRows = indexes as! NSArray
                    let result = arrayRows[0]
                    self.onWeight.setTitle((result as AnyObject).stringValue, for: UIControlState())
                    return
                }, cancel: { ActionMultipleStringCancelBlock in return }, origin: self.onWeight)
        })
        alertController.addAction(lbAction)
        alertController.addAction(kgAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
   
    
    @IBAction func onAge(_ sender: AnyObject) {
        ActionSheetMultipleStringPicker.show(withTitle: "Age", rows: [
            ageNumbers,
            ], initialSelection: [35], doneBlock: {
                picker, values, indexes in
                let arrayRows = indexes as! NSArray
                let result = arrayRows[0]
                self.onAge.setTitle((result as AnyObject).stringValue, for: UIControlState())
                return
            }, cancel: { ActionMultipleStringCancelBlock in return }, origin: onAge)
    }
    @IBAction func saveProfile(_ sender: AnyObject) {
        let ageWritten: String = onAge.titleLabel!.text!
        let heightWritten: String = onHeight.titleLabel!.text!
        let weightWritten: String = onWeight.titleLabel!.text!
        let genderWritten: String = onGender.titleLabel!.text!
        let raceResponse = raceButton.titleLabel!.text!
        let educationResponse = onEducationStatus.titleLabel!.text!
        let familyResponse = onFamilyHistory.titleLabel!.text!
        let maritalResponse = onMaritalStatus.titleLabel!.text!
        let employmentResponse = onEmploymentStatus.titleLabel!.text!
        let palText = onPhysicalActivity.titleLabel!.text!

        let email = self.userDefaults.value(forKey: "email") as! String
        var arn = "NULL"
        if userDefaults.object(forKey: "endpointArn") != nil {
            arn = String(describing: userDefaults.object(forKey: "endpointArn")!)
        }
        var gender = -1
        if(genderWritten == "Male" || genderWritten == "MALE"){
            gender = 0
        }
        else if(genderWritten == "Female" || genderWritten == "FEMALE"){
             gender = 1
        }
        // Here we pass the PAL into the User constructer to pass the pal value.
        let userProfile = User(age: ageWritten, height: heightWritten, weight: weightWritten, gender: gender, pal: self.PAL, metric: self.metric)
        userDefaults.set(NSKeyedArchiver.archivedData(withRootObject: userProfile!), forKey: "user")
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        let jsonObject: [String: Any] = [
            "TableName":  "diaFitUsers" as AnyObject,
            "operation": "update" as AnyObject ,
            "Key": ["email": email],
            "UpdateExpression": "set age = :age, height = :height, weight = :weight, gender = :gender, firstTimeUser = :firstTimeUser, race = :race, education = :education, familyHistory = :familyHistory, marital = :marital, employment = :employment, arn = :arn, metric = :metric, physicalActivityLevel = :physicalActivityLevel",
            "ExpressionAttributeValues" :
                [
                    ":age" : ageWritten,
                    ":height" : heightWritten,
                    ":weight" : weightWritten,
                    ":gender" : genderWritten,
                    ":race" : raceResponse,
                    ":education" : educationResponse,
                    ":familyHistory" : familyResponse,
                    ":marital" : maritalResponse,
                    ":employment" : employmentResponse,
                    ":firstTimeUser" : "false",
                    ":arn" : arn,
                    ":metric": self.metric,
                    ":physicalActivityLevel": palText
            ],
            "ReturnValues": "UPDATED_NEW"
        ]
        let task = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonObject)
        task.continue(successBlock: { (task: AWSTask) -> Any? in
            if task.error != nil {
                print(task.error as Any)
            } else {
                if task.result != nil {
                    print("Posted at Profile!")
                    DispatchQueue.main.async {
                        let storyBoard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
                        let menu = storyBoard.instantiateViewController(withIdentifier: "mainMenuNav")
                        self.present(menu, animated: true, completion: nil)
                    }
                } else {
                    print("Exception: \(String(describing: task.exception))")
                }
            }
            return nil
        })
    }
 

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func getProfile(){
        let email = userDefaults.value(forKey: "email")!
        let lambdaInvoker = AWSLambdaInvoker.default()
        let jsonObject: [String: Any] = ["operation": "read" as AnyObject,
                                         "TableName": "diaFitUsers" as AnyObject,
                                         "Key":["email": email]];
        let task = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonObject);
        task.continue(successBlock: { (task: AWSTask) -> Any? in
            if task.error != nil {
                print("Error: ", task.error as Any)
            }
            if task.result != nil {
                do {
                    let json = task.result as! Dictionary<String, AnyObject>
                    let listofattributes = json["Item"] as! Dictionary<String, AnyObject>
                    if listofattributes["firstTimeUser"] as? Bool == true {
                        self.deviceType = self.defaults.integer(forKey: "device")
                        switch(self.deviceType){
                        case 0:
                            self.deviceManager.authorizeHealthKit(){
                                (result: Bool) in
                                if(result){ DispatchQueue.main.async {
                                    self.onGender.setTitle(self.deviceManager.healthKitGetGender(), for: UIControlState.normal)
                                    self.onAge.setTitle(self.deviceManager.healthKitGetAge(), for: UIControlState.normal)
                                    DispatchQueue.main.async {
                                        self.deviceManager.healthKitGetWeight() {
                                            (result:String) in
                                            
                                            self.onWeight.setTitle(result, for: UIControlState.normal)
                                        }
                                    }
                                    DispatchQueue.main.async {
                                        self.deviceManager.healthKitGetHeight(){
                                            (result:String) in
                                            self.onHeight.setTitle(result, for: UIControlState.normal)
                                        }
                                    }
                                    }
                                }
                            }
                            
                        case 1:
                            self.deviceManager.getUserProfile({ (result) in
                                print("RESULT \(result)")
                                if(result){
                                    DispatchQueue.main.async {
                                        self.onGender.setTitle(self.deviceManager.getFitBitGender(), for: UIControlState.normal)
                                        self.onAge.setTitle(self.deviceManager.getFitBitAge(), for: UIControlState.normal)
                                        self.onHeight.setTitle(self.deviceManager.getFitBitHeight(), for: UIControlState.normal)
                                        self.onWeight.setTitle(self.deviceManager.getFitBitWeight(), for: UIControlState.normal)
                                        self.defaults.synchronize()
                                        
                                    }
                                }
                            })
                        default:
                            print("Error: Profile default case")
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.onAge.setTitle(listofattributes["age"] as? String, for: UIControlState.normal)
                            self.onWeight.setTitle(listofattributes["weight"] as? String, for: UIControlState.normal)
                            self.onGender.setTitle(listofattributes["gender"] as? String, for:UIControlState.normal)
                            self.onHeight.setTitle(listofattributes["height"] as? String, for: UIControlState.normal)
                            self.raceButton.setTitle(listofattributes["race"] as? String, for: UIControlState.normal)
                            self.onEducationStatus.setTitle(listofattributes["education"] as? String, for: UIControlState.normal)
                            self.onEmploymentStatus.setTitle(listofattributes["employment"] as? String, for: UIControlState.normal)
                            self.onMaritalStatus.setTitle(listofattributes["marital"] as? String, for: UIControlState.normal)
                            self.onFamilyHistory.setTitle(listofattributes["familyHistory"] as? String, for: UIControlState.normal)
                            self.onPhysicalActivity.setTitle(listofattributes["physicalActivityLevel"] as? String, for: UIControlState.normal)
                            if let metric = listofattributes["metric"] {
                                self.metric = (metric as? Bool)!
                            }
                        }
                    }
                }
                
            }
            return nil
        })
    }
    
    @IBAction func onSignOut(_ sender: AnyObject) {
        //clear NSUserdefaults
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
        print("User Signed out")
                defaults.removeObject(forKey: "email")
                defaults.removeObject(forKey: "rememberMe")
                defaults.removeObject(forKey: "loginFirstTime")
        defaults.removeObject(forKey: "fitbitAccess")
        defaults.synchronize()
        let storyBoard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
        let menu = storyBoard.instantiateViewController(withIdentifier: "loginView")
        present(menu, animated: true, completion: nil)
    }


}

