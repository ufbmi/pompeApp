//
//  AuthViewController.swift
//  diaFit
//
//  Created by Liang,Franky Z on 4/8/16.
//  Copyright © 2016 Liang,Franky Z. All rights reserved.
//

import UIKit
import OAuthSwift

class AuthViewController: UIViewController {
    
    let oauthswift = OAuth2Swift(
        consumerKey: "896bfe71ba59439085b0fee520e03b09" , consumerSecret: "cf78ba3de6a74a71932a41930e15d206", authorizeUrl: "http://sandboxapi.ihealthlabs.com/OpenApiV2/OAuthv2/userauthorization/", accessTokenUrl: "http://sandboxapi.ihealthlabs.com/OpenApiV2/OAuthv2/userauthorization/", responseType: "code"
    )
    
    
    override func viewDidAppear(_ animated: Bool) {
        checkConnection()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
 


    
    @IBAction func onLoginButton(_ sender: AnyObject) {
        //take out grant_type?
        oauthswift.allowMissingStateCheck = true
        let state: String = generateState(withLength: 20) as String
        oauthswift.authorizeURLHandler = SafariURLHandler.self as! OAuthSwiftURLHandlerType
        oauthswift.authorize(withCallbackURL: URL(string: "com.mHealth.diaFit://oauth-callback")!, scope: "https://sandboxapi.ihealthlabs.com/openapiv2", state: state, parameters:  ["ApiName": "OpenApiBG"], success: { credential, response, parameters in
            //            print("I got a token!")
            //            print(credential.oauth_token)
            }, failure: { error in
                print(error)
                
            }
            )
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
