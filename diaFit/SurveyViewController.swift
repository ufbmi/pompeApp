//
//  SurveyViewController.swift
//  diaFit
//
//  Created by Liang,Zhan W on 5/25/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit
import AWSCore
import AWSLambda
import DLRadioButton
import SwiftyJSON


class SurveyViewController: ChildViewController {
    var arrayIndex:Int = 0
    var surveyArray = [(String,(String,String))]()
    @IBOutlet weak var radiobuttons: DLRadioButton!
    var dict = Dictionary<String, String>()
    let defaults = UserDefaults.standard
    var email: String = "N/A"
    var instruction: String = ""
    var surveyResponse: String = ""
    var previousquestion: String = ""
    let userDefaults = UserDefaults.standard
    let questionCounter: Int = 2
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var surveyButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        getquestions()
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        checkConnection()
        
    }
    
    
    @IBAction func nextButton(_ sender: AnyObject) {
        
        if self.arrayIndex == 9 {
            surveyButton.setTitle("Done", for: UIControlState())
            if surveyResponse.isEmpty {
                let alertController = UIAlertController(title: "Error", message: "Enter a value!", preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                    alertController.dismiss(animated: true, completion: nil)
                })
                alertController.addAction(OKAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                //update the last question and response to dictionary
                dict.updateValue(surveyResponse, forKey: previousquestion)
                radiobuttons.deselectOtherButtons()
                // run lambdaInvoker()
                lambdaInvoker()
                // pop UIAlertViewController with message saying we are done
            }

        } else {
            if surveyResponse.isEmpty{
                let alertController = UIAlertController(title: "Error", message: "Enter a value!", preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                    alertController.dismiss(animated: true, completion: nil)
                })
                alertController.addAction(OKAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                dict.updateValue(surveyResponse, forKey: previousquestion)
                radiobuttons.isSelected = false
                radiobuttons.deselectOtherButtons()
                surveyResponse = ""
                self.questionLabel.text = self.surveyArray[self.arrayIndex].1.0
                self.instructionLabel.text = self.surveyArray[self.arrayIndex].1.1
                self.previousquestion = self.questionLabel.text!
                self.arrayIndex += 1
            }
            
        }
    }
    
    func lambdaInvoker() {
        let email = self.userDefaults.value(forKey: "email") as! String
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/dd/yyyy"
            let currentDateForAWS =  dateFormatter.string(from: Date()) + " PROQuestions"
            let lambdaInvoker = AWSLambdaInvoker.default()
            let jsonObject: [String: AnyObject] = [
                "TableName":  "diaFitSurveyResponses" as AnyObject,
                "operation": "update" as AnyObject ,
                "Key": ["email": email] as AnyObject,
                "UpdateExpression": "set #date = :responses" as AnyObject,
                "ExpressionAttributeNames": [
                    "#date": currentDateForAWS
                ] as AnyObject,
                "ExpressionAttributeValues": [
                    ":responses": dict
                ] as AnyObject,
                "ReturnValues": "UPDATED_NEW" as AnyObject
            ]
            let task = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonObject)
            task.continue(successBlock: { (task: AWSTask) -> Any? in
                if task.error != nil {
                    print(task.error)
                } else {
                    if task.result != nil {
                        print("Posted at Survey!")
                        let alertController = UIAlertController(title: "Finished", message: "You are done with the survey!", preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                            // Segues to activity log using either HealthKit data or Fitbit data
                            if self.userDefaults.integer(forKey: "device") == 0 {
                                let storyBoard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
                                let Meds = storyBoard.instantiateViewController(withIdentifier: "mainMenuNav")
                                self.present(Meds, animated: true, completion: nil)
                            } else if self.userDefaults.integer(forKey: "device") == 1 {
                                let storyBoard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
                                let Fitbit = storyBoard.instantiateViewController(withIdentifier: "mainMenuNav")
                                self.present(Fitbit, animated: true, completion: nil)
                            }
                        })
                        alertController.addAction(OKAction)
                        self.present(alertController, animated: true, completion: nil)
                    } else {
                        print("Exception: \(task.exception)")
                    }
                }
                return nil
            })
        }
    }
    
    
    func getquestions() {
        let lambdaInvoker = AWSLambdaInvoker.default()
        let jsonObject: [String: AnyObject] = ["operation": "read" as AnyObject, "TableName": "SurveyTable" as AnyObject,"Key":["SurveyID":1] as AnyObject];
        let task = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonObject)
        task.continue(successBlock: { (task: AWSTask) -> Any? in
            if task.error != nil {
                print("Error: ", task.error)
            }
            if task.result != nil {
                let surveyJSON = JSON(task.result!)
                for questionsAndInstructions in surveyJSON["Item"] {
                    //Create dictionary with values of questions and instructions. Key is Question + "1", Question + "2", etc..
                    if questionsAndInstructions.0 != "SurveyID" {
                        let question = questionsAndInstructions.1["Question"].stringValue
                        let instruction = questionsAndInstructions.1["Instruction"].stringValue
                        self.surveyArray.append(questionsAndInstructions.0, (question, instruction))
                    }
                }
                //sort array
                self.surveyArray = self.surveyArray.sorted(by: { $0.0 < $1.0 })
                     DispatchQueue.main.async {
                        self.questionLabel.text = self.surveyArray[self.arrayIndex].1.0
                        self.instructionLabel.text = self.surveyArray[self.arrayIndex].1.1
                        self.previousquestion = self.questionLabel.text!
                        self.arrayIndex += 1
                    }
            }
            return nil
        })
    }
    
  
    
    @IBAction func radioButtonsSource(_ radiobutton: DLRadioButton) {
        let response = radiobutton.selected()!.titleLabel!.text! as String
        surveyResponse = response
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
