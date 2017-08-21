//
//  NDBDetailViewController.swift
//  diaFit
//
//  Created by Liang,Franky Z on 4/7/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//


//post food portion VC

import UIKit
import AWSCore
import AWSLambda


class NDBDetailViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var nameLabel: UILabel!
   // @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var servingTextField: UITextField!
    @IBOutlet weak var numOfServingTextField: UITextField!
    let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
    var dataTask: URLSessionDataTask?
    var food: Food!
    var currentDate:String = ""
    var nutritionResults = [Nutrition]()
    //var measures = [Serving]()
    var servingPickerView = UIPickerView()
    var userInputServing: Float!
    var userPickedServing: String!
    let userDefaults = UserDefaults.standard

    //Set initial nutrition values to 0
    var energyKCal208: Float = 0.0
    var energyKJ268: Float = 0.0
    var proteinG203: Float = 0.0
    var totalLipidG204: Float = 0.0
    var carbsG205: Float = 0.0
    var dietaryFiberG291: Float = 0.0
    var totalSugarsG268: Float = 0.0
    var calciumMg301: Float = 0
    var ironMg303: Float = 0
    var potassiumMg306: Float = 0
    var sodiumMg307: Float = 0
    var vitAIU318: Float = 0
    var vitARAE320: Float = 0
    var vitCMg401: Float = 0
    var vitB6Mg415: Float = 0
    var cholesterolMg601: Float = 0
    var transFatG605: Float = 0
    var saturatedFatG606: Float = 0
    
    //Make variables for total nutrition values of the current day? -> make an object with NSDate() <-- the current date.
    //How to make data persist for whole day??
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
    var totalCholesterol = 0
    var totalTransFat = 0
    var totalSaturatedFat = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        nameLabel.text = food.name
        DispatchQueue.main.async {
            self.networkRequest()
        }
        servingPickerView.delegate = self
        servingPickerView.dataSource = self
        servingTextField.inputView = servingPickerView
    }
    override var shouldAutorotate : Bool {
        return false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }

    override func viewDidAppear(_ animated: Bool) {
        checkConnection()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateNutrients(_ data: Data?) {
        nutritionResults.removeAll()
        do {
            if let dataInput: Data = data, let jsonParsed = try? JSONSerialization.jsonObject(with: dataInput, options:JSONSerialization.ReadingOptions(rawValue:0)) {
                if let dictLevel1 = jsonParsed as? [String: Any] {
                    if let dictLevel2 = dictLevel1["report"] as? [String: Any] {
                        if let dictLevel3 = dictLevel2["food"] as? [String: Any] {
                            if let arrayLevel4 = dictLevel3["nutrients"] as? NSArray {
                                for nutrientArray in arrayLevel4 {
                                    if let nutrientJson = nutrientArray as? [String: Any]{
                                        let nutrientId = nutrientJson["nutrient_id"] as? String
                                        let nutrientName = nutrientJson["name"] as? String
                                        let value = nutrientJson["value"] as? String
                                        let unit = nutrientJson["unit"] as? String
                                        var measures = [Serving]()
                                        if let meassure = nutrientJson["measures"] as? NSArray {
                                            for setMeasurement in meassure {
                                                let meassure = setMeasurement as? [String: Any]
                                                let label = meassure?["label"] as? String
                                                let eqv = meassure?["eqv"] as? Double
                                                let qty = meassure?["qty"] as? Double
                                                let value = meassure?["value"] as? String
                                                let qtyLabel = String(qty!) + " " + label!
                                                measures.append(Serving(label: qtyLabel, eqv: eqv!, qty: qty!, value: value!))
                                            }
                                        }
                                        else {
                                            print("Error at NBD: Measures")
                                        }
                                        nutritionResults.append(Nutrition(measures: measures, nutrientId: nutrientId!, nutrientName: nutrientName!, unit: unit!, value: value!))
                                    }
                                }
                            }
                            else {
                                print("Error at NBD: nutrients")
                            }
                        }
                        else {
                            print("Error at NBD: food")
                        }
                    }
                    else {
                        print("Error at NBD: report")
                    }
                }
                else {
                    print("Error at NBD: dictLevel1")
                }
            }
            else {
                print("Error at NBD: JSONSerialization")
            }
            DispatchQueue.main.async {
                self.servingTextField.text = self.nutritionResults[0].measures[0].label
            }
        }
        servingPickerView.reloadAllComponents()
    }

    func networkRequest() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let apiKey = "1ADB1YidG74qvv8NbqPxUVOcZjyRZhtpFURGEyIE"
        let queryNDBNO = food.ndbno
        let url = URL(string:"https://api.nal.usda.gov/ndb/reports/?ndbno=\(queryNDBNO)&type=b&format=json&api_key=\(apiKey)")
        dataTask = defaultSession.dataTask(with: url!, completionHandler: {
            data, response, error in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if let error = error {
                print(error.localizedDescription)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    self.updateNutrients(data)
                }
            }
        }) 
        dataTask?.resume()
    }
    
 

    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return nutritionResults[0].measures[row].label
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return nutritionResults[0].measures.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            self.servingTextField.text = nutritionResults[0].measures[row].label
    }

    @IBAction func onPost(_ sender: AnyObject) {
        if numOfServingTextField.text!.isEmpty == true || servingTextField.text!.isEmpty == true {
            let alertController = UIAlertController(title: "Error", message: "Enter a value for serving size!", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                alertController.dismiss(animated: true, completion: nil)
            })
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: nil)
        } else {
            calculateNutrition()
            lambdaInvoker()
            self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)

        }

        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "postSegue") {
            let destinationNavigationController = segue.destination as! UINavigationController
            let targetController = destinationNavigationController.topViewController as! FoodLogViewController
            targetController.segueDateFromNDB = currentDate
        }
        

    }
    
    
    func calculateNutrition() {
        for nutrient in nutritionResults {
            userPickedServing = servingTextField.text!
            userInputServing = Float(numOfServingTextField.text!)
            let currNutrient = nutrient.nutrientId
            switch currNutrient {
            case "208":
                //this is energy in kcal
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        energyKCal208 = floatServingValue * Float(userInputServing)
                    }
                }
            case "268":
                //this is energy in kJ
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        energyKJ268 = floatServingValue * Float(userInputServing)
                    }
                }
            case "203":
                //this is protein in g
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        proteinG203 = floatServingValue * Float(userInputServing)
                    }
                }
            case "204":
                //this is total lipids in g
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        totalLipidG204 = floatServingValue * Float(userInputServing)
                    }
                }
            case "205":
                //this is carbs b difference in g
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        carbsG205 = floatServingValue * Float(userInputServing)
                    }
                }
            case "291":
                //this is total dietary fiber in g
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        dietaryFiberG291 = floatServingValue * Float(userInputServing)
                    }
                }
            case "269":
                //this is total sugars in g
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        totalSugarsG268 = floatServingValue * Float(userInputServing)
                    }
                }
            case "301":
                //this is calcium in mg
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        calciumMg301 = floatServingValue * Float(userInputServing)
                    }
                }
            case "303":
                //this is iron in mg
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        ironMg303 = floatServingValue * Float(userInputServing)
                    }
                }
            case "306":
                //this is potassium in mg
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        potassiumMg306 = floatServingValue * Float(userInputServing)
                    }
                }
            case "307":
                //this is sodium in mg
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        sodiumMg307 = floatServingValue * Float(userInputServing)
                    }
                }
            case "318":
                //this is vitamin A, IU
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        vitAIU318 = floatServingValue * Float(userInputServing)
                    }
                }
            case "320":
                //this is vitamin A, RAE
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        vitARAE320 = floatServingValue * Float(userInputServing)
                    }
                }
            case "401":
                //this is vit c in mg
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        vitCMg401 = floatServingValue * Float(userInputServing)
                    }
                }
            case "415":
                //this is vitamin B6 in mg
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        vitB6Mg415 = floatServingValue * Float(userInputServing)
                    }
                }
            case "601":
                //this is cholesterol in mg
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        cholesterolMg601 = floatServingValue * Float(userInputServing)
                    }
                }
            case "605":
                //this is trans fats in g
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        transFatG605 = floatServingValue * Float(userInputServing)
                    }
                }
            case "606":
                //this is saturated fats in g
                for serving in nutrient.measures {
                    if (userPickedServing == serving.label) {
                        //calculate the nutrition
                        let servingNSString = serving.value as NSString
                        let floatServingValue = servingNSString.floatValue
                        saturatedFatG606 = floatServingValue * Float(userInputServing)
                    }
                }
            default:
                print("Default case")
            }
        }
    }
    
    func lambdaInvoker() {
        let email = self.userDefaults.value(forKey: "email") as! String
        let lambdaInvoker = AWSLambdaInvoker.default()
        var food_nutrient = [String:AnyObject]()
        food_nutrient = [":food_name" : food.name as AnyObject,
                         ":user_picked_serving": userPickedServing as AnyObject,
                         ":user_input_serving": userInputServing as AnyObject,
                         ":energyKJ": energyKJ268 as AnyObject,
                         ":energyKCal": energyKCal208 as AnyObject,
                         ":protein": proteinG203 as AnyObject,
                         ":lipids": totalLipidG204 as AnyObject,
                         ":carbohydrates": carbsG205 as AnyObject,
                         ":dietaryFiber": dietaryFiberG291 as AnyObject,
                         ":totalSugars": totalSugarsG268 as AnyObject,
                         ":cholesterol": cholesterolMg601 as AnyObject,
                         ":transFat": transFatG605 as AnyObject,
                         ":saturated_fat": saturatedFatG606 as AnyObject,
                         ":date": currentDate as AnyObject]
        // TODO
        //        ":calcium": calciumMg301 as AnyObject,
        //        ":iron": ironMg303 as AnyObject,
        //        ":potassium": potassiumMg306 as AnyObject,
        //        ":sodium": sodiumMg307 as AnyObject,
        //        ":vitAIU": vitAIU318 as AnyObject,
        //        ":vitARAE": vitARAE320 as AnyObject,
        //        ":vitC": vitCMg401 as AnyObject,
        //        ":vitB6": vitB6Mg415 as AnyObject,
        let jsonObject: [String: AnyObject] = [
            "TableName":  "diaFitNutrition" as AnyObject,
            "operation": "update" as AnyObject,
            "Key": ["email": email] as AnyObject,
            "UpdateExpression": "set #date = :food_nutrient" as AnyObject,
            "ExpressionAttributeNames": [
                "#date": currentDate
                
            ] as AnyObject,
            "ExpressionAttributeValues": [
                ":food_nutrient": food_nutrient
            ] as AnyObject,
            "ReturnValues": "UPDATED_NEW" as AnyObject
        ]
        let task = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonObject)
        print("GOT HERE")
       task.continue(successBlock: { (task: AWSTask) -> Any? in
            if task.error != nil {
                print(task.error as Any)
            } else {
                if task.result != nil {
                    print("Posted! At NDB")
                } else {
                    print("Exception: \(String(describing: task.exception))")
                }
            }
            return nil
        })
         print("GOT HERE")
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let inverseSet = CharacterSet(charactersIn:"0123456789.").inverted
        let components = string.components(separatedBy: inverseSet)
        let filtered = components.joined(separator: "")
        return string == filtered
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
