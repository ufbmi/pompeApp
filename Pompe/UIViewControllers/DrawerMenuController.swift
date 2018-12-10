//
//  DrawerMenuController.swift
//  NavigationDrawer-Swift
//
//  Created by Pulkit Rohilla on 26/05/17.
//  Copyright © 2018 PulkitRohilla. All rights reserved.
//

import UIKit

protocol DrawerMenuDelegate : NSObjectProtocol {
    
    func didSelectMenuOptionAtIndex(indexPath: IndexPath)
}

class DrawerMenuController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var delegate : DrawerMenuDelegate!
    let titleArray = ["Nutrition Log", "FitBit Activity Log", "Weight Log", "User Profile"]
    let imageArray = [UIImage.init(named: "nutrition"), UIImage.init(named: "fitbit"), UIImage.init(named: "weight"), UIImage.init(named: "user")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return titleArray.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        let cell : DrawerMenuCell = tableView.dequeueReusableCell(withIdentifier: "optionCellIdentifier", for: indexPath) as! DrawerMenuCell
        cell.lblTitle.text = titleArray[indexPath.row]
        cell.imgIcon.image = imageArray[indexPath.row]
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        delegate.didSelectMenuOptionAtIndex(indexPath: indexPath)
    }
}
