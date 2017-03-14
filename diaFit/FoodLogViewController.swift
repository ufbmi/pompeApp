//
//  FoodLogViewController.swift
//  diaFit
//
//  Created by Liang,Franky Z on 5/24/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit
import AWSLambda
import AWSCore
import SwiftyJSON
import HealthKit
import OAuthSwift
import CorePlot




class FoodLogViewController: ChildViewController, UITableViewDataSource, UITableViewDelegate, PiechartDelegate {
    
      var currentDate: String = ""
    @IBOutlet var myTableView: UITableView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var caloriesConsumedLabel: UILabel!
    @IBOutlet weak var totalProteinLabel: UILabel!
    @IBOutlet weak var totalLipidsLabel: UILabel!
    @IBOutlet weak var totalCarbsLabel: UILabel!
    @IBOutlet weak var totalSugarsLabel: UILabel!
    @IBOutlet weak var totalFibersLabel: UILabel!
    @IBOutlet weak var caloriesBurnedLabel: UILabel!
    @IBOutlet weak var remainingLabel: UILabel!
    
    @IBOutlet weak var percentageCarb: UILabel!

    @IBOutlet weak var percentageFat: UILabel!
    
    @IBOutlet weak var percentageProtein: UILabel!
    var refreshControl: UIRefreshControl!
    var totalEnergyKCal = 0
    var totalEnergyKJ = 0
    var totalProtein = 0
    var totalLipids = 0
    var totalCarbs = 0
    var totalDietaryFiber = 0
    var totalSugars = 0
    var totalCalcium = 0
    var totalIron = 0
    var totalPotassium = 0
    var totalSodium = 0
    var totalVitAIU = 0
    var totalVitARAE = 0
    var totalVitC = 0
    var totalVitB6 = 0
    var totalCholesterol = 0
    var totalTransFat = 0
    var totalSaturatedFat = 0
    var dateAddingUnit = 0
    var caloriesBurned = 0
    var segueDate1 = ""
    var segueDate2 = ""
    var currentDateWithTime = ""
    // Make returnedFood model
    var currentFoods = [ReturnedFood]()
    var segueDateFromNDB = ""
    let healthManager:HealthManager = HealthManager()
    let userDefaults = UserDefaults.standard
    let deviceManager:DeviceManager = DeviceManager()
    var messageFrame = UIView()
    var activityIndicator = UIActivityIndicatorView()
    
    
    @IBOutlet weak var percentageLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.userDefaults.setValue(1, forKey: "device");
        tableView.delegate = self
        tableView.dataSource = self
        refreshControl  = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(FoodLogViewController.onRefresh), for: UIControlEvents.valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
        print("GETTOFOODLOGVIEWCONTROLLER")
        print(userDefaults.value(forKey: "fitbitAccess"))
    }
    
    
    
    func drawPieChart( _ Carbs: Int, Fats: Int, Proteins: Int) {
        var views: [String: UIView] = [:]
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        var carbs = Piechart.Slice()
        
        
        if Carbs == 0 {
            carbs.value = 3
            carbs.color = UIColor.magenta
            carbs.text = "Carbohydrates"
        } else {		
            carbs.value = CGFloat(Carbs)
            carbs.color = UIColor.magenta
            carbs.text = "Carbohydrates"
        }
       
        var proteins = Piechart.Slice()
        if Proteins == 0 {
            proteins.value = 3
            proteins.color = UIColor.blue
            proteins.text = "Proteins"
        } else {
            proteins.value = CGFloat(Proteins)
            proteins.color = UIColor.blue
            proteins.text = "Proteins"
        }
    
        var fats = Piechart.Slice()
        if Fats == 0 {
            fats.value = 3
            fats.color = UIColor.orange
            fats.text = String("Fats")
        } else {
            fats.value = CGFloat(Fats)
            fats.color = UIColor.orange
            fats.text = "Fats"
        }
        
        let piechart = Piechart()
        piechart.delegate = self
        piechart.title = "Macronutrients"
        piechart.activeSlice = 2
        piechart.slices = [carbs, proteins, fats]
        let fatsValue = Int(fats.value), carbsValue = Int(carbs.value), proteinsValue = Int(proteins.value)
        let totalValue = fatsValue + carbsValue + proteinsValue
        let proteinPercent = Int((proteinsValue/totalValue) * 100)
        let carbsPercent = Int((carbsValue/totalValue) * 100)
        let fatsPercent = Int((fatsValue/totalValue) * 100)
        DispatchQueue.main.async {
            self.percentageProtein.text = String(proteinPercent) + "%" + " Proteins"
            self.percentageFat.text = String(fatsPercent) + "%" + " Fats"
            self.percentageCarb.text = String(carbsPercent) + "%" + " Carbs"
        }
        
        piechart.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(piechart)
        views["piechart"] = piechart
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[piechart]-125-|", options: [], metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-170-[piechart(==170)]", options: [], metrics: nil, views: views))
    }
    
    func setSubtitle(_ total: CGFloat, slice: Piechart.Slice) -> String {
        return "\(Int(slice.value / total * 100))% " + slice.text
    }
    
    func setInfo(_ total: CGFloat, slice: Piechart.Slice) -> String {
        return "\(Int(slice.value))/\(Int(total))"
   
    }

    func progressBarDisplayer(_ indicator:Bool ) {
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
      
        messageFrame = UIView(frame: CGRect(x: 0, y: 0 , width: screenWidth, height: screenHeight))
        messageFrame.backgroundColor = UIColor(white: 1, alpha: 1)

        if indicator {
            activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
            activityIndicator.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
            activityIndicator.startAnimating()
            messageFrame.addSubview(activityIndicator)
        }
        view.addSubview(messageFrame)
    }
    
    override var shouldAutorotate : Bool {
        return false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        checkConnection()
        self.myTableView.reloadData()
        progressBar.transform = CGAffineTransform(scaleX: 1, y: 5)
        
        
        DispatchQueue.main.async {
            self.progressBarDisplayer( true)
            DispatchQueue.main.async {
                self.lambdaInvoker()
            }
        }


    }
    
    @IBAction func backButton(_ sender: AnyObject) {
        let storyBoard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
        let menu = storyBoard.instantiateViewController(withIdentifier: "mainMenuNav")
        present(menu, animated: true, completion: nil)
        
    }
    
    func updateProgressBar() {
   
        let caloriesConsumed = Float(self.caloriesConsumedLabel.text!)!
        if self.remainingLabel.text == "N/A" {
            //hide progress bar
            self.percentageLabel.isHidden = true
            progressBar.isHidden = true
        } else {
            let caloriesRemained = Float(self.remainingLabel.text!)!
            if caloriesRemained  < 0 {
                //set progress bar to red
                progressBar.setProgress(1.0, animated: true)
                progressBar.progressTintColor = UIColor.red
                //set percentage label
                let actualRemain = caloriesConsumed + caloriesRemained
                let exceededPercentage = Int(((-caloriesRemained)/actualRemain)*100 + (100))
                DispatchQueue.main.async {
                    self.percentageLabel.text = String(exceededPercentage) + "%"
                }
                
            } else if caloriesRemained >= 0 {
                progressBar.progressTintColor = UIColor.gray
                let progressValue = caloriesConsumed / (caloriesRemained + caloriesConsumed)
                let percentageValue = Int(progressValue * 100)
                DispatchQueue.main.async {
                    self.progressBar.setProgress(progressValue, animated: true)
                    self.percentageLabel.text = String(percentageValue) + "%"
                }
            }
        }
        
           }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentFoods.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoodLogCell", for: indexPath) as! FoodLogCell
        let food = currentFoods[(indexPath as NSIndexPath).row]
        cell.foodNameLabel.text = food.foodName
        cell.numberServingLabel.text = food.inputServing
        self.tableView.flashScrollIndicators()
        return cell
        
    }
    
     func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
     func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let email = self.userDefaults.value(forKey: "email") as! String
        currentDate = currentFoods[(indexPath as NSIndexPath).row].date
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            // handle delete (by removing the data from your AWS)
            let lambdaInvoker = AWSLambdaInvoker.default()
            let jsonObject: [String: AnyObject] = [
                "TableName":  "diaFitNutrition" as AnyObject,
                "operation": "delete" as AnyObject ,
                //import email from other view controller -> public variable
                "Key": ["email": email] as AnyObject,
                "UpdateExpression": "remove #date" as AnyObject,
                "ExpressionAttributeNames": [
                    "#date": currentDate,
                    ] as AnyObject,
                "ReturnValues": "NONE" as AnyObject
            ]
            let task = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonObject)
             task.continue(successBlock: { (task: AWSTask) -> Any? in
                if task.error != nil {
                    print(task.error)
                } else {
                    //delete the table view row
                    DispatchQueue.main.async {
                        self.progressBarDisplayer( true)
                        DispatchQueue.main.async {
                            self.lambdaInvoker()
                            self.currentFoods.remove(at: indexPath.row)
                            tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                    }
                }
                return nil
            })
        }
    }
  
    func lambdaInvoker () {
        self.view.backgroundColor = UIColor.white
        let email = self.userDefaults.value(forKey: "email") as! String
        //reset displayed values to 0
        self.totalProtein = 0
        self.totalLipids = 0
        self.totalCarbs = 0
        self.totalSugars = 0
        self.totalDietaryFiber = 0
        self.totalEnergyKCal = 0
        self.caloriesBurned = 0
        let calendar = Calendar.current
        var selectedDate = (calendar as NSCalendar).date(byAdding: .day, value: (self.dateAddingUnit), to: Date(), options: [])
        
        if segueDateFromNDB != "" {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/M/yyyy, H:mm:ss"
            let segueDate = dateFormatter.date(from: segueDateFromNDB)
            let calendar: Calendar = Calendar.current
            let date1 = calendar.startOfDay(for: segueDate!)
            let date2 = calendar.startOfDay(for: selectedDate!)
            let flags = NSCalendar.Unit.day
            let components = (calendar as NSCalendar).components(flags, from: date2, to: date1, options: [])
            dateAddingUnit = components.day!
            selectedDate = segueDate
            segueDateFromNDB = ""
            
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/dd/yyyy"
        let dateFormatterForAWS = DateFormatter()
        dateFormatterForAWS.dateFormat = "dd/M/yyyy, H:mm:ss"
        let currentDate = dateFormatter.string(from: selectedDate!)
        self.currentDateWithTime = dateFormatterForAWS.string(from: selectedDate!)
        DispatchQueue.main.async {
            self.segueDate2 = self.currentDateWithTime
            self.dateLabel.text = currentDate
        }
        let lambdaInvoker = AWSLambdaInvoker.default()
        let jsonObject: [String: AnyObject] = [
            "operation": "read" as AnyObject,
            "TableName": "diaFitNutrition" as AnyObject,
            "Key": ["email": email] as AnyObject
        ]
        let task = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonObject)
        task.continue(successBlock: { (task: AWSTask) -> Any? in
            if task.error != nil {
                print(task.error)
            } else {
                if task.result != nil {
                    var nutritionJSON =  JSON(task.result!)
                    var foodFromAWS = [ReturnedFood]()
                    for item in nutritionJSON["Item"] {
                        if item.0 != "email" {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "M/dd/yyyy"
                            let dateString = String(item.0)
                            let currentDateFromAWS = dateFormatterForAWS.date(from: dateString!)
                            let compareDateString = dateFormatter.string(from: currentDateFromAWS!)
                            if compareDateString == currentDate {
                                DispatchQueue.main.async {
                                    self.totalCalcium += item.1[":calcium"].intValue
                                    let currFoodTotalCalcium = String(item.1[":calcium"].intValue)
                                    
                                    self.totalCarbs += item.1[":carbohydrates"].intValue
                                    let currFoodTotalCarbs = String(item.1[":carbohydrates"].intValue)
                                    
                                    self.totalCholesterol += item.1[":cholesterol"].intValue
                                    let currFoodTotalCholesterol = String(item.1[":cholesterol"].intValue)
                                    
                                    self.totalDietaryFiber += item.1[":dietaryFiber"].intValue
                                    let currFoodTotalDietaryFiber = String(item.1[":dietaryFiber"].intValue)
                                    
                                    self.totalEnergyKCal += item.1[":energyKCal"].intValue
                                    let currFoodTotalKCal = String(item.1[":energyKCal"].intValue)
                                    
                                    self.totalEnergyKJ += item.1[":energyKJ"].intValue
                                    let currFoodTotalKJ = String(item.1[":energyKJ"].intValue)
                                    
                                    self.totalIron += item.1[":iron"].intValue
                                    let currFoodTotalIron = String(item.1[":iron"].intValue)
                                    
                                    self.totalLipids += item.1[":lipids"].intValue
                                    let currFoodTotalLipids = String(item.1[":lipids"].intValue)
                                    
                                    self.totalPotassium += item.1[":potassium"].intValue
                                    let currFoodTotalPotassium = String(item.1[":potassium"].intValue)
                                    
                                    self.totalProtein += item.1[":protein"].intValue
                                    let currFoodTotalProtein = String(item.1[":protein"].intValue)
                                    
                                    self.totalSaturatedFat += item.1[":saturated_fat"].intValue
                                    let currFoodTotalSaturatedFat = String(item.1[":saturated_fat"].intValue)
                                    
                                    self.totalSodium += item.1[":sodium"].intValue
                                    let currFoodTotalSodium = String(item.1[":sodium"].intValue)
                                    
                                    self.totalSugars += item.1[":totalSugars"].intValue
                                    let currFoodTotalSugars = String(item.1[":totalSugars"].intValue)
                                    
                                    self.totalTransFat += item.1[":transFat"].intValue
                                    let currFoodTotalTransFat = String(item.1[":transFat"].intValue)
                                    
                                    self.totalVitAIU += item.1[":vitAIU"].intValue
                                    let currFoodTotalVitAIU = String(item.1[":vitAIU"].intValue)
                                    
                                    self.totalVitARAE += item.1[":vitARAE"].intValue
                                    let currFoodTotalVitARAE = String(item.1[":vitARAE"].intValue)
                                    
                                    self.totalVitC += item.1["vitC"].intValue
                                    let currFoodTotalVitC = String(item.1["vitC"].intValue)
                                    
                                    self.totalVitB6 += item.1["vitB6"].intValue
                                    let currFoodTotalVitB6 = String(item.1["vitB6"].intValue)
                                    
                                    let currFoodName = item.1[":food_name"].stringValue
                                    let currFoodNDBNO = String(item.1[":food_ndbno"].intValue)
                                    let currFoodDate = item.1[":date"].stringValue
                                    let userInputServing = String(item.1[":user_input_serving"].intValue)

                                    let userPickedServing = item.1[":user_picked_serving"].stringValue
                                    foodFromAWS.append(ReturnedFood(foodName: currFoodName, foodNDBNO: currFoodNDBNO, pickedServing: userPickedServing, inputServing: userInputServing, energyKJ: currFoodTotalKJ, energyKCal: currFoodTotalKCal, protein: currFoodTotalProtein, lipids: currFoodTotalLipids, carbohydrates: currFoodTotalCarbs, dietaryFiber: currFoodTotalDietaryFiber, totalSugars: currFoodTotalSugars, calcium: currFoodTotalCalcium, iron: currFoodTotalIron, potassium: currFoodTotalPotassium, sodium: currFoodTotalSodium, vitAIU: currFoodTotalVitAIU, vitARAE: currFoodTotalVitARAE, vitC: currFoodTotalVitC, vitB6: currFoodTotalVitB6, cholesterol: currFoodTotalCholesterol, transFat: currFoodTotalTransFat, saturatedFat: currFoodTotalSaturatedFat, date: currFoodDate))
                                }
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        self.currentFoods = foodFromAWS
                        self.tableView.reloadData()
                        self.myTableView.reloadData()
                        self.tableView.setContentOffset(CGPoint.zero, animated: false)
                        self.caloriesConsumedLabel.text = String(self.totalEnergyKCal)
                        self.totalProteinLabel.text = String(self.totalProtein) + "g"
                        self.totalLipidsLabel.text = String(self.totalLipids) + "g"
                        self.totalCarbsLabel.text = String(self.totalCarbs) + "g"
                        self.totalSugarsLabel.text = String(self.totalSugars) + "g"
                        self.totalFibersLabel.text = String(self.totalDietaryFiber) + "g"
                            self.updateCalories()
                        DispatchQueue.main.async {
                        self.messageFrame.removeFromSuperview()
                            self.drawPieChart(self.totalCarbs,Fats: self.totalLipids,Proteins: self.totalProtein)
                        }
                    }
                } else {
                    print("Exception: \(task.exception)")
                }
                
            }
            return nil
        })
    }
    
    func updateCalories(){
        let device = self.userDefaults.value(forKey: "device") as! Int
        let data = userDefaults.object(forKey: "user") as? Data
        let unarc = NSKeyedUnarchiver(forReadingWith: data!)
        unarc.setClass(User.self, forClassName: "User")
        let user:User = unarc.decodeObject(forKey: "root") as! User
        let formatter  = DateFormatter()
        let calendar = Calendar.current
        //FITBIT
        if( device == 1){
            //
            formatter.dateFormat = "yyyy-MM-dd"
            let date = formatter.string(from: (calendar as NSCalendar).date(byAdding: [.day],value: self.dateAddingUnit,to: Date(),options: [])!)
            self.deviceManager.getFitBitSteps(date){(result: Int) in
                let caloriesBurned = Double(result) * 0.044
                var remaining = ""
                if(!user.completeData){
                    remaining = "N/A"
                }
                else {
                    remaining = String(Int(user.getCalories() +  caloriesBurned - Double(self.caloriesConsumedLabel.text!)!))
                }
                DispatchQueue.main.async {
                    self.caloriesBurnedLabel.text = String(Int(caloriesBurned))
                    self.remainingLabel.text = remaining
                    self.updateProgressBar()
                }
            }
        }
        else if (device == 0){
            //IOS
            let stepSample = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
            formatter.dateStyle = DateFormatter.Style.full
            var remaining = ""
            self.healthManager.getSteps(stepSample!) { (stepCounts, error) -> Void in
                if( error != nil ) {
                    print("Error: \(error)")
                    return
                }
                var steps = 0
                if(stepCounts.isEmpty) {
                    if(!user.completeData){
                        remaining = "N/A"
                    }
                    else {
                        remaining = String(Int(user.getCalories()) +  0 - Int(self.caloriesConsumedLabel.text!)!)
                    }
                    DispatchQueue.main.async {
                        self.remainingLabel.text = remaining
                        self.updateProgressBar()
                    }
                }
                else {
                    for stepCount in stepCounts {
                        let tempStepCount = stepCount as? HKQuantitySample
                        let startDate = formatter.string(from: (tempStepCount?.startDate)!)
                        if(startDate == formatter.string(from: (calendar as NSCalendar).date(byAdding: [.day],value: self.dateAddingUnit,to: Date(),options: [])!)) {
                            steps += Int(tempStepCount!.quantity.doubleValue(for: HKUnit.count()))
                            let caloriesBurned = Double(steps) * 0.044
                            if(!user.completeData){
                                remaining = "N/A"
                            }
                            else {
                                remaining = String(Int(user.getCalories() +  caloriesBurned - Double(self.caloriesConsumedLabel.text!)!))
                            }
                            DispatchQueue.main.async {
                                self.caloriesBurnedLabel.text = String(Int(caloriesBurned))
                                self.remainingLabel.text = remaining
                                self.updateProgressBar()
                            }
                        }
                        
                    }
                }
            }
            
        }
    }
    
    @IBAction func onAdd(_ sender: AnyObject) {
        segueDate1 = dateLabel.text!
        self.performSegue(withIdentifier: "sendData1", sender: sender)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "sendData1") {
            let destinationNavigationController = segue.destination as! UINavigationController
            let targetController = destinationNavigationController.topViewController as! ViewController
            //Pass dateLabel.text to dateTitle in ViewController
            targetController.dateTitle = segueDate1
            targetController.currentDate = segueDate2
        }
    }
    
    @IBAction func onPrevious(_ sender: AnyObject) {
        dateAddingUnit += (-1)
        lambdaInvoker()
        
    }
    
    @IBAction func onNext(_ sender: AnyObject) {
        dateAddingUnit += 1
        lambdaInvoker()
        
        
    }
    
    func onRefresh(){
        lambdaInvoker()
        self.tableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

