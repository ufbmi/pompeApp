//
//  MessagesViewController.swift
//  diaFit
//
//  Created by Mendoza,Tonatiuh on 7/26/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit
import AWSLambda
import AWSCore
import SwiftyJSON

class MessagesViewController:  UITableViewController {
    var message: String = ""
    var currentDate: String = ""
    @IBOutlet var myTableView: UITableView!
    let cellSpacingHeight: CGFloat = 5
    var messages = [Message]()
    let userDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.tableView.contentInset = UIEdgeInsetsMake(85,0,0,0);
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.checkConnection()
        self.messages.removeAll()
        DispatchQueue.main.async(execute: { () -> Void in
            self.getMessages()
        })
        
    }
    
   

    
    func getMessages() {
        let email = self.userDefaults.value(forKey: "email") as! String
        let lambdaInvoker = AWSLambdaInvoker.default()
        let jsonObject: [String: AnyObject] = [
            "operation": "read" as AnyObject,
            "TableName": "diaFitMessages" as AnyObject,
            "Key": ["email": email] as AnyObject
        ]
        let task = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonObject)
        task.continue(successBlock: { (task: AWSTask) -> Any? in
            if task.error != nil {
                print(task.error)
            } else {
                if task.result != nil {
                   for message in JSON(task.result!)["Item"] {
                    self.currentDate = message.0
                    if(self.currentDate != "email") {
                        let type = String(describing: message.1.type)
                        if type != "dictionary" {
                            let index = self.currentDate.index(self.currentDate.startIndex, offsetBy: 10)
                            let date = self.currentDate.substring(to: index)
                            let text =  String( describing: message.1)
                            self.messages += [Message(date: date, message: text, fullDate: self.currentDate)!]
                        }
                        
                    }
                    }
                    
                }
            }
            DispatchQueue.main.async {

                self.myTableView.reloadData()
            }
            return nil
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
  
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print("You tapped cell number \((indexPath as NSIndexPath).row).")
    }
    
 
    // this method handles row deletion
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            let email = self.userDefaults.value(forKey: "email") as! String

            // remove the item from the data model
            message = messages[(indexPath as NSIndexPath).row].message
            currentDate = messages[(indexPath as NSIndexPath).row].fullDate
            let response = [
                ":message": message,
                ":deleted": true
            ] as [String : Any]
            
            let lambdaInvoker = AWSLambdaInvoker.default()
            let jsonObject: [String: AnyObject] = [
                "TableName":  "diaFitMessages" as AnyObject,
                "operation": "update" as AnyObject ,
                //import email from other view controller -> public variable
                "Key": ["email": email] as AnyObject,
                "UpdateExpression": "set #date = :responses" as AnyObject,
                "ExpressionAttributeNames": [
                    "#date": currentDate
                ] as AnyObject,
                "ExpressionAttributeValues": [
                    ":responses": response
                ] as AnyObject,
                "ReturnValues": "UPDATED_NEW" as AnyObject
            ]
            let task = lambdaInvoker.invokeFunction("handlerDiaFIT", jsonObject: jsonObject)
            task.continue(successBlock: { (task: AWSTask) -> Any? in
                if task.error != nil {
                    print(task.error)
                    
                    
                } else {
                    print("DELETED Message")
                
                }
            return nil
            })
            messages.remove(at: (indexPath as NSIndexPath).row)
            // delete the table view row
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        } else if editingStyle == .insert {
            // Not used in our example, but if you were adding a new row, this is where you would do it.
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "MessageTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! MessageTableViewCell
        // Fetches the appropriate meal for the data source layout.
        let message = messages[(indexPath as NSIndexPath).row]
        cell.date.text = message.date
        cell.message.text = message.message
        
        // add border and color
        cell.backgroundColor = UIColor.white
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 8
        cell.clipsToBounds = true
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 60.0;
    }

}
