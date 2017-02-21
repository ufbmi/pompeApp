//
//  NewReminder.swift
//  ManageMyReminders
//
//  Created by Malek T. on 11/20/15.
//  Copyright © 2015 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import EventKit
import DLRadioButton
import AWSLambda
import AWSCore

class NewMeds: UIViewController {
    
    
    // Properties
    var eventStore: EKEventStore!
    var datePicker: UIDatePicker!
    
    @IBOutlet var newMedsTextField: UITextField!
    @IBOutlet var dateTextField: UITextField!
    @IBOutlet var doseTextField: UITextField!
    @IBOutlet var reminderButton: DLRadioButton!
    
    let userDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker = UIDatePicker()
        datePicker.addTarget(self, action: #selector(NewMeds.addDate), for: UIControlEvents.valueChanged)
        datePicker.datePickerMode = UIDatePickerMode.time
        dateTextField.inputView = datePicker
    }
    
    @IBAction func 	dismiss(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkConnection()
    }
    

    
   
    
    func lambdainvoker() {
        
        let email = self.userDefaults.value(forKey: "email") as! String

        let medicationName = newMedsTextField.text!
        let medicationDose = doseTextField.text!
        let lambdaInvoker = AWSLambdaInvoker.default()
        let jsonObject: [String: AnyObject] = [
            "TableName":  "diafitMeds" as AnyObject,
            "operation": "update" as AnyObject,
            "Key": ["email": email] as AnyObject,
            "UpdateExpression": "set #medicationName = :medicationDose" as AnyObject,
            "ExpressionAttributeNames": [
                "#medicationName": medicationName,
                
                ] as AnyObject,
            "ExpressionAttributeValues" :
                [
                    ":medicationDose" : medicationDose,
                    ] as AnyObject,
            "ReturnValues": "UPDATED_NEW" as AnyObject
        ]
        let task = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonObject)
        task.continue(successBlock: { (task: AWSTask) -> Any? in
            if task.error != nil {
                print(task.error)
            } else {
                if task.result != nil {
                    //print(task.result)
                    print("Posted at newMeds")
                    DispatchQueue.main.async {
                        let storyBoard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
                        let menu = storyBoard.instantiateViewController(withIdentifier: "mainMenuNav")
                        self.present(menu, animated: true, completion: nil)
                    }
                } else {
                    print("Exception: \(task.exception)")
                }
            }
            return nil
        })
    }
    
    @IBAction func saveNewReminder(_ sender: AnyObject) {
        let gregorian = Calendar(identifier: Calendar.Identifier.gregorian)
        let dueDate =  (Calendar.current as NSCalendar).date(
            byAdding: .year,
            value: 2,
            to: self.datePicker.date,
            options: NSCalendar.Options(rawValue: 0))
        let unitFlags = NSCalendar.Unit(rawValue: UInt.max)
        let dueDateComponents  = (gregorian as NSCalendar?)?.components(unitFlags, from: dueDate!)
        let reminder = EKReminder(eventStore: self.eventStore)
        reminder.title = newMedsTextField.text!
        reminder.notes = doseTextField.text!
        reminder.dueDateComponents = dueDateComponents
        reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
        let recurrence = EKRecurrenceRule(recurrenceWith: .daily,
            interval: 1,
            daysOfTheWeek: [EKRecurrenceDayOfWeek(.monday)],
            daysOfTheMonth: nil,
            monthsOfTheYear: nil,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: nil, 
            end: nil)
        if(reminderButton.isSelected){
            let alarm = EKAlarm(absoluteDate: self.datePicker.date)
            reminder.addRecurrenceRule(recurrence)
            reminder.addAlarm(alarm)
        }


        do {
            lambdainvoker()
            try self.eventStore.save(reminder, commit: true)
            self.dismiss(animated: true, completion: nil)
        }catch{
            print("Error creating and saving new reminder : \(error)")
        }
    }
    
    func addDate(){
        let formatter:DateFormatter = DateFormatter()
        formatter.dateFormat = "hh-mm-a"
        self.dateTextField.text = formatter.string(from: self.datePicker.date)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
