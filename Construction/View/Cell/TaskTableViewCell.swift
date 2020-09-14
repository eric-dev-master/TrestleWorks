//
//  JournalTableViewCell.swift
//  Construction
//
//  Created by Macmini on 3/13/18.
//  Copyright © 2018 LekshmySankar. All rights reserved.
//

import UIKit
import MessageKit

class TaskTableViewCell: UITableViewCell {
    var disposer: Disposer<Task>?
    var task: Task?
    
    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblContent: UILabel!
    @IBOutlet weak var btnComment: UIButton!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblComments: UILabel!
    @IBOutlet weak var lblStatus: UILabel!

    var delegate: CommentableCellDelegate?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imgUser.layer.cornerRadius = 18
        imgUser.layer.borderWidth = 2
        imgUser.layer.borderColor = Colors.lightColor.cgColor
    }

    func reset(with newTask: Task?) {
        self.task = newTask
        
        if let task = self.task {
            lblTitle.text = task.title
            lblContent.text = task.content
            lblDate.text = task.createdAt.toStringWithRelativeTime()
            lblStatus.textColor = task.state.color
            lblStatus.text = task.state.status
            lblComments.text = "\(task.comments.count)"
            
            if let userId = task.userId {
                lblUserName.text  = task.userName
                lblUserName.textColor = #colorLiteral(red: 0.2780584991, green: 0.3169239163, blue: 0.391651094, alpha: 1)
                User.observeSingle(userId, eventType: .value) { (user) in
                    if let user = user {
                        if let file = user.thumbnail {
                            if let url = file.downloadURL {
                                self.imgUser.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "user_placeholder"), options: .refreshCached, completed: nil)
                            }
                        }
                    }
                };
            }
            else {
                lblUserName.text = "Not assigned yet."
                lblUserName.textColor = #colorLiteral(red: 1, green: 0.1490196078, blue: 0, alpha: 1)
            }
        }
        self.contentView.layoutIfNeeded()
    }
    

    @IBAction func onComment(_ sender: Any) {
        if let task = self.task, let delegate = self.delegate {
            delegate.onCommentTapped(task)
        }
    }
}
