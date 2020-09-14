//
//  CommentTableViewCell.swift
//  Construction
//
//  Created by Macmini on 3/30/18.
//  Copyright © 2018 LekshmySankar. All rights reserved.
//

import UIKit

class CommentTableViewCell: UITableViewCell {
    var disposer: Disposer<Comment>?
    var comment: Comment?

    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var lblComment: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func reset(with newComment: Comment?) {
        self.comment = newComment
        
        if let comment = self.comment {
            lblUserName.text = comment.userName
            lblComment.text = comment.comment
            lblDate.text = comment.createdAt.toStringWithRelativeTime()
        }
        self.contentView.layoutIfNeeded()
    }
}
