//
//  MenuViewController.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

class MenuViewController: UITableViewController {
    @IBOutlet weak var lblInvitation: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblInvitation.layer.cornerRadius = 12.5
        lblInvitation.layer.masksToBounds = true
        lblInvitation.layer.borderColor = UIColor.white.cgColor
        lblInvitation.layer.borderWidth = 1.5
        
        self.setupObserver()
    }
    
    func setupObserver() {
        if let user = Manager.shared.user {
            updateInvitationLabel(count: UInt(user.invited.count))
            user.invited.ref.observe(.value, with: { (snapshot) in
                if snapshot.exists(){
                    self.updateInvitationLabel(count: snapshot.childrenCount)
                }
                else {
                    self.updateInvitationLabel(count: 0)
                }
            })
        }
    }
    
    func updateInvitationLabel(count: UInt) {
        if count == 0 {
            self.lblInvitation.isHidden = true
        }
        else {
            self.lblInvitation.isHidden = false
            self.lblInvitation.text = "\(count)"
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 4 { //Home page
            if let link = URL(string: "https://lekshmysankar.com") {
                if UIApplication.shared.canOpenURL(link) {
                    UIApplication.shared.open(link)
                }
            }
        }
        else if indexPath.row == 5 {//Log Out
            UIManager.shared.showLogin()
        }
    }
}
