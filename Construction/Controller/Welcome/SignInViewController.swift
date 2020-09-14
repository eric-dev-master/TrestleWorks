//
//  SignInViewController.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import SVProgressHUD

class SignInViewController: BarHidableViewController {
    @IBOutlet weak var lblForgotPassword: UIButton!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblForgotPassword.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SignInViewController.onForgotPassword(_:)))
        lblForgotPassword.addGestureRecognizer(tapGesture)
    }
    
    @objc func onForgotPassword(_ sender: Any) {
        guard let email = txtEmail.text, email.isValidEmail() else {
            self.alert(message: "Please type your email correctly.")
            return
        }

        SVProgressHUD.show()
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            SVProgressHUD.dismiss()
            if let error = error {
                self.alert(message: error.localizedDescription)
                return
            }
            else {
                self.alert(message: "A password reset email has been sent to your registered email.", title: "Reset email sent.")
            }
        }
    }
    
    @IBAction func onSignIn(_ sender: Any) {
        guard let email = txtEmail.text, email.isValidEmail() else {
            self.alert(message: "Please type your email correctly.")
            return
        }
        
        guard let password = txtPassword.text, password.count >= 6 else {
            self.alert(message: "Password should be at least 6 characters.")
            return
        }
        
        SVProgressHUD.show()
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            SVProgressHUD.dismiss()
            if let error = error {
                self.alert(message: error.localizedDescription)
                return
            }
            
            if let user = user {
//                User.load(email: email, completion: { (returnedUser) in
//                    if let returnedUser = returnedUser {
//                        Manager.shared.user = returnedUser
//                        UIManager.shared.showMain()
//                    }
//                    else {
//                        let currentUser = User()
//                        currentUser.email = user.email
//                        currentUser.name = user.displayName
//                        currentUser.password = password
//                        currentUser.save({ (ref, error) in
//                            if error == nil {
//                                Manager.shared.user = currentUser
//                                UIManager.shared.showMain()
//                            }
//                            else {
//                                self.alert(message: "Server is busy now. please try again later.")
//                            }
//                        })
//                    }
//                })
//                return

                if user.isEmailVerified {
                    User.load(email: email, completion: { (returnedUser) in
                        if let returnedUser = returnedUser {
                            Manager.shared.user = returnedUser
                            UIManager.shared.showMain()
                        }
                        else {
                            let currentUser = User()
                            currentUser.email = user.email
                            currentUser.name = user.displayName
                            currentUser.password = password
                            currentUser.save({ (ref, error) in
                                if error == nil {
                                    Manager.shared.user = currentUser
                                    UIManager.shared.showMain()
                                }
                                else {
                                    self.alert(message: "Server is busy now. please try again later.")
                                }
                            })
                        }
                    })
                }
                else {
                    self.alert(title: "Your account is currently not active. ", message: "Are you going to send new verification email?", options: "Yes", "No", completion: { (index) in
                        if (index == 0) {
                            SVProgressHUD.show()
                            user.sendEmailVerification(completion: { (error) in
                                SVProgressHUD.dismiss()
                                if let error = error {
                                    self.alert(message: error.localizedDescription)
                                    return
                                }
                                
                                self.alert(title: "Verification email has been sent.", message: "Please tap on the link in the email to verify your account.", options: "Ok", completion: { (index) in
                                })
                            })
                        }
                    })
                    do {
                        try Auth.auth().signOut()
                    } catch {
                        print("Sign out failure.")
                    }
                }
            }
        }
    }
}

extension SignInViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtEmail {
            txtPassword.becomeFirstResponder()
        }
        else if textField == txtPassword {
            textField.resignFirstResponder()
        }
        return true
    }
}
