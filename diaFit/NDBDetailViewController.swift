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


class NDBDetailViewController: UIViewController{
    
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
    var proteinG203: Float = 0.0
    var totalLipidG204: Float = 0.0
    var carbsG205: Float = 0.0
    
    //Make variables for total nutrition values of the current day? -> make an object with NSDate() <-- the current date.
    var totalEnergyKCal = 0
    var totalProtein = 0
    var totalLipids = 0
    var totalCarbs = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        nameLabel.text = food.name + " " + food.brandName
        nameLabel.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 26)
        servingTextField.font = UIFont(name: "AppleSDGothicNeo-Medium", size: 21)
        DispatchQueue.main.async {
            self.networkRequest()
        }
        

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
                print(jsonParsed)
                if let nutrientJson = jsonParsed as? [String: Any] {
                    print("\(nutrientJson)nutrientJson")
                    let foodName = (nutrientJson["item_name"] as? String)! + " " + (nutrientJson["brand_name"] as? String)!
                    let energyKCal = nutrientJson["nf_calories"] as? Double ?? 0
                    let protein = nutrientJson["nf_protein"] as? Double ?? 0
                    let lipids = nutrientJson["nf_total_fat"] as? Double ?? 0
                    let carbohydrates = nutrientJson["nf_total_carbohydrate"] as? Double ?? 0
                    var measures = [Serving]()
                    let label = nutrientJson["nf_serving_size_unit"] as? String
                    let qty = nutrientJson["nf_serving_size_qty"] as? Double ?? 0
                    let qtyLabel = String(qty) + " " + label!
                    measures.append(Serving(label: qtyLabel,  qty: qty))
                    
                    nutritionResults.append(Nutrition(measures: measures, foodName: foodName, energyKCal: energyKCal, protein: protein, lipids: lipids, carbohydrates:carbohydrates))
                    
                }
                else {
                    print("Error at NBD: nutrientJson")
                }
            }
            else {
                print("Error at NBD: JSONSerialization")
            }
            DispatchQueue.main.async {
                self.servingTextField.text = "Serving: "+self.nutritionResults[0].measures[0].label
            }
        }
    }
    
    func networkRequest() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let id = "ff35e5bb"
        let apiKey = "ca6076d34d452bfb106b7d179b31d420"
        let itemId = food.ndbno//item_id
        print("queryNDBNO\(itemId)")
        let url = URL(string:"https://api.nutritionix.com/v1_1/item?id=\(itemId)&appId=\(id)&appKey=\(apiKey)")
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
    
    
    func calculateNutrition() {         //for one particular food
        for nutrient in nutritionResults {
            userPickedServing = servingTextField.text!
            userInputServing = Float(numOfServingTextField.text!)
            let cal = nutrient.energyKCal
            let carb = nutrient.carbohydrates
            let protein = nutrient.protein
            let fat = nutrient.lipids
            
            for _ in nutrient.measures {
                //                    if (userPickedServing == serving.label) {
                //calculate the nutrition
                energyKCal208 = Float(cal * Double(userInputServing))
                carbsG205 = Float(carb * Double(userInputServing))
                totalLipidG204 = Float(fat * Double(userInputServing))
                proteinG203 = Float(protein * Double(userInputServing))
                
                //}
            }
        }
    }

    
    func lambdaInvoker() {
        let email = self.userDefaults.value(forKey: "email") as! String
        let lambdaInvoker = AWSLambdaInvoker.default()
        var food_nutrient = [String:AnyObject]()    //json def
        food_nutrient = [":food_name" : food.name + " " + food.brandName as AnyObject,
                         ":user_picked_serving": userPickedServing as AnyObject,
                         ":user_input_serving": userInputServing as AnyObject,
                         ":energyKCal": energyKCal208 as AnyObject,
                         ":protein": proteinG203 as AnyObject,
                         ":lipids": totalLipidG204 as AnyObject,
                         ":carbohydrates": carbsG205 as AnyObject,
                         ":date": currentDate as AnyObject]
        
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
        task.continue(successBlock: { (task: AWSTask) -> Any? in
            if task.error != nil {
                print(task.error!)
            } else {
                if task.result != nil {
                    print("Posted! At NDB")
                } else {
                    print("Exception: \(String(describing: task.exception))")
                }
            }
            return nil
        })
    }
}
