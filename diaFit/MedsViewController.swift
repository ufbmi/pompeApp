//
//  ViewController.swift
//  ManageMyReminders
//
//  Created by Malek T. on 11/19/15.
//  Copyright © 2015 Medigarage Studios LTD. All rights reserved.
//

import UIKit
import EventKit


class MedsViewController: ChildViewController, UITableViewDataSource, UITableViewDelegate{
    
    // Properties
    var eventStore: EKEventStore!
    var reminders: [EKReminder]!
    var selectedReminder: EKReminder!
    
    @IBOutlet var tableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        // Fetch all reminders
        // Connect to the Event Store
        self.eventStore = EKEventStore()
        self.reminders = [EKReminder]()
        self.eventStore.requestAccess(to: EKEntityType.reminder, completion: { (granted, error) in
            if granted{
                let predicate = self.eventStore.predicateForReminders(in: nil)
                self.eventStore.fetchReminders(matching: predicate, completion: { (reminders: [EKReminder]?) -> Void in
                    self.reminders = reminders
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                })
            }else{
                print("The app is not permitted to access reminders, make sure to grant permission in the settings and try again")
            }

        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
    
    @IBAction func editTable(_ sender: AnyObject) {
        tableView.isEditing = !tableView.isEditing
        if tableView.isEditing{
            tableView.setEditing(true, animated: true)
        }else{
            tableView.setEditing(false, animated: true)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        checkConnection()
    }
   

    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Which segue is triggered, react accordingly
        if segue.identifier == "showDetails"{
            let reminderDetailsVC = segue.destination as! MedsDetails
            reminderDetailsVC.reminder = self.selectedReminder
            reminderDetailsVC.eventStore = eventStore
        }else{
            let newReminderVC = segue.destination as! NewMeds
            newReminderVC.eventStore = eventStore
        }
    }
    
    
    //MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.reminders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:MedicationsCell! = tableView.dequeueReusableCell(withIdentifier: "medicationCell") as! MedicationsCell
        let medication:EKReminder! = self.reminders![(indexPath as NSIndexPath).row]
        cell.medName.text = medication.title
        cell.dose.text = medication.notes
        let formatter:DateFormatter = DateFormatter()
        formatter.dateFormat = "hh-mm-a"
        if let dueDate = (medication.dueDateComponents as NSDateComponents?)?.date{
            cell.reminder.text = formatter.string(from: dueDate)
        }else{
            cell.reminder.text = "N/A"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        let reminder: EKReminder = reminders[(indexPath as NSIndexPath).row]
        do{
            try eventStore.remove(reminder, commit: true)
            self.reminders.remove(at: (indexPath as NSIndexPath).row)
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
        }catch{
            print("An error occurred while removing the reminder from the Calendar database: \(error)")
        }
    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        self.selectedReminder = self.reminders[(indexPath as NSIndexPath).row]
        self.performSegue(withIdentifier: "showDetails", sender: self)
    }
}

