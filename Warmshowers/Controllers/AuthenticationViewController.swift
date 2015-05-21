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
    private var api = API.sharedInstance
    
    @IBOutlet weak var usernameTextField: UITextField! {
        didSet {
            usernameTextField.resignFirstResponder()
        }
    }
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var spinner: UIActivityIndicatorView! {
        didSet {
            spinner.hidesWhenStopped = true
        }
    }
    
    override func viewDidLoad()
    {
        usernameTextField?.text = APISecrets.Username
        passwordTextField?.text = APISecrets.Password
    }
    
    @IBAction func attemptLogin()
    {
        spinner.startAnimating()
              
        api
            .login(usernameTextField.text, password: passwordTextField.text)
            .onSuccess() { user in
                self.spinner.stopAnimating()
                self.performSegueWithIdentifier(Storyboard.ShowStartSegue, sender: nil)
            }
            .onFailure() { error in
                let alertController = UIAlertController(
                    title: "Login Problem",
                    message: "Incorrect username or password. Please try again ...",
                    preferredStyle: UIAlertControllerStyle.Alert
                )
                alertController.addAction(
                    UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil)
                )
                
                self.spinner.stopAnimating()
                self.presentViewController(alertController, animated: true, completion: nil)
            }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == Storyboard.ShowStartSegue {
            // TODO: handover the logged in user
        }
    }
}
