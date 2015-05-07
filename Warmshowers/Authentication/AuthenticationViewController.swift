//
//  AuthenticationViewController.swift
//  Warmshowers
//
//  Created by Michael Haeuslmann on 07/05/15.
//  Copyright (c) 2015 Michael Haeuslmann. All rights reserved.
//

import UIKit
import XCGLogger

class AuthenticationViewController: UIViewController
{
    @IBOutlet weak var usernameTextField: UITextField! {
        didSet {
            usernameTextField.resignFirstResponder()
        }
    }
    @IBOutlet weak var passwordTextField: UITextField!

    let authentication = Authentication()
    
    @IBAction func attemptLogin()
    {
        let username = usernameTextField.text
        let password = passwordTextField.text
        
        if username == "" || password == "" {
            return
        }
        
        if authentication.login(username, password: password) {
            log.info("Login success: \(username)")
            
        } else {
            log.info("Login failure: \(password)")
        }
    }
}
