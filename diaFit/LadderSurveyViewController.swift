//
//  LadderSurveyViewController.swift
//  diaFit
//
//  Created by Liang,Zhan W on 6/1/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit
import AWSCore
import AWSLambda
import DLRadioButton

class LadderSurveyViewController: ChildViewController {
    
    @IBOutlet weak var questionLabel: UILabel!
    var dict = Dictionary<String, String>()
    let userDefaults = UserDefaults.standard
    var email: String = "N/A"
    var surveyResponse: String = ""
    var ladderquestion: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        getquestions()
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        checkConnection()
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func nextButton(_ sender: AnyObject) {
        if surveyResponse.isEmpty{
            let alertController = UIAlertController(title: "Error", message: "Enter a value!", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                alertController.dismiss(animated: true, completion: nil)
            })
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: nil)
        } else {
        dict.updateValue(surveyResponse, forKey: ladderquestion)
        lambdaInvoker()
        }
    }
    
    func getquestions(){
        let lambdaInvoker = AWSLambdaInvoker.default()
        let jsonObject: [String: AnyObject] = ["operation": "read" as AnyObject, "TableName": "SurveyTable" as AnyObject,"Key":["SurveyID":2]as AnyObject];
        let task = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonObject)
        task.continue(successBlock: { (task: AWSTask) -> Any? in

            if task.error != nil {
                print("Error: ", task.error)
            }
            if task.result != nil {
                do {
                    let json = task.result as! Dictionary<String, AnyObject>
                    var listofquestions = json["Item"] as! Dictionary<String, AnyObject>
                    //remove surveyID column from dictionary
                    listofquestions.removeValue(forKey: "SurveyID")
                    var listofquestionarray = Array(listofquestions.values) as Array;
                   //set questionlabel to index 0 at array
                   DispatchQueue.main.async {
                        self.questionLabel.text = (listofquestionarray[0]) as? String
                        //instantialize global variable ladderquestion to ladderquestion text
                        self.ladderquestion = (listofquestionarray[0]) as! String
                    }
                    }
            
            }
            
            return nil
        })
    }

    @IBAction func RadiobuttonSource(_ radioButton: DLRadioButton) {
        let response = radioButton.selected()!.titleLabel!.text! as String
        surveyResponse = response
    
    }


    
    func lambdaInvoker() {
        let email = self.userDefaults.value(forKey: "email") as! String
        do {
            let jsonData = try! JSONSerialization.data(withJSONObject: dict , options: JSONSerialization.WritingOptions.prettyPrinted)
            let jsonString = NSString(data:jsonData,encoding: String.Encoding.utf8.rawValue)! as String
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/dd/yyyy"
            let currentDateForAWS =  dateFormatter.string(from: Date()) + " LadderQuestion"
            let lambdaInvoker = AWSLambdaInvoker.default()
            let jsonObject: [String: AnyObject] = [
                "TableName":  "diaFitSurveyResponses" as AnyObject,
                "operation": "update" as AnyObject ,
                //import email from other view controller -> public variable
                "Key": ["email": email] as AnyObject,
                "UpdateExpression": "set #date = :responses" as AnyObject,
                "ExpressionAttributeNames"	: [
                    "#date": currentDateForAWS
                ] as AnyObject,
                "ExpressionAttributeValues": [
                    ":responses": jsonString
                ] as AnyObject,
                "ReturnValues": "UPDATED_NEW" as AnyObject
            ]
            let task = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonObject)
            task.continue(successBlock: { (task: AWSTask) -> Any? in
                if task.error != nil {
                    print(task.error)
                } else {
                    if task.result != nil {
                        print("Posted at Ladder!")
                        let alertController = UIAlertController(title: "Finished", message: "You are done with the survey!", preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                            alertController.dismiss(animated: true, completion: nil)
                        let storyBoard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
                        let mainMenu = storyBoard.instantiateViewController(withIdentifier: "mainMenuNav")
                        self.present(mainMenu, animated: true, completion: nil)
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

}
