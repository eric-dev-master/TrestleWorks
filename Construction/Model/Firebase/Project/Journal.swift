//
//  Journal.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

class JournalComment: Relation<Comment> {
    override class var _name: String {
        return "journal_comments"
    }
}

class Journal: Object {
    @objc dynamic var attachment: File?
    @objc dynamic var  title: String?
    @objc dynamic var  content: String?
    @objc dynamic var  userId: String?
    @objc dynamic var  userName: String?
    
    var comments: JournalComment = []
    @objc dynamic var likes: Set<String> = []
}
