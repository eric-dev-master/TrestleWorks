//
//  SignUpViewController.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import SVProgressHUD

class SignUpViewController: BarHidableViewController {
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func onSignUp(_ sender: Any) {
        guard let email = txtEmail.text, email.isValidEmail() else {
            self.alert(message: "Please type your email correctly.")
            return
        }
        
        guard let password = txtPassword.text, password.count >= 6 else {
            self.alert(message: "Password should be at least 6 characters.")
            return
        }
        
        SVProgressHUD.show()
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            SVProgressHUD.dismiss()
            
            if let error = error {
                self.alert(message: error.localizedDescription)
                return
            }
            
            if let user = user {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = self.txtName.text
                changeRequest.commitChanges(completion: { (error) in
                    
                })
            }
            
            self.sendEmail(email: email, password: password)
        }
    }
    
    func sendEmail(email: String, password: String) {
        SVProgressHUD.show()
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            SVProgressHUD.dismiss()
            if let error = error {
                self.alert(message: error.localizedDescription)
                return
            }
            
            SVProgressHUD.show()
            user!.sendEmailVerification(completion: { (error) in
                SVProgressHUD.dismiss()
                if let error = error {
                    self.alert(message: error.localizedDescription)
                    return
                }
                
                self.alert(title: "Verificaiton Email has been sent.", message: "Please tap on the link in the email to verify your account.", options: "Ok", completion: { (index) in
                    self.navigationController?.popViewController(animated: true)
                })
            })
        }
    }
}

extension SignUpViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtName {
            txtEmail.becomeFirstResponder()
        }
        else if textField == txtEmail {
            txtPassword.becomeFirstResponder()
        }
        else if textField == txtPassword {
            textField.resignFirstResponder()
        }
        return true
    }
}
