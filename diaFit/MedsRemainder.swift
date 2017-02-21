//
//  ReminderDetails.swift
//  ManageMyReminders
//
//  Created by Malek T. on 11/20/15.
//  Copyright © 2015 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import EventKit

class MedsRemainder: UIViewController {
    
    // Properties
    var datePicker: UIDatePicker!
    var reminder: EKReminder!
    var eventStore: EKEventStore!
    
    @IBOutlet var medText: UITextField!
    @IBOutlet var dateTextField: UITextField!
    
    
    
    @IBAction func saveReminder(sender: AnyObject) {
        self.reminder.title = medText.text!
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let dueDateComponents = appDelegate.dateComponentFromNSDate(self.datePicker.date)
        reminder.dueDateComponents = dueDateComponents
        reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
        do {
            try self.eventStore.saveReminder(reminder, commit: true)
            self.navigationController?.popToRootViewControllerAnimated(true)
        }catch{
            print("Error creating and saving new reminder : \(error)")
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.medText.text = self.reminder.title
        datePicker = UIDatePicker()
        datePicker.addTarget(self, action: "addDate", forControlEvents: UIControlEvents.ValueChanged)
        datePicker.datePickerMode = UIDatePickerMode.DateAndTime
        dateTextField.inputView = datePicker
        medText.becomeFirstResponder()
        
    }
    
    func addDate(){
        self.dateTextField.text = self.datePicker.date.description
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
