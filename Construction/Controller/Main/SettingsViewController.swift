//
//  SettingsViewController.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import SVProgressHUD

class SettingsViewController: UITableViewController {
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var imgPassword: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imgProfile.tintColor = #colorLiteral(red: 0.7326959968, green: 0.612052381, blue: 0.435046494, alpha: 1)
        imgPassword.tintColor = #colorLiteral(red: 0.7326959968, green: 0.612052381, blue: 0.435046494, alpha: 1)

        if let footer = self.tableView.tableFooterView {
            var footerRect = footer.frame
            footerRect.size.height = 0
            footer.frame = footerRect
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {//Change Password
            self.changePassword()
        }
    }
    
    func changePassword() {
        let controller = UIStoryboard(name: "Project", bundle: nil).instantiateViewController(withIdentifier: "sid_prompt") as! PromptViewController
        controller.delegate = self
        controller.type = .changePassword
        controller.title = "Change Password"
        controller.modalPresentationStyle = .overFullScreen
        self.present(controller, animated: true, completion: nil)
    }
}

extension SettingsViewController: PromptDelegate {
    func done(with values: [String : Any]) {
        if let user = Auth.auth().currentUser,
            let password = values["New Password"] as? String{
            SVProgressHUD.show()
            user.updatePassword(to: password, completion: { (err) in
                SVProgressHUD.dismiss()
                if let error = err {
                    self.alert(message: error.localizedDescription)
                }
                else {
                    if let curUser = Manager.shared.user {
                        curUser.password = password
                    }
                    self.alert(message: "Update password successfully.")
                }
            })
        }
    }
    
    func invalidField(values: [String : Any]) -> String? {
        for (key, value) in values {
            if (value as! String).count == 0 {
                return key
            }
        }

        if let oldPassword = values["Old Password"] as? String {
            if let password = Manager.shared.user.password {
                if oldPassword != password {
                    return "Old Password"
                }
            }
        }
        
        if let newPassword = values["New Password"] as? String,
           let confirmPassword = values["Confirm Password"] as? String
        {
            if newPassword.count < 6 {
                return "New Password"
            }
            if confirmPassword.count < 6 {
                return "Confirm Password"
            }
            if newPassword != confirmPassword {
                return "Confirm Password"
            }
        }
        return nil
    }
}
