//
//  Task.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

@objc enum TaskStatus: Int {
    case notStarted
    case inProgress
    case review
    case onHold
    case needHelp
    case complete
    
    var color: UIColor? {
        switch self {
        case .notStarted:
            return #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        case .inProgress:
            return #colorLiteral(red: 0.8004502654, green: 0.6688987017, blue: 0.4783759713, alpha: 1)
        case .review:
            return #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        case .onHold:
            return #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        case .needHelp:
            return #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        case .complete:
            return #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
        }
    }
    
    var status: String? {
        switch self {
        case .notStarted:
            return "Not Started"
        case .inProgress:
            return "In Progress"
        case .review:
            return "Review"
        case .onHold:
            return "On Hold"
        case .needHelp:
            return "Need Help"
        case .complete:
            return "Completed"
        }
    }
}

class TaskComment: Relation<Comment> {
    override class var _name: String {
        return "task_comments"
    }
}

class Task: Object {
    @objc dynamic var title: String?
    @objc dynamic var content: String?
    @objc dynamic var state: TaskStatus = .notStarted
    @objc dynamic var  userId: String?
    @objc dynamic var  userName: String?
    @objc dynamic var  creatorId: String?
    @objc dynamic var  creatorName: String?
    
    var comments: TaskComment = []

    override func encode(_ key: String, value: Any?) -> Any? {
        if key == "state" {
            return self.state.rawValue as AnyObject?
        }
        return nil
    }
    
    override func decode(_ key: String, value: Any?) -> Any? {
        if key == "state" {
            if let state: Int = value as? Int {
                self.state = TaskStatus(rawValue: state)!
                return self.state
            }
        }
        return nil
    }
}
