//
//  JournalTableViewCell.swift
//  Construction
//
//  Created by Macmini on 3/13/18.
//  Copyright © 2018 LekshmySankar. All rights reserved.
//

import UIKit

protocol CommentableCellDelegate {
    func onCommentTapped(_ journal: Any?)
}

class JournalTableViewCell: UITableViewCell {
    var disposer: Disposer<Journal>?
    var journal: Journal?
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblContent: UILabel!
    @IBOutlet weak var btnLike: UIButton!
    @IBOutlet weak var btnComment: UIButton!
    @IBOutlet weak var lblDate: UILabel!
    
    @IBOutlet weak var lblLikes: UILabel!
    @IBOutlet weak var lblComments: UILabel!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var imgPhoto: UIImageView!

    var delegate: CommentableCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func reset(with newJournal: Journal?) {
        self.journal = newJournal
        
        if let journal = self.journal {
            lblTitle.text = journal.title
            lblContent.text = journal.content
            lblUserName.text = journal.userName
            lblDate.text = journal.createdAt.toString(dateStyle: .medium, timeStyle: .none)
            if let file = journal.attachment, let data = file.data, let image = UIImage(data: data) {
                imgPhoto.image = image
            }
            lblComments.text = "\(journal.comments.count)"
            lblLikes.text = "\(journal.likes.count)"
        }
        self.contentView.layoutIfNeeded()
    }
    
    @IBAction func onLike(_ sender: Any) {
        if let journal = self.journal {
            if !journal.likes.contains(Manager.shared.user.id) {
                journal.likes.insert(Manager.shared.user.id)
                lblLikes.text = "\(journal.likes.count)"
            }
        }
    }
    
    @IBAction func onComment(_ sender: Any) {
        if let journal = self.journal, let delegate = self.delegate {
            delegate.onCommentTapped(journal)            
        }
    }
}
