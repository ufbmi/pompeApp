//
//  ViewController.swift
//  diaFit
//
//  Created by Liang,Franky Z on 4/7/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
    var dataTask: URLSessionDataTask?
    var searchResults = [Food]()
    var dateTitle:String?
    var currentDate:String?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
    }
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController!.navigationBar.topItem!.title = dateTitle
        checkConnection()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override var shouldAutorotate : Bool {
        return false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }

    
    
    func updateSearchResults(_ data: Data?) {
        searchResults.removeAll()
        do {
            if let dataInput: Data = data, let jsonParsed = try? JSONSerialization.jsonObject(with: dataInput, options:JSONSerialization.ReadingOptions(rawValue:0)) {
                if let dictLevel1 = jsonParsed as? [String: Any] {
                    if let dictLevel2 = dictLevel1["list"] as? [String: Any] {
                        if let arrayLevel3 = dictLevel2["item"] as? NSArray {
                            for foodSet in arrayLevel3 {
                                let food: [String: Any] = foodSet as! [String : Any]
                                let name = food["name"] as? String
                                let group = food["group"] as? String
                                let ndbno = food["ndbno"] as? String
                                searchResults.append(Food(name: name!, group: group!, ndbno: ndbno!))
                            }
                        }
                        else {
                            print("Error: search view controller, arrayLevel3")
                        }
                    }
                    else {
                        print("Error: search view controller, dictLevel2")
                    }
                }
                else {
                    print("Error: search view controller, dictLevel1")
                }
            }
            else {
                print("Error: search view controller, serialization")
            }
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.setContentOffset(CGPoint.zero, animated: false)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return searchResults.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoodCell", for: indexPath) as! FoodCell
        let food = searchResults[(indexPath as NSIndexPath).row]
        // Configure food name labels
        cell.foodLabel.text = food.name
        return cell
    }
    
    func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
        if !searchBar.text!.isEmpty {
            if dataTask != nil {
                dataTask?.cancel()
            }
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let expectedCharSet = CharacterSet.urlQueryAllowed
        let searchText = searchBar.text!.addingPercentEncoding(withAllowedCharacters: expectedCharSet)!
        let apiKey = "1ADB1YidG74qvv8NbqPxUVOcZjyRZhtpFURGEyIE"
        let url = URL(string:"https://api.nal.usda.gov/ndb/search/?format=json&q=\(searchText)&sort=n&max=25&offset=0&api_key=\(apiKey)")
        dataTask = defaultSession.dataTask(with: url!, completionHandler: {
            data, response, error in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            if let error = error {
                print(error.localizedDescription)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    self.updateSearchResults(data)
                }
            }
        }) 
        dataTask?.resume()
    }
    
    
    @IBAction func onCancel(_ sender: AnyObject) {
        let storyBoard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
        let menu = storyBoard.instantiateViewController(withIdentifier: "mainMenuNav")
        self.present(menu, animated: true, completion: nil)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNDBDetailViewControllerSegue" {
            let cell = sender as! UITableViewCell
            let ndbDetailViewController = segue.destination as! NDBDetailViewController
            let indexPath = tableView.indexPath(for: cell)
            ndbDetailViewController.food = searchResults[(indexPath! as NSIndexPath).row]
            ndbDetailViewController.currentDate = currentDate!
        }
    }
    
}

extension UIViewController {
    func checkConnection() {
        let status = Reach().connectionStatus()
        let statusDescription = status.description
        if (statusDescription == "Offline") {
            let NoConnection = UIAlertController(title: "No Internet Connection", message: "Make sure your device is connected to the internet.", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                self.checkConnection()
                NoConnection.dismiss(animated: true, completion: nil)
            })
            NoConnection.addAction(OKAction)
            DispatchQueue.main.async {
                self.present(NoConnection, animated: true, completion: nil);
            }
        }
        
    }
}
