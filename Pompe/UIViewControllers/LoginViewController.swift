//
//  LoginViewController.swift
//  diaFit
//
//  Created by Liang,Franky Z on 4/28/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit
import AWSCore
import AWSLambda
import DLRadioButton

class LoginViewController: UIViewController,UITextFieldDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!/*{
        didSet{
            passwordTextField.delegate = self
        }
    }*/
    
    @IBOutlet weak var passConfTextField: UITextField!
    @IBOutlet weak var newUserButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    var  email = ""
    @IBOutlet var rememberMe: DLRadioButton!
    var registerSelected = false
    @IBOutlet var subViewArea: UIView!
    let userDefaults = UserDefaults.standard
       let deviceManager:DeviceManager = DeviceManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        passConfTextField.isHidden = true;
        let screenSize: CGRect = UIScreen.main.bounds;
        let screenWidth = screenSize.width;
        let screenHeight = screenSize.height;
        subViewArea.center = CGPoint(x: screenWidth / 2,
            y: screenHeight / 2);
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    override var shouldAutorotate : Bool {
        return false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }

    override func viewDidAppear(_ animated: Bool) {
        checkConnection()
        checkForLoginPass()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        passwordTextField.text = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true     //*********
    }

    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }

    @IBAction func newHere(_ sender: AnyObject) {
        if (!registerSelected) {
            registerSelected = true;
            signInButton.setTitle("Sign up", for: UIControl.State())
            newUserButton.setTitle("I am not new", for: UIControl.State())
            passConfTextField.isHidden = false;
        }
        else {
            registerSelected = false;
            signInButton.setTitle("Sign in", for: UIControl.State())
            newUserButton.setTitle("Register me.", for: UIControl.State())
            passConfTextField.isHidden = true;
        }
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    @IBAction func onLogin(_ sender: AnyObject) {
        if(emailTextField.text == "" || passwordTextField.text == ""){
            let unmatchedPassword = UIAlertController(title: "Oops", message: "Please provide an email/password.", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                unmatchedPassword.dismiss(animated: true, completion: nil)
            })
            unmatchedPassword.addAction(OKAction)
            self.present(unmatchedPassword, animated: true, completion: nil)
        } else if (registerSelected){
            if(emailTextField.text == "" || passwordTextField.text == ""){
                let unmatchedPassword = UIAlertController(title: "Oops", message: "Please provide an email/password.", preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                    unmatchedPassword.dismiss(animated: true, completion: nil)
                })
                unmatchedPassword.addAction(OKAction)
                self.present(unmatchedPassword, animated: true, completion: nil)
            }
            else {
                if(passConfTextField.text != passwordTextField.text){
                    let unmatchedPassword = UIAlertController(title: "Oops", message: "The password and password confirmation have to match.", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                        unmatchedPassword.dismiss(animated: true, completion: nil)
                    })
                    unmatchedPassword.addAction(OKAction)
                    self.present(unmatchedPassword, animated: true, completion: nil)
                }
                else{
                    if(isValidEmail(emailTextField.text!)){
                        registerUser();
                    }
                    else {
                        let badEmail = UIAlertController(title: "Oops", message: "Please input a valid email.", preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                        badEmail.dismiss(animated: true, completion: nil)
                        })
                        badEmail.addAction(OKAction)
                        self.present(badEmail, animated: true, completion: nil)
                    }
                }
               
            }
        }
        else{
            if(isValidEmail(emailTextField.text!)){
                  authenticateUser();
            }
            else {
                let badEmail = UIAlertController(title: "Oops", message: "Please input a valid email.", preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                    badEmail.dismiss(animated: true, completion: nil)
                })
                badEmail.addAction(OKAction)
                self.present(badEmail, animated: true, completion: nil)
            }
          
        }
    }
    
   
    
    func authenticateUser() {
        let lambdaInvoker = AWSLambdaInvoker.default()
        let emailAddress = emailTextField.text!.lowercased()
        let jsonObject: [String: AnyObject] = ["email": emailAddress as AnyObject, "password": passwordTextField.text! as AnyObject];
        let task = lambdaInvoker.invokeFunction("diaFitLogin", jsonObject: jsonObject)
        task.continue(successBlock: { (task: AWSTask) -> Any? in
            if task.error != nil {
                print("Error: ", task.error as Any)
            }
            if((task.exception) != nil) {
                print("Exception: \(String(describing: task.exception))" )
            }
            if task.result != nil {
                let login: NSNumber = task.result!.value(forKey: "login") as! NSNumber
                let loginAlert = UIAlertController(title: "Oops", message: "Please verify your email.", preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                    loginAlert.dismiss(animated: true, completion: nil)
                });
                loginAlert.addAction(OKAction)
                if(login != 1) {
                    let verified =  task.result?.value(forKey: "verified")
                    if (verified != nil && verified as! NSNumber != 1) {
                        loginAlert.message = "Please verify your email.";
                        DispatchQueue.main.async {
                            self.present(loginAlert, animated: true, completion: nil);
                        }
                    }
                    else {
                        loginAlert.message = "Please check your email/password.";
                        DispatchQueue.main.async {
                            self.present(loginAlert, animated: true, completion: nil);
                        }
                    }
                }
                else {
                    self.userDefaults.setValue(self.emailTextField.text,forKey: "email")
                         DispatchQueue.main.async {
                        let _: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                                self.deviceManager.authorizeFitbit(){(authorized: Bool) in
                                    if authorized {
                                        print("Authorized to FitBit ")
                                        
                                        self.log()

                                        //Once htey login for the first time they do not need to go through this.
                                        self.userDefaults.set(false, forKey: "loginFirstTime");
                                        self.userDefaults.setValue(false, forKey: "deviceFirstTime")
                                        self.userDefaults.synchronize()
                                    } else {
                                        print("Error in FITBIT Authorize.")
                                    }
                                }
                    }
                }
            }
            return nil;
        })
    }
    
    func registerUser() {
        let lambdaInvoker = AWSLambdaInvoker.default()
        let emailAddress = emailTextField.text!.lowercased()
        let jsonObject: [String: AnyObject] = ["email":  emailAddress as AnyObject, "password": passwordTextField.text! as AnyObject];
        let task = lambdaInvoker.invokeFunction("diaFitCreateUser", jsonObject: jsonObject)
        task.continue(successBlock: { (task: AWSTask) -> Any? in
            if task.error != nil {
                print("Error: ", task.error as Any)
            }
            if task.result != nil {
                let success: NSNumber = task.result!.value(forKey: "created") as! NSNumber
                if(success == 1){
                    let created = UIAlertController(title: "Got it!", message: "Please verify your email.", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                    created.dismiss(animated: true, completion: nil)
                    })
                    created.addAction(OKAction)
                    DispatchQueue.main.async {
                        self.present(created, animated: true, completion: nil);
                        self.registerSelected = false;
                        self.signInButton.setTitle("Sign in", for: UIControl.State.normal)
                        self.newUserButton.setTitle("Register me.", for: UIControl.State.normal)
                        self.passConfTextField.isHidden = true;
                    }
                }
                else {
                    let badEmail = UIAlertController(title: "Oops", message: "There is a problem with your email. Please contact us.", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
                        badEmail.dismiss(animated: true, completion: nil)
                    })
                    badEmail.addAction(OKAction)
                    DispatchQueue.main.async {
                        self.present(badEmail, animated: true, completion: nil);
                    }
                }
            }
            if((task.exception) != nil) {
                print("Exception: \(String(describing: task.exception))" )
            }
            return nil
        })
    }
    
    func isValidEmail(_ testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }

    
func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let inverseSet = CharacterSet(charactersIn:"0123456789.").inverted
    let components = string.components(separatedBy: inverseSet)
    let filtered = components.joined(separator: "")
    return string == filtered
    }
    
    func log(){
        
        let storyBoard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
        let menuController  = storyBoard.instantiateViewController(withIdentifier: "DrawerMenu")
        let frontController: FoodLogViewController = UIStoryboard(name: "Nutrition", bundle: nil).instantiateViewController(withIdentifier: "foodLog") as! FoodLogViewController
        
        let frontNavController : UINavigationController = storyBoard.instantiateViewController(withIdentifier: "CommonNavController") as! UINavigationController
        
        frontNavController.viewControllers = [frontController]
        
        let navDrawerController = NavigationDrawerController.init(frontViewController: frontNavController, menuController: menuController)
        
        self.present(navDrawerController, animated: true, completion: nil)
    }
    
    func checkForLoginPass(){
        
        if let rememberMe = userDefaults.value(forKey: "loginFirstTime") {
            
            if rememberMe as! Bool == false {
                
               log()
            }
        }
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
