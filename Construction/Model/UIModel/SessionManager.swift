//
//  SessionManager.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseCore
import SVProgressHUD

class SessionManager{
    static var shared = SessionManager()
    
    var loggedIn: Bool {
        if let _ = Auth.auth().currentUser {
            return true
        }
        else {
            return false
        }
    }
    
    func checkLogin() {
        if let user = Auth.auth().currentUser {
            if let email = user.email {
                SVProgressHUD.show(withStatus: "Loading...")
                User.load(email: email, completion: { (returnedUser) in
                    SVProgressHUD.dismiss()
                    if let returnedUser = returnedUser {
                        Manager.shared.user = returnedUser
                        UIManager.shared.showMain(animated: true)
                    }
                })
            }
        }
    }
}
