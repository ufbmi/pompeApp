//
//  ReminderDetails.swift
//  ManageMyReminders
//
//  Created by Malek T. on 11/20/15.
//  Copyright © 2015 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import EventKit

class MedsDetails: UIViewController {
    
    // Properties
    var datePicker: UIDatePicker!
    var reminder: EKReminder!
    var eventStore: EKEventStore!
    
    @IBOutlet var dateTextField: UITextField!
    @IBOutlet var medsTextField: UITextField!
    
    @IBOutlet var doseTextField: UITextField!
    
    @IBAction func saveReminder(_ sender: AnyObject) {
        self.reminder.title = medsTextField.text!
        reminder.notes = doseTextField.text!
        let gregorian = Calendar(identifier: Calendar.Identifier.gregorian)
        let dueDate =  (Calendar.current as NSCalendar).date(
            byAdding: .year,
            value: 2,
            to: self.datePicker.date,
            options: NSCalendar.Options(rawValue: 0))
        let unitFlags = NSCalendar.Unit(rawValue: UInt.max)
        let reminderDueDate  = (gregorian as NSCalendar?)?.components(unitFlags, from: dueDate!)
        reminder.dueDateComponents = reminderDueDate
        reminder.calendar = self.eventStore.defaultCalendarForNewReminders()
        do {
            try self.eventStore.save(reminder, commit: true)
            self.navigationController?.popToRootViewController(animated: true)
        }catch{
            print("Error creating and saving new reminder : \(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.medsTextField.text = self.reminder.title
        doseTextField.text = reminder.notes
        datePicker = UIDatePicker()
        datePicker.addTarget(self, action: #selector(MedsDetails.addDate), for: UIControlEvents.valueChanged)
        datePicker.datePickerMode = UIDatePickerMode.time
        dateTextField.inputView = datePicker
        medsTextField.becomeFirstResponder()
        let formatter:DateFormatter = DateFormatter()
        formatter.dateFormat = "hh-mm-a"
        if let dueDate = (reminder.dueDateComponents as NSDateComponents?)?.date {
           dateTextField.text  = formatter.string(from: dueDate)
        }else{
            dateTextField.text = "N/A"
        }

        
    }
    override func viewDidAppear(_ animated: Bool) {
        checkConnection()
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
