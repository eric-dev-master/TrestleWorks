//
//  Project.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit
import FirebaseDatabase

@objc enum UserType: Int {
    case developer
    case projectManager
}

class UserJournals: Relation<Journal> {
    override class var _name: String {
        return "user_journals"
    }
}

class User: Object {
    override class var _version: String {
        return "v1"
    }
    
    @objc dynamic var name: String?
    @objc dynamic var email: String?
    @objc dynamic var password: String?
    @objc dynamic var organization: String?
    @objc dynamic var phoneNumber: String?
    @objc dynamic var thumbnail: File?
    @objc dynamic var type: UserType = .developer
    var projects: Relation<Project> = []
    var invited: Invitation = []

    override func encode(_ key: String, value: Any?) -> Any? {
        if key == "type" {
            return self.type.rawValue as AnyObject?
        }
        return nil
    }
    
    override func decode(_ key: String, value: Any?) -> Any? {
        if key == "type" {
            if let type: Int = value as? Int {
                self.type = UserType(rawValue: type)!
                return self.type
            }
        }
        return nil
    }
    
    class func load(email: String, completion: @escaping ((User?)->Void)){
        let ref = User.databaseRef
        ref.queryOrdered(byChild: "email").queryEqual(toValue: email).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() == false {
                completion(nil)
            }
            else {
                for child in snapshot.children {
                    let user = User(snapshot: child as! DataSnapshot);
                    completion(user)
                    break
                }
            }
        }
    }
}
