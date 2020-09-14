//
//  UserTableViewCell.swift
//  Construction
//
//  Created by Macmini on 11/26/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {
    var disposer: Disposer<User>?

    @IBOutlet weak var imgPhoto: UIImageView!
    @IBOutlet weak var lblRole: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblMemberSince: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imgPhoto.layer.cornerRadius = 23
        imgPhoto.layer.borderWidth = 2
        imgPhoto.layer.borderColor = Colors.lightColor.cgColor
    }
    
    func reset(with user: User!) {
        lblName.text = user.name
        if let project = Manager.shared.currentProject,
            let managerId = project.managerId,
            user.id == managerId{
            lblRole.text = "PROJECT MANAGER"
        }
        else {
            lblRole.text = "TEAM MEMBER"
        }
        lblMemberSince.text = "Member Since: \(user.createdAt.toString(dateStyle: .medium, timeStyle: .none))"
        if let file = user.thumbnail {
            if let url = file.downloadURL {
                imgPhoto.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "user_placeholder"), options: .refreshCached, completed: nil)
            }
        }
    }
}
